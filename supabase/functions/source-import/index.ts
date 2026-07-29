import postgres from 'postgres'
import type { AdapterBatch } from '../_shared/source-adapters/types.ts'
import { validateAdapterBatch } from '../_shared/source-adapters/validate.ts'

const MAX_BODY_BYTES = 1024 * 1024
const MIN_TRIGGER_TOKEN_BYTES = 32
const IMPORT_TOKEN_HEADER = 'X-Weedypedia-Import-Token'

type ImportResult = {
  run_id: string
  inserted_records: number
  inserted_assertions: number
  review_cases: number
}

export type SourceImportLogEvent = {
  correlationId: string
  sourceId: string | null
  code: string
}

export type SourceImportDependencies = {
  authorizeTriggerToken(request: Request): Promise<boolean>
  recordBatch(batch: AdapterBatch): Promise<ImportResult>
  log(event: SourceImportLogEvent): void
  correlationId(): string
}

function responseHeaders(extra: HeadersInit = {}): Headers {
  const headers = new Headers(extra)
  headers.set('Cache-Control', 'no-store')
  return headers
}

function jsonResponse(
  status: number,
  body: Record<string, unknown>,
): Response {
  return Response.json(body, {
    status,
    headers: responseHeaders(),
  })
}

function failure(status: number, code: string): Response {
  return jsonResponse(status, { ok: false, code })
}

function databaseErrorCode(error: unknown): string | null {
  if (typeof error !== 'object' || error === null) return null
  const code = Reflect.get(error, 'code')
  return typeof code === 'string' ? code : null
}

async function readBoundedBody(request: Request): Promise<string | null> {
  const declaredLength = request.headers.get('content-length')
  if (declaredLength !== null) {
    const bytes = Number(declaredLength)
    if (!Number.isSafeInteger(bytes) || bytes < 0 || bytes > MAX_BODY_BYTES) {
      return null
    }
  }

  if (!request.body) return ''

  const reader = request.body.getReader()
  const chunks: Uint8Array[] = []
  let byteLength = 0

  try {
    while (true) {
      const { done, value } = await reader.read()
      if (done) break
      byteLength += value.byteLength
      if (byteLength > MAX_BODY_BYTES) {
        await reader.cancel()
        return null
      }
      chunks.push(value)
    }
  } finally {
    reader.releaseLock()
  }

  const body = new Uint8Array(byteLength)
  let offset = 0
  for (const chunk of chunks) {
    body.set(chunk, offset)
    offset += chunk.byteLength
  }
  return new TextDecoder('utf-8', { fatal: true }).decode(body)
}

export async function secureTokenMatches(
  suppliedToken: string,
  configuredToken: string,
): Promise<boolean> {
  const encoder = new TextEncoder()
  const suppliedBytes = encoder.encode(suppliedToken)
  const configuredBytes = encoder.encode(configuredToken)
  const [suppliedDigest, configuredDigest] = await Promise.all([
    crypto.subtle.digest('SHA-256', suppliedBytes),
    crypto.subtle.digest('SHA-256', configuredBytes),
  ])

  const suppliedHash = new Uint8Array(suppliedDigest)
  const configuredHash = new Uint8Array(configuredDigest)
  let difference = suppliedBytes.byteLength === configuredBytes.byteLength
    ? 0
    : 1
  for (let index = 0; index < configuredHash.byteLength; index += 1) {
    difference |= suppliedHash[index] ^ configuredHash[index]
  }

  return (
    configuredBytes.byteLength >= MIN_TRIGGER_TOKEN_BYTES &&
    suppliedBytes.byteLength > 0 &&
    difference === 0
  )
}

export function createSourceImportHandler(
  dependencies: SourceImportDependencies,
): (request: Request) => Promise<Response> {
  return async (request) => {
    const correlationId = dependencies.correlationId()
    if (request.method !== 'POST') {
      const response = failure(405, 'method_not_allowed')
      response.headers.set('Allow', 'POST')
      return response
    }

    if (!await dependencies.authorizeTriggerToken(request)) {
      dependencies.log({
        correlationId,
        sourceId: null,
        code: 'unauthorized',
      })
      return failure(401, 'unauthorized')
    }

    let bodyText: string | null
    try {
      bodyText = await readBoundedBody(request)
    } catch {
      return failure(400, 'invalid_batch')
    }
    if (bodyText === null) return failure(413, 'invalid_batch')

    let batch: AdapterBatch
    try {
      const input: unknown = JSON.parse(bodyText)
      batch = validateAdapterBatch(input).batch
    } catch {
      return failure(400, 'invalid_batch')
    }

    try {
      const result = await dependencies.recordBatch(batch)
      return jsonResponse(200, {
        ok: true,
        runId: result.run_id,
        insertedRecords: result.inserted_records,
        insertedAssertions: result.inserted_assertions,
        reviewCases: result.review_cases,
      })
    } catch (error) {
      const code = databaseErrorCode(error) === '42501'
        ? 'source_blocked'
        : 'unavailable'
      dependencies.log({
        correlationId,
        sourceId: batch.sourceId,
        code,
      })
      return failure(code === 'source_blocked' ? 403 : 503, code)
    }
  }
}

function productionDependencies(): SourceImportDependencies {
  let database: ReturnType<typeof postgres> | null = null

  function databaseClient(): ReturnType<typeof postgres> {
    if (database) return database
    const connectionUrl = Deno.env.get('SOURCE_INGESTOR_POOLER_URL')
    if (!connectionUrl) throw new Error('source ingestor database unavailable')
    database = postgres(connectionUrl, {
      connect_timeout: 5,
      idle_timeout: 5,
      max: 1,
      prepare: false,
      ssl: 'require',
    })
    return database
  }

  return {
    async authorizeTriggerToken(request) {
      return await secureTokenMatches(
        request.headers.get(IMPORT_TOKEN_HEADER) ?? '',
        Deno.env.get('SOURCE_IMPORT_TRIGGER_TOKEN') ?? '',
      )
    },
    async recordBatch(batch) {
      const sql = databaseClient()
      return await sql.begin(async (transaction) => {
        await transaction`set local role source_ingestor`
        const rows = await transaction<ImportResult[]>`
          select
            run_id,
            inserted_records,
            inserted_assertions,
            review_cases
          from private.record_source_import(${transaction.json(batch)}::jsonb)
        `
        const row = rows[0]
        if (!row) throw new Error('source import returned no result')
        return row
      })
    },
    log(event) {
      console.error(JSON.stringify(event))
    },
    correlationId: () => crypto.randomUUID(),
  }
}

let runtimeHandler:
  | ((request: Request) => Promise<Response>)
  | null = null

async function fetch(request: Request): Promise<Response> {
  runtimeHandler ??= createSourceImportHandler(productionDependencies())
  return await runtimeHandler(request)
}

export default { fetch }

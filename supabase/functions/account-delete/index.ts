import { withSupabase } from '@supabase/server'

type Factor = {
  factor_type?: string
  status?: string
}

type AdminError = {
  code?: string
  status?: number
  message: string
}

export type AuthenticatedDeleteContext = {
  userId: string
  jwtClaims: Record<string, unknown>
  listFactors(): Promise<{
    factors: Factor[]
    error: AdminError | null
  }>
  deleteUser(): Promise<{
    error: AdminError | null
  }>
}

type AccountDeleteHandlerOptions = {
  authenticate(request: Request): Promise<AuthenticatedDeleteContext | null>
  now(): number
}

const MAX_PROOF_AGE_SECONDS = 5 * 60
const MAX_CLOCK_SKEW_SECONDS = 60

function responseHeaders(extra: HeadersInit = {}): Headers {
  const headers = new Headers(extra)
  headers.set('Cache-Control', 'no-store')
  return headers
}

function jsonResponse(status: number, message: string): Response {
  return Response.json(
    { message },
    {
      status,
      headers: responseHeaders(),
    },
  )
}

function methodNotAllowed(): Response {
  return jsonResponse(405, 'Methode nicht erlaubt.')
}

function unauthorized(): Response {
  return jsonResponse(401, 'Authentifizierung erforderlich.')
}

function forbidden(): Response {
  return jsonResponse(403, 'Aktion nicht erlaubt.')
}

function serviceUnavailable(): Response {
  return jsonResponse(503, 'Kontoaktion vorübergehend nicht verfügbar.')
}

function noContent(): Response {
  return new Response(null, {
    status: 204,
    headers: responseHeaders(),
  })
}

function isFreshTimestamp(value: unknown, now: number): value is number {
  if (typeof value !== 'number' || !Number.isFinite(value)) return false
  const age = now - value
  return (
    age >= -MAX_CLOCK_SKEW_SECONDS
    && age <= MAX_PROOF_AGE_SECONDS
  )
}

function hasFreshPasswordMethod(
  amr: unknown,
  now: number,
): boolean {
  if (!Array.isArray(amr)) return false
  return amr.some((entry) => {
    if (!entry || typeof entry !== 'object') return false
    const method = Reflect.get(entry, 'method')
    const timestamp = Reflect.get(entry, 'timestamp')
    return method === 'password' && isFreshTimestamp(timestamp, now)
  })
}

function isAlreadyDeleted(error: AdminError): boolean {
  return error.status === 404 || error.code === 'user_not_found'
}

export async function handleAuthenticatedDelete(
  context: AuthenticatedDeleteContext,
  now: number,
): Promise<Response> {
  const claims = context.jwtClaims
  if (
    claims.sub !== context.userId
    || !isFreshTimestamp(claims.iat, now)
    || !hasFreshPasswordMethod(claims.amr, now)
  ) {
    return forbidden()
  }

  const factorResult = await context.listFactors()
  if (factorResult.error) return serviceUnavailable()

  const hasVerifiedFactor = factorResult.factors.some(
    (factor) => factor.status === 'verified',
  )
  if (hasVerifiedFactor && claims.aal !== 'aal2') {
    return forbidden()
  }

  const deletion = await context.deleteUser()
  if (!deletion.error || isAlreadyDeleted(deletion.error)) {
    return noContent()
  }
  return serviceUnavailable()
}

export function createAccountDeleteHandler(
  options: AccountDeleteHandlerOptions,
): (request: Request) => Promise<Response> {
  return async (request) => {
    if (request.method !== 'DELETE') {
      const response = methodNotAllowed()
      response.headers.set('Allow', 'DELETE')
      return response
    }

    const context = await options.authenticate(request)
    if (!context) return unauthorized()
    return handleAuthenticatedDelete(context, options.now())
  }
}

function withNoStore(response: Response): Response {
  const headers = responseHeaders(response.headers)
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  })
}

const authenticatedRuntimeHandler = withSupabase(
  { auth: 'user' },
  async (_request, context) => {
    if (!context.userClaims || !context.jwtClaims) return unauthorized()
    const userId = context.userClaims.id

    return handleAuthenticatedDelete(
      {
        userId,
        jwtClaims: context.jwtClaims,
        async listFactors() {
          const { data, error } =
            await context.supabaseAdmin.auth.admin.mfa.listFactors({ userId })
          return {
            factors: data?.factors ?? [],
            error: error
              ? {
                  code: error.code,
                  status: error.status,
                  message: error.message,
                }
              : null,
          }
        },
        async deleteUser() {
          const { error } =
            await context.supabaseAdmin.auth.admin.deleteUser(userId)
          return {
            error: error
              ? {
                  code: error.code,
                  status: error.status,
                  message: error.message,
                }
              : null,
          }
        },
      },
      Math.floor(Date.now() / 1000),
    )
  },
)

async function fetch(request: Request): Promise<Response> {
  if (request.method !== 'DELETE') {
    const response = methodNotAllowed()
    response.headers.set('Allow', 'DELETE')
    return response
  }
  return withNoStore(await authenticatedRuntimeHandler(request))
}

export default { fetch }

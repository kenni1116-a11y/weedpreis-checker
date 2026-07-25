import { assertEquals } from '@std/assert'
import {
  createAccountDeleteHandler,
  type AuthenticatedDeleteContext,
} from '../account-delete/index.ts'

const nowSeconds = 1_774_441_800
const userId = '00000000-0000-4000-8000-000000000001'

function claims(
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    sub: userId,
    iat: nowSeconds - 30,
    aal: 'aal1',
    amr: [{ method: 'password', timestamp: nowSeconds - 30 }],
    ...overrides,
  }
}

function harness(options: {
  jwtClaims?: Record<string, unknown>
  factors?: Array<{ factor_type: string; status: string }>
  deleteError?: { code?: string; status?: number; message: string } | null
}) {
  const calls = { listFactors: 0, deleteUser: 0 }
  const context: AuthenticatedDeleteContext = {
    userId,
    jwtClaims: options.jwtClaims ?? claims(),
    async listFactors() {
      calls.listFactors += 1
      return {
        factors: options.factors ?? [],
        error: null,
      }
    },
    async deleteUser() {
      calls.deleteUser += 1
      return {
        error: options.deleteError ?? null,
      }
    },
  }
  const handler = createAccountDeleteHandler({
    now: () => nowSeconds,
    authenticate: async (request) =>
      request.headers.get('authorization') === 'Bearer fresh-token'
        ? context
        : null,
  })
  return { calls, handler }
}

function request(method = 'DELETE', withToken = true): Request {
  return new Request('https://example.invalid/account-delete', {
    method,
    headers: withToken
      ? { Authorization: 'Bearer fresh-token' }
      : undefined,
  })
}

Deno.test('account deletion rejects methods other than DELETE', async () => {
  const { calls, handler } = harness({})
  const response = await handler(request('POST'))

  assertEquals(response.status, 405)
  assertEquals(response.headers.get('allow'), 'DELETE')
  assertEquals(response.headers.get('cache-control'), 'no-store')
  assertEquals(calls.deleteUser, 0)
})

Deno.test('account deletion rejects a missing proof token', async () => {
  const { calls, handler } = harness({})
  const response = await handler(request('DELETE', false))

  assertEquals(response.status, 401)
  assertEquals(response.headers.get('cache-control'), 'no-store')
  assertEquals(calls.listFactors, 0)
  assertEquals(calls.deleteUser, 0)
})

Deno.test('account deletion rejects stale proof and missing password AMR generically', async () => {
  const stale = harness({
    jwtClaims: claims({
      iat: nowSeconds - 301,
      amr: [{ method: 'password', timestamp: nowSeconds - 301 }],
    }),
  })
  const missingPassword = harness({
    jwtClaims: claims({ amr: [{ method: 'totp', timestamp: nowSeconds - 10 }] }),
  })

  const staleResponse = await stale.handler(request())
  const missingPasswordResponse = await missingPassword.handler(request())

  assertEquals(staleResponse.status, 403)
  assertEquals(missingPasswordResponse.status, 403)
  assertEquals(await staleResponse.text(), await missingPasswordResponse.text())
  assertEquals(stale.calls.deleteUser, 0)
  assertEquals(missingPassword.calls.deleteUser, 0)
})

Deno.test('account deletion requires AAL2 when a verified TOTP factor exists', async () => {
  const { calls, handler } = harness({
    factors: [{ factor_type: 'totp', status: 'verified' }],
    jwtClaims: claims({ aal: 'aal1' }),
  })

  const response = await handler(request())

  assertEquals(response.status, 403)
  assertEquals(response.headers.get('cache-control'), 'no-store')
  assertEquals(calls.listFactors, 1)
  assertEquals(calls.deleteUser, 0)
})

Deno.test('account deletion removes an AAL2 TOTP account', async () => {
  const { calls, handler } = harness({
    factors: [{ factor_type: 'totp', status: 'verified' }],
    jwtClaims: claims({ aal: 'aal2' }),
  })

  const response = await handler(request())

  assertEquals(response.status, 204)
  assertEquals(response.headers.get('cache-control'), 'no-store')
  assertEquals(calls.listFactors, 1)
  assertEquals(calls.deleteUser, 1)
})

Deno.test('account deletion treats an already deleted account as a successful retry', async () => {
  const { calls, handler } = harness({
    deleteError: {
      code: 'user_not_found',
      status: 404,
      message: 'User not found',
    },
  })

  const response = await handler(request())

  assertEquals(response.status, 204)
  assertEquals(response.headers.get('cache-control'), 'no-store')
  assertEquals(calls.deleteUser, 1)
})

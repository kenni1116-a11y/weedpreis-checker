import { describe, expect, it } from 'vitest'
import { createInMemoryAuthService } from './in-memory-auth-service'

describe('createInMemoryAuthService', () => {
  it('exposes deterministic state changes and exact synthetic calls', async () => {
    const service = createInMemoryAuthService()
    const states: string[] = []
    const unsubscribe = service.subscribe((state) => states.push(state.status))

    service.setState({
      status: 'verification-required',
      email: 'test-user@example.invalid',
    })
    await service.login({
      email: 'test-user@example.invalid',
      password: 'synthetic-password',
    })

    expect(await service.currentState()).toEqual({
      status: 'verification-required',
      email: 'test-user@example.invalid',
    })
    expect(states).toEqual(['verification-required'])
    expect(service.calls.login).toEqual([
      {
        email: 'test-user@example.invalid',
        password: 'synthetic-password',
      },
    ])

    unsubscribe()
    service.setState({ status: 'signed-out' })
    expect(states).toEqual(['verification-required'])
  })

  it('rejects non-synthetic email addresses in test state', () => {
    expect(() =>
      createInMemoryAuthService({
        initialState: {
          status: 'verification-required',
          email: 'real@example.com',
        },
      }),
    ).toThrow('synthetic .invalid')
  })
})

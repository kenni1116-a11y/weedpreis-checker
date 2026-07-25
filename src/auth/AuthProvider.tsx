import {
  createContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import type { AuthService, AuthState } from './auth-service'

export type AuthContextValue = {
  state: AuthState
  service: AuthService
}

export const AuthContext = createContext<AuthContextValue | null>(null)

type AuthProviderProps = {
  service: AuthService
  children: ReactNode
}

export function AuthProvider({
  service,
  children,
}: AuthProviderProps) {
  const [state, setState] = useState<AuthState>({ status: 'loading' })

  useEffect(() => {
    let active = true
    const unsubscribe = service.subscribe((nextState) => {
      if (active) setState(nextState)
    })
    void service.currentState().then((nextState) => {
      if (active) setState(nextState)
    })
    return () => {
      active = false
      unsubscribe()
    }
  }, [service])

  const value = useMemo(() => ({ state, service }), [service, state])
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

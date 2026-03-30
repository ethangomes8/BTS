import React, { createContext, useContext, useEffect, useMemo, useState } from 'react'

import { API_URL } from '../config/env'

type AuthContextValue = {
  token: string | null
  isAuthenticated: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => void
}

const AuthContext = createContext<AuthContextValue | null>(null)

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [token, setToken] = useState<string | null>(() => {
    const raw = localStorage.getItem('admin_token')
    return raw && raw.length > 0 ? raw : null
  })

  useEffect(() => {
    if (!token) return
    localStorage.setItem('admin_token', token)
  }, [token])

  const value = useMemo<AuthContextValue>(() => {
    return {
      token,
      isAuthenticated: !!token,
      login: async (email: string, password: string) => {
        const res = await fetch(`${API_URL}/auth/login`, {
          method: 'POST',
          headers: { 'content-type': 'application/json' },
          body: JSON.stringify({ email, password }),
        })

        if (!res.ok) {
          const text = await res.text().catch(() => '')
          throw new Error(text || `Login failed (${res.status})`)
        }

        const data = (await res.json()) as { token: string }
        if (!data.token) throw new Error('Missing token')
        setToken(data.token)
      },
      logout: () => {
        localStorage.removeItem('admin_token')
        setToken(null)
      },
    }
  }, [token])

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}


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

function cleanPayloadText(text: string): string {
  let result = text.trim()
  if ((result.startsWith('"') && result.endsWith('"')) || (result.startsWith("'") && result.endsWith("'"))) {
    result = result.slice(1, -1).trim()
  }
  if (result.startsWith('{') && result.endsWith('}')) {
    result = result.slice(1, -1).trim()
  }
  return result.replace(/^error\s*[:=-]?\s*/i, '').trim()
}

async function parseLoginError(res: Response): Promise<string> {
  const text = await res.text().catch(() => '')
  if (!text) return `Échec de la connexion (${res.status})`

  try {
    const payload = JSON.parse(text)
    if (payload && typeof payload === 'object') {
      if (typeof payload.error === 'string' && payload.error.trim().length > 0) {
        return cleanPayloadText(payload.error)
      }
      if (typeof payload.message === 'string' && payload.message.trim().length > 0) {
        return cleanPayloadText(payload.message)
      }
    }
  } catch {
    // ignore invalid JSON
  }

  return cleanPayloadText(text) || `Échec de la connexion (${res.status})`
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
          throw new Error(await parseLoginError(res))
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


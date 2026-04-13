import { API_URL } from '../config/env'

import type { StockFormat, StockType, StockProductView } from './types'

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

async function parseApiError(res: Response): Promise<string> {
  const text = await res.text().catch(() => '')
  if (!text) return `La requête a échoué (${res.status})`

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

  return cleanPayloadText(text) || `La requête a échoué (${res.status})`
}

async function apiFetch<T>(path: string, token: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${API_URL}${path}`, {
    ...init,
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${token}`,
      ...(init?.headers ?? {}),
    },
  })

  if (!res.ok) {
    throw new Error(await parseApiError(res))
  }

  return (await res.json()) as T
}

export async function getTypes(token: string): Promise<StockType[]> {
  const data = await apiFetch<{ items: StockType[] }>('/admin/types', token, { method: 'GET' })
  return data.items
}

export async function createType(token: string, name: string): Promise<void> {
  await apiFetch('/admin/types', token, {
    method: 'POST',
    body: JSON.stringify({ name }),
  })
}

export async function updateType(token: string, id: string, name: string): Promise<void> {
  await apiFetch('/admin/types/' + encodeURIComponent(id), token, {
    method: 'PUT',
    body: JSON.stringify({ name }),
  })
}

export async function deleteType(token: string, id: string): Promise<void> {
  await apiFetch('/admin/types/' + encodeURIComponent(id), token, { method: 'DELETE' })
}

export async function getFormats(token: string): Promise<StockFormat[]> {
  const data = await apiFetch<{ items: StockFormat[] }>('/admin/formats', token, { method: 'GET' })
  return data.items
}

export async function createFormat(token: string, input: {
  label: string
  volumeMl: number
  alcoholPercent: number
}): Promise<void> {
  await apiFetch('/admin/formats', token, { method: 'POST', body: JSON.stringify(input) })
}

export async function updateFormat(token: string, id: string, input: {
  label: string
  volumeMl: number
  alcoholPercent: number
}): Promise<void> {
  await apiFetch('/admin/formats/' + encodeURIComponent(id), token, {
    method: 'PUT',
    body: JSON.stringify(input),
  })
}

export async function deleteFormat(token: string, id: string): Promise<void> {
  await apiFetch('/admin/formats/' + encodeURIComponent(id), token, { method: 'DELETE' })
}

export async function getProducts(token: string): Promise<StockProductView[]> {
  const data = await apiFetch<{ items: StockProductView[] }>('/admin/products', token, { method: 'GET' })
  return data.items
}

export async function createProduct(token: string, input: {
  name: string
  description: string
  typeId: string
  formatId: string
  quantity: number
  imageKey: string
}): Promise<void> {
  await apiFetch('/admin/products', token, { method: 'POST', body: JSON.stringify(input) })
}

export async function updateProduct(token: string, id: string, input: {
  name: string
  description: string
  typeId: string
  formatId: string
  quantity: number
  imageKey: string
}): Promise<void> {
  await apiFetch('/admin/products/' + encodeURIComponent(id), token, {
    method: 'PUT',
    body: JSON.stringify(input),
  })
}

export async function deleteProduct(token: string, id: string): Promise<void> {
  await apiFetch('/admin/products/' + encodeURIComponent(id), token, { method: 'DELETE' })
}


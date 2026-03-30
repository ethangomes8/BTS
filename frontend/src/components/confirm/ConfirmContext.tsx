import { createContext, useContext } from 'react'

export type ConfirmOptions = {
  title?: string
  message: string
  confirmText?: string
  cancelText?: string
  tone?: 'default' | 'danger'
}

export type ConfirmFn = (options: ConfirmOptions) => Promise<boolean>

const ConfirmContext = createContext<ConfirmFn | null>(null)

export function useConfirm(): ConfirmFn {
  const ctx = useContext(ConfirmContext)
  if (!ctx) throw new Error('useConfirm must be used within ConfirmProvider')
  return ctx
}

export { ConfirmContext }


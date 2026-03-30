import { useCallback, useMemo, useState } from 'react'

import { ConfirmContext, type ConfirmFn, type ConfirmOptions } from './ConfirmContext'

type State =
  | null
  | {
      options: ConfirmOptions
      resolve: (value: boolean) => void
    }

export function ConfirmProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<State>(null)

  const confirm = useCallback<ConfirmFn>((options) => {
    return new Promise<boolean>((resolve) => {
      setState({ options, resolve })
    })
  }, [])

  const value = useMemo(() => confirm, [confirm])

  return (
    <ConfirmContext.Provider value={value}>
      {children}
      {state ? (
        <div className="bts-modal-overlay" role="presentation">
          <div className="bts-modal" role="dialog" aria-modal="true" aria-label={state.options.title ?? 'Confirmation'}>
            <div className="bts-modal-header">
              <div className="bts-modal-title">{state.options.title ?? 'Confirmation'}</div>
            </div>
            <div className="bts-modal-body">{state.options.message}</div>
            <div className="bts-modal-actions">
              <button
                className="bts-btn"
                onClick={() => {
                  state.resolve(false)
                  setState(null)
                }}
              >
                {state.options.cancelText ?? 'Annuler'}
              </button>
              <button
                className={`bts-btn primary ${state.options.tone === 'danger' ? 'danger' : ''}`}
                onClick={() => {
                  state.resolve(true)
                  setState(null)
                }}
              >
                {state.options.confirmText ?? 'Confirmer'}
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </ConfirmContext.Provider>
  )
}


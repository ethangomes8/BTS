type StatusMessageProps = {
  message: string | null
  type?: 'error' | 'success' | 'info'
  onClose?: () => void
}

export default function StatusMessage({ message, type = 'error', onClose }: StatusMessageProps) {
  if (!message) return null

  return (
    <div className={`bts-status ${type}`} role="alert">
      <span>{message}</span>
      {onClose ? (
        <button type="button" className="bts-status-close" onClick={onClose} aria-label="Fermer le message">
          ×
        </button>
      ) : null}
    </div>
  )
}

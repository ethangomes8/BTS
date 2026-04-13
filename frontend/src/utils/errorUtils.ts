export function cleanErrorText(raw: string): string {
  let text = raw.trim()
  if ((text.startsWith('"') && text.endsWith('"')) || (text.startsWith("'") && text.endsWith("'"))) {
    text = text.slice(1, -1).trim()
  }
  if (text.startsWith('{') && text.endsWith('}')) {
    text = text.slice(1, -1).trim()
  }
  text = text.replace(/^error\s*[:=-]?\s*/i, '').trim()
  return text
}

export function formatError(err: unknown): string {
  if (err instanceof Error) {
    const txt = cleanErrorText(err.message)
    if (txt === 'Failed to fetch') {
      return 'Impossible de joindre le serveur. Vérifiez que le backend est démarré.'
    }
    if (txt === 'NetworkError when attempting to fetch resource.') {
      return 'Impossible de contacter le serveur. Vérifiez votre connexion réseau.'
    }
    return txt || 'Erreur inconnue.'
  }

  return 'Erreur inconnue.'
}

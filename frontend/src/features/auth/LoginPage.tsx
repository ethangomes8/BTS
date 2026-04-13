import { useState } from 'react'
import { useNavigate } from 'react-router-dom'

import { useAuth } from '../../auth/AuthContext'
import StatusMessage from '../../components/StatusMessage'
import { formatError } from '../../utils/errorUtils'

export default function LoginPage() {
  const { login } = useAuth()
  const navigate = useNavigate()
  const [email, setEmail] = useState('admin@brasserie.local')
  const [password, setPassword] = useState('Admin1234!')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  return (
    <div className="bts-app">
      <div className="bts-card" style={{ maxWidth: 520, margin: '0 auto' }}>
        <h2 style={{ marginTop: 0 }}>Connexion admin</h2>

        <form
          className="bts-form"
          onSubmit={async (e) => {
            e.preventDefault()
            setError(null)
            setLoading(true)
            try {
              await login(email, password)
              navigate('/admin/produits')
            } catch (err) {
              setError(formatError(err))
            } finally {
              setLoading(false)
            }
          }}
        >
          <div className="bts-field">
            <label>Email</label>
            <input value={email} onChange={(e) => setEmail(e.target.value)} />
          </div>

          <div className="bts-field">
            <label>Mot de passe</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </div>

          <StatusMessage message={error} type="error" onClose={() => setError(null)} />

          <button className="bts-btn primary" disabled={loading} type="submit">
            {loading ? 'Connexion...' : 'Se connecter'}
          </button>
        </form>
      </div>
    </div>
  )
}


import { NavLink, Outlet, useNavigate } from 'react-router-dom'

import { useAuth } from '../../auth/AuthContext'

export default function AdminLayout() {
  const { logout } = useAuth()
  const navigate = useNavigate()

  return (
    <div className="bts-app">
      <header className="bts-header">
        <div className="bts-brand">
          <img src="/images/brasserie_logo.png" alt="Brasserie Terroir & Savoirs" />
          <div>
            <div style={{ fontWeight: 700, lineHeight: 1.1 }}>Brasserie Terroir &amp; Savoirs</div>
            <div style={{ color: '#6f6a7d', fontSize: 13 }}>Gestion des stocks (admin)</div>
          </div>
        </div>

        <div className="bts-inline">
          <nav className="bts-nav" aria-label="Navigation admin">
            <NavLink to="/admin/produits">Produits</NavLink>
            <NavLink to="/admin/types">Types</NavLink>
            <NavLink to="/admin/formats">Formats</NavLink>
          </nav>
          <button
            className="bts-btn"
            onClick={() => {
              logout()
              navigate('/login')
            }}
          >
            Déconnexion
          </button>
        </div>
      </header>

      <main style={{ marginTop: 16 }}>
        <Outlet />
      </main>
    </div>
  )
}


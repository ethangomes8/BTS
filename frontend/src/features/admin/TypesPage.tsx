import { useEffect, useState } from 'react'

import { useAuth } from '../../auth/AuthContext'
import { createType, deleteType, getTypes, updateType } from '../../api/adminApi'
import type { StockType } from '../../api/types'
import { useConfirm } from '../../components/confirm/ConfirmContext'

export default function TypesPage() {
  const { token } = useAuth()
  const confirm = useConfirm()
  const [items, setItems] = useState<StockType[]>([])
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  const [newName, setNewName] = useState('')
  const [editId, setEditId] = useState<string | null>(null)
  const [editName, setEditName] = useState('')

  async function refresh() {
    if (!token) return
    setLoading(true)
    setError(null)
    try {
      const data = await getTypes(token)
      setItems(data)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Error')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    refresh()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token])

  return (
    <div className="bts-grid">
      <section className="bts-card">
        <h2 style={{ marginTop: 0 }}>Types de produits</h2>
        {loading ? <div>Chargement...</div> : null}
        {error ? <div className="bts-error">{error}</div> : null}

        <table className="bts-table" aria-label="Liste types">
          <thead>
            <tr>
              <th>Nom</th>
              <th style={{ width: 220 }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {items.map((t) => (
              <tr key={t.id}>
                <td>{t.name}</td>
                <td>
                  <div className="bts-inline">
                    <button
                      className="bts-btn"
                      onClick={() => {
                        setEditId(t.id)
                        setEditName(t.name)
                      }}
                    >
                      Modifier
                    </button>
                    <button
                      className="bts-btn"
                      onClick={async () => {
                        if (!token) return
                        const ok = await confirm({
                          title: 'Supprimer le type',
                          message: 'Confirmer la suppression de ce type ?',
                          confirmText: 'Supprimer',
                          tone: 'danger',
                        })
                        if (!ok) return
                        try {
                          await deleteType(token, t.id)
                          setEditId((cur) => (cur === t.id ? null : cur))
                          setEditName('')
                          await refresh()
                        } catch (e) {
                          setError(e instanceof Error ? e.message : 'Error')
                        }
                      }}
                    >
                      Supprimer
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {items.length === 0 && !loading ? (
              <tr>
                <td colSpan={2} style={{ color: '#6f6a7d' }}>
                  Aucun type.
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </section>

      <aside className="bts-card">
        <h3 style={{ marginTop: 0 }}>{editId ? 'Modifier' : 'Créer'}</h3>

        <div className="bts-form">
          <div className="bts-field">
            <label>Nom du type</label>
            <input
              value={editId ? editName : newName}
              onChange={(e) => (editId ? setEditName(e.target.value) : setNewName(e.target.value))}
              placeholder="Ex: Bière"
            />
          </div>

          <div className="bts-inline">
            <button
              className="bts-btn primary"
              onClick={async () => {
                if (!token) return
                try {
                  if (editId) {
                    const ok = await confirm({
                      title: 'Modifier le type',
                      message: 'Confirmer la modification de ce type ?',
                      confirmText: 'Enregistrer',
                    })
                    if (!ok) return
                    await updateType(token, editId, editName)
                    setEditId(null)
                    setEditName('')
                  } else {
                    await createType(token, newName)
                    setNewName('')
                  }
                  await refresh()
                } catch (e) {
                  setError(e instanceof Error ? e.message : 'Error')
                }
              }}
            >
              {editId ? 'Enregistrer' : 'Ajouter'}
            </button>

            {editId ? (
              <button
                className="bts-btn"
                onClick={() => {
                  setEditId(null)
                  setEditName('')
                }}
              >
                Annuler
              </button>
            ) : null}
          </div>

          <p style={{ color: '#6f6a7d', fontSize: 13, marginTop: -2 }}>
            Les types sont utilisés pour classer les produits en stock.
          </p>
        </div>
      </aside>
    </div>
  )
}


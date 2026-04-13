import { useEffect, useState } from 'react'

import { useAuth } from '../../auth/AuthContext'
import StatusMessage from '../../components/StatusMessage'
import { formatError } from '../../utils/errorUtils'
import { createFormat, deleteFormat, getFormats, updateFormat } from '../../api/adminApi'
import type { StockFormat } from '../../api/types'
import { useConfirm } from '../../components/confirm/ConfirmContext'

export default function FormatsPage() {
  const { token } = useAuth()
  const confirm = useConfirm()
  const [items, setItems] = useState<StockFormat[]>([])
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  const [newLabel, setNewLabel] = useState('')
  const [newVolumeMl, setNewVolumeMl] = useState<number>(250)
  const [newAlcoholPercent, setNewAlcoholPercent] = useState<number>(4)

  const [editId, setEditId] = useState<string | null>(null)
  const [editLabel, setEditLabel] = useState('')
  const [editVolumeMl, setEditVolumeMl] = useState<number>(250)
  const [editAlcoholPercent, setEditAlcoholPercent] = useState<number>(4)

  async function refresh() {
    if (!token) return
    setLoading(true)
    setError(null)
    try {
      const data = await getFormats(token)
      setItems(data)
    } catch (e) {
      setError(formatError(e))
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
        <h2 style={{ marginTop: 0 }}>Formats de produits</h2>
        {loading ? <div>Chargement...</div> : null}
        <StatusMessage message={error} type="error" onClose={() => setError(null)} />

        <table className="bts-table" aria-label="Liste formats">
          <thead>
            <tr>
              <th>Libellé</th>
              <th>Volume</th>
              <th>% Vol</th>
              <th style={{ width: 220 }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {items.map((f) => (
              <tr key={f.id}>
                <td>{f.label}</td>
                <td>{f.volumeMl} ml</td>
                <td>{f.alcoholPercent}</td>
                <td>
                  <div className="bts-inline">
                    <button
                      className="bts-btn"
                      onClick={() => {
                        setEditId(f.id)
                        setEditLabel(f.label)
                        setEditVolumeMl(f.volumeMl)
                        setEditAlcoholPercent(f.alcoholPercent)
                      }}
                    >
                      Modifier
                    </button>
                    <button
                      className="bts-btn"
                      onClick={async () => {
                        if (!token) return
                        const ok = await confirm({
                          title: 'Supprimer le format',
                          message: 'Confirmer la suppression de ce format ?',
                          confirmText: 'Supprimer',
                          tone: 'danger',
                        })
                        if (!ok) return
                        try {
                          await deleteFormat(token, f.id)
                          setEditId((cur) => (cur === f.id ? null : cur))
                          await refresh()
                        } catch (e) {
                          setError(formatError(e))
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
                <td colSpan={4} style={{ color: '#6f6a7d' }}>
                  Aucun format.
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
            <label>Libellé</label>
            <input
              value={editId ? editLabel : newLabel}
              onChange={(e) => (editId ? setEditLabel(e.target.value) : setNewLabel(e.target.value))}
              placeholder="Ex: 25CL - 4°"
            />
          </div>

          <div className="bts-inline">
            <div className="bts-field" style={{ flex: 1 }}>
              <label>Volume (ml)</label>
              <input
                type="number"
                value={editId ? editVolumeMl : newVolumeMl}
                onChange={(e) =>
                  editId
                    ? setEditVolumeMl(Number(e.target.value))
                    : setNewVolumeMl(Number(e.target.value))
                }
              />
            </div>
            <div className="bts-field" style={{ flex: 1 }}>
              <label>% alcool</label>
              <input
                type="number"
                step="0.1"
                value={editId ? editAlcoholPercent : newAlcoholPercent}
                onChange={(e) =>
                  editId
                    ? setEditAlcoholPercent(Number(e.target.value))
                    : setNewAlcoholPercent(Number(e.target.value))
                }
              />
            </div>
          </div>

          <div className="bts-inline">
            <button
              className="bts-btn primary"
              onClick={async () => {
                if (!token) return
                try {
                  if (editId) {
                    const ok = await confirm({
                      title: 'Modifier le format',
                      message: 'Confirmer la modification de ce format ?',
                      confirmText: 'Enregistrer',
                    })
                    if (!ok) return
                    await updateFormat(token, editId, {
                      label: editLabel,
                      volumeMl: editVolumeMl,
                      alcoholPercent: editAlcoholPercent,
                    })
                    setEditId(null)
                    setEditLabel('')
                  } else {
                    await createFormat(token, {
                      label: newLabel,
                      volumeMl: newVolumeMl,
                      alcoholPercent: newAlcoholPercent,
                    })
                    setNewLabel('')
                  }
                  await refresh()
                } catch (e) {
                  setError(formatError(e))
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
                  setEditLabel('')
                }}
              >
                Annuler
              </button>
            ) : null}
          </div>
        </div>
      </aside>
    </div>
  )
}


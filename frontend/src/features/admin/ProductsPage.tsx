import { useEffect, useMemo, useState } from 'react'

import { useAuth } from '../../auth/AuthContext'
import {
  createProduct,
  deleteProduct,
  getFormats,
  getProducts,
  getTypes,
  updateProduct,
} from '../../api/adminApi'
import type { StockFormat, StockProductView, StockType } from '../../api/types'
import { useConfirm } from '../../components/confirm/ConfirmContext'

const imageOptions = [
  'produits-01.png',
  'produits-02.png',
  'produits-03.png',
  'produits-04.png',
  'produits-05.png',
] as const

export default function ProductsPage() {
  const { token } = useAuth()
  const confirm = useConfirm()

  const [types, setTypes] = useState<StockType[]>([])
  const [formats, setFormats] = useState<StockFormat[]>([])
  const [items, setItems] = useState<StockProductView[]>([])
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  const [editId, setEditId] = useState<string | null>(null)
  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [typeId, setTypeId] = useState('')
  const [formatId, setFormatId] = useState('')
  const [quantity, setQuantity] = useState<number>(0)
  const [imageKey, setImageKey] = useState<string>(imageOptions[0])

  const imageSrc = useMemo(() => `/images/${imageKey}`, [imageKey])

  async function loadAll() {
    if (!token) return
    setLoading(true)
    setError(null)
    try {
      const [t, f, p] = await Promise.all([getTypes(token), getFormats(token), getProducts(token)])
      setTypes(t)
      setFormats(f)
      setItems(p)

      // Default selections when creating a new product
      if (!editId) {
        setTypeId(t[0]?.id ?? '')
        setFormatId(f[0]?.id ?? '')
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Error')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadAll()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token])

  return (
    <div className="bts-grid">
      <section className="bts-card">
        <h2 style={{ marginTop: 0 }}>Stocks de produits</h2>
        {loading ? <div>Chargement...</div> : null}
        {error ? <div className="bts-error">{error}</div> : null}

        <table className="bts-table" aria-label="Liste produits">
          <thead>
            <tr>
              <th>Produit</th>
              <th>Type</th>
              <th>Format</th>
              <th>Quantité</th>
              <th>Image</th>
              <th style={{ width: 210 }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {items.map((p) => (
              <tr key={p.id}>
                <td>
                  <div style={{ fontWeight: 700 }}>{p.name}</div>
                  <div style={{ color: '#6f6a7d', fontSize: 13 }}>{p.description.slice(0, 40)}{p.description.length > 40 ? '…' : ''}</div>
                </td>
                <td>{p.typeName}</td>
                <td>{p.formatLabel}</td>
                <td>{p.quantity}</td>
                <td>
                  <img className="bts-thumb" src={`/images/${p.imageKey}`} alt={p.imageKey} />
                </td>
                <td>
                  <div className="bts-inline">
                    <button
                      className="bts-btn"
                      onClick={() => {
                        setEditId(p.id)
                        setName(p.name)
                        setDescription(p.description)

                        const matchingType = types.find((t) => t.name === p.typeName)
                        const matchingFormat = formats.find((f) => f.label === p.formatLabel)
                        setTypeId(matchingType?.id ?? '')
                        setFormatId(matchingFormat?.id ?? '')
                        setQuantity(p.quantity)
                        setImageKey(p.imageKey)
                      }}
                    >
                      Modifier
                    </button>
                    <button
                      className="bts-btn"
                      onClick={async () => {
                        if (!token) return
                        const ok = await confirm({
                          title: 'Supprimer le produit',
                          message: 'Confirmer la suppression de ce produit ?',
                          confirmText: 'Supprimer',
                          tone: 'danger',
                        })
                        if (!ok) return
                        try {
                          await deleteProduct(token, p.id)
                          if (editId === p.id) {
                            setEditId(null)
                            setName('')
                            setDescription('')
                          }
                          await loadAll()
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
                <td colSpan={6} style={{ color: '#6f6a7d' }}>
                  Aucun produit en stock.
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </section>

      <aside className="bts-card">
        <h3 style={{ marginTop: 0 }}>{editId ? 'Modifier' : 'Créer'}</h3>

        <div className="bts-form">
          <div className="bts-inline" style={{ justifyContent: 'space-between' }}>
            <div className="bts-inline">
              <div style={{ fontWeight: 700 }}>Aperçu</div>
              <img className="bts-thumb" src={imageSrc} alt="Aperçu produit" />
            </div>
          </div>

          <div className="bts-field">
            <label>Produit (nom)</label>
            <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Ex: Whisky" />
          </div>

          <div className="bts-field">
            <label>Description</label>
            <textarea value={description} onChange={(e) => setDescription(e.target.value)} />
          </div>

          <div className="bts-inline">
            <div className="bts-field" style={{ flex: 1 }}>
              <label>Type</label>
              <select value={typeId} onChange={(e) => setTypeId(e.target.value)}>
                {types.map((t) => (
                  <option key={t.id} value={t.id}>
                    {t.name}
                  </option>
                ))}
              </select>
            </div>

            <div className="bts-field" style={{ flex: 1 }}>
              <label>Format</label>
              <select value={formatId} onChange={(e) => setFormatId(e.target.value)}>
                {formats.map((f) => (
                  <option key={f.id} value={f.id}>
                    {f.label}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="bts-inline">
            <div className="bts-field" style={{ flex: 1 }}>
              <label>Quantité</label>
              <input type="number" value={quantity} onChange={(e) => setQuantity(Number(e.target.value))} />
            </div>

            <div className="bts-field" style={{ flex: 1 }}>
              <label>Image</label>
              <select value={imageKey} onChange={(e) => setImageKey(e.target.value)}>
                {imageOptions.map((k) => (
                  <option key={k} value={k}>
                    {k}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="bts-inline">
            <button
              className="bts-btn primary"
              onClick={async () => {
                if (!token) return
                try {
                  if (!name.trim() || !description.trim() || !typeId || !formatId || !imageKey) {
                    throw new Error('Champs obligatoires manquants')
                  }

                  if (editId) {
                    const ok = await confirm({
                      title: 'Modifier le produit',
                      message: 'Confirmer la modification de ce produit ?',
                      confirmText: 'Enregistrer',
                    })
                    if (!ok) return
                    await updateProduct(token, editId, {
                      name,
                      description,
                      typeId,
                      formatId,
                      quantity,
                      imageKey,
                    })
                  } else {
                    await createProduct(token, {
                      name,
                      description,
                      typeId,
                      formatId,
                      quantity,
                      imageKey,
                    })
                  }

                  setEditId(null)
                  setName('')
                  setDescription('')
                  await loadAll()
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
                  setName('')
                  setDescription('')
                  setQuantity(0)
                  setImageKey(imageOptions[0])
                }}
              >
                Annuler
              </button>
            ) : null}
          </div>

          <p style={{ color: '#6f6a7d', fontSize: 13, marginTop: -2 }}>
            Les images proviennent du dossier `frontend/public/images`.
          </p>
        </div>
      </aside>
    </div>
  )
}


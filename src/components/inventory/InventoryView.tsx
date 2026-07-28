import {
  useEffect,
  useRef,
  useState,
} from 'react'
import type {
  CatalogReference,
  InventoryItem,
  ValidInventoryDraft,
} from '../../inventory/inventory'
import type { InventoryRepository } from '../../inventory/inventory-repository'
import { InventoryCard } from './InventoryCard'
import { InventoryForm } from './InventoryForm'

type InventoryViewProps = {
  repository: InventoryRepository
}

function errorMessage(cause: unknown, fallback: string): string {
  return cause instanceof Error ? cause.message : fallback
}

export function InventoryView({ repository }: InventoryViewProps) {
  const [references, setReferences] = useState<CatalogReference[]>([])
  const [items, setItems] = useState<InventoryItem[]>([])
  const [loading, setLoading] = useState(true)
  const [editingItem, setEditingItem] = useState<InventoryItem | null>(null)
  const [formOpen, setFormOpen] = useState(false)
  const [deletingItem, setDeletingItem] = useState<InventoryItem | null>(null)
  const [pending, setPending] = useState(false)
  const [error, setError] = useState('')
  const errorRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (error) errorRef.current?.focus()
  }, [error])

  useEffect(() => {
    const controller = new AbortController()
    setLoading(true)
    setError('')

    void Promise.all([
      repository.references(controller.signal),
      repository.list(controller.signal),
    ]).then(([nextReferences, nextItems]) => {
      if (controller.signal.aborted) return
      setReferences(nextReferences)
      setItems(nextItems)
    }).catch((cause: unknown) => {
      if (
        controller.signal.aborted
        || (cause instanceof DOMException && cause.name === 'AbortError')
      ) return
      setError(errorMessage(
        cause,
        'Der private Bestand konnte nicht geladen werden.',
      ))
    }).finally(() => {
      if (!controller.signal.aborted) setLoading(false)
    })

    return () => controller.abort()
  }, [repository])

  function closeForm() {
    setFormOpen(false)
    setEditingItem(null)
  }

  async function save(input: ValidInventoryDraft) {
    setPending(true)
    setError('')
    try {
      if (editingItem) {
        const updated = await repository.update(editingItem.id, input)
        setItems((current) => current.map((item) => (
          item.id === updated.id ? updated : item
        )))
      } else {
        const created = await repository.create(input)
        setItems((current) => [created, ...current])
      }
      closeForm()
    } catch (cause) {
      setError(errorMessage(
        cause,
        'Der Bestandseintrag konnte nicht gespeichert werden.',
      ))
    } finally {
      setPending(false)
    }
  }

  async function confirmDelete() {
    if (!deletingItem) return
    setPending(true)
    setError('')
    try {
      await repository.remove(deletingItem.id)
      setItems((current) => current.filter(
        (item) => item.id !== deletingItem.id,
      ))
      setDeletingItem(null)
    } catch (cause) {
      setError(errorMessage(
        cause,
        'Der Bestandseintrag konnte nicht gelöscht werden.',
      ))
    } finally {
      setPending(false)
    }
  }

  return (
    <section className="inventory-view" aria-labelledby="inventory-heading">
      <header className="section-header">
        <div>
          <p className="eyebrow">Persönliches Profil</p>
          <h2 id="inventory-heading">Mein Bestand</h2>
        </div>
        {!loading ? (
          <button
            type="button"
            onClick={() => {
              setEditingItem(null)
              setFormOpen(true)
              setError('')
            }}
          >
            Eintrag hinzufügen
          </button>
        ) : null}
      </header>

      <p>
        Deine Einträge sind privat und nur in deinem Konto sichtbar.
      </p>

      {error ? (
        <div
          ref={errorRef}
          role="alert"
          tabIndex={-1}
          className="error-summary"
        >
          {error}
        </div>
      ) : null}

      {loading ? (
        <p role="status" aria-label="Privater Bestand wird geladen">
          Privater Bestand wird geladen …
        </p>
      ) : null}

      {formOpen ? (
        <InventoryForm
          key={editingItem?.id ?? 'new'}
          references={references}
          item={editingItem ?? undefined}
          pending={pending}
          onSubmit={save}
          onCancel={closeForm}
        />
      ) : null}

      {deletingItem ? (
        <section
          className="confirmation-panel"
          aria-labelledby="delete-inventory-heading"
        >
          <h3 id="delete-inventory-heading">Eintrag wirklich löschen?</h3>
          <p>
            {deletingItem.entryName} wird dauerhaft aus deinem
            privaten Bestand entfernt.
          </p>
          <div className="form-actions">
            <button
              type="button"
              disabled={pending}
              onClick={() => void confirmDelete()}
            >
              Löschen bestätigen
            </button>
            <button
              type="button"
              disabled={pending}
              onClick={() => setDeletingItem(null)}
            >
              Abbrechen
            </button>
          </div>
        </section>
      ) : null}

      {!loading && items.length === 0 ? (
        <p className="empty-state">Noch kein Bestand gespeichert.</p>
      ) : null}

      <div className="inventory-list">
        {items.map((item) => (
          <InventoryCard
            key={item.id}
            item={item}
            onEdit={() => {
              setEditingItem(item)
              setFormOpen(true)
              setError('')
            }}
            onDelete={() => {
              setDeletingItem(item)
              setError('')
            }}
          />
        ))}
      </div>
    </section>
  )
}

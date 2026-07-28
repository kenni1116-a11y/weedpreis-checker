import {
  useEffect,
  useRef,
  useState,
} from 'react'
import type { CatalogRepository } from '../../catalog/catalog-repository'
import type { CommunityRepository } from '../../community/community-repository'
import type {
  InventoryItem,
  ValidInventoryDraft,
} from '../../inventory/inventory'
import type { InventoryRepository } from '../../inventory/inventory-repository'
import {
  retryCommunityMutation,
  saveInventoryEntry,
  type PendingCommunityMutation,
} from '../../inventory/save-inventory-entry'
import { InventoryCard } from './InventoryCard'
import { InventoryForm } from './InventoryForm'

type InventoryViewProps = {
  repository: InventoryRepository
  catalogRepository: CatalogRepository
  communityRepository: CommunityRepository
  communityConsentVersion: string
}

function errorMessage(cause: unknown, fallback: string): string {
  return cause instanceof Error ? cause.message : fallback
}

export function InventoryView({
  repository,
  catalogRepository,
  communityRepository,
  communityConsentVersion,
}: InventoryViewProps) {
  const [items, setItems] = useState<InventoryItem[]>([])
  const [loading, setLoading] = useState(true)
  const [editingItem, setEditingItem] = useState<InventoryItem | null>(null)
  const [formOpen, setFormOpen] = useState(false)
  const [deletingItem, setDeletingItem] = useState<InventoryItem | null>(null)
  const [pending, setPending] = useState(false)
  const [error, setError] = useState('')
  const [status, setStatus] = useState('')
  const [pendingCommunityMutation, setPendingCommunityMutation] =
    useState<PendingCommunityMutation | null>(null)
  const errorRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (error) errorRef.current?.focus()
  }, [error])

  useEffect(() => {
    const controller = new AbortController()
    setLoading(true)
    setError('')

    void repository.list(controller.signal).then((nextItems) => {
      if (!controller.signal.aborted) setItems(nextItems)
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

  async function save(
    input: ValidInventoryDraft,
    communityMutation: PendingCommunityMutation | null,
  ) {
    setPending(true)
    setError('')
    setStatus('')
    try {
      const outcome = await saveInventoryEntry({
        itemId: editingItem?.id,
        draft: input,
        communityMutation,
        inventoryRepository: repository,
        communityRepository,
      })
      setItems((current) => {
        const exists = current.some((item) => item.id === outcome.item.id)
        return exists
          ? current.map((item) => (
              item.id === outcome.item.id ? outcome.item : item
            ))
          : [outcome.item, ...current]
      })
      closeForm()

      if (outcome.kind === 'inventory_saved_community_failed') {
        setPendingCommunityMutation(outcome.pendingCommunityMutation)
        setError(
          'Der Bestand wurde gespeichert. Der Community-Beitrag konnte nicht übernommen werden.',
        )
      } else {
        setPendingCommunityMutation(null)
        setStatus(
          outcome.community === 'saved'
            ? 'Gespeichert. Der Community-Mittelwert wird später aktualisiert.'
            : 'Gespeichert.',
        )
      }
    } catch (cause) {
      setError(errorMessage(
        cause,
        'Der Bestandseintrag konnte nicht gespeichert werden.',
      ))
    } finally {
      setPending(false)
    }
  }

  async function retryCommunity() {
    if (!pendingCommunityMutation) return
    setPending(true)
    setError('')
    try {
      await retryCommunityMutation(
        pendingCommunityMutation,
        communityRepository,
      )
      setPendingCommunityMutation(null)
      setStatus(
        'Gespeichert. Der Community-Mittelwert wird später aktualisiert.',
      )
    } catch (cause) {
      setError(errorMessage(
        cause,
        'Der Community-Beitrag konnte nicht übernommen werden.',
      ))
    } finally {
      setPending(false)
    }
  }

  async function confirmDelete() {
    if (!deletingItem) return
    setPending(true)
    setError('')
    setStatus('')
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
              setStatus('')
            }}
          >
            Eintrag hinzufügen
          </button>
        ) : null}
      </header>

      <p>Deine Einträge sind privat und nur in deinem Konto sichtbar.</p>

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
      {status ? <p role="status" className="save-status">{status}</p> : null}
      {pendingCommunityMutation ? (
        <button
          type="button"
          disabled={pending}
          onClick={() => void retryCommunity()}
        >
          Community-Beitrag erneut versuchen
        </button>
      ) : null}

      {loading ? (
        <p role="status" aria-label="Privater Bestand wird geladen">
          Privater Bestand wird geladen …
        </p>
      ) : null}

      {formOpen ? (
        <InventoryForm
          key={editingItem?.id ?? 'new'}
          catalogRepository={catalogRepository}
          communityRepository={communityRepository}
          communityConsentVersion={communityConsentVersion}
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
            {deletingItem.entryName} wird dauerhaft aus deinem privaten
            Bestand entfernt.
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
              setStatus('')
            }}
            onDelete={() => {
              setDeletingItem(item)
              setError('')
              setStatus('')
            }}
          />
        ))}
      </div>
    </section>
  )
}

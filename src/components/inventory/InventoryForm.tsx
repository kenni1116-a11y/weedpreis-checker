import {
  useEffect,
  useRef,
  useState,
  type FormEvent,
} from 'react'
import {
  inventoryDraftErrors,
  validateInventoryDraft,
  type CatalogReference,
  type InventoryDraft,
  type InventoryDraftErrors,
  type InventoryItem,
  type InventoryUnit,
  type ValidInventoryDraft,
} from '../../inventory/inventory'

type InventoryFormProps = {
  references: CatalogReference[]
  item?: InventoryItem
  pending: boolean
  onSubmit(input: ValidInventoryDraft): Promise<void>
  onCancel(): void
}

function initialDraft(item?: InventoryItem): InventoryDraft {
  return {
    entityId: item?.reference.id ?? '',
    quantity: item ? String(item.quantity) : '',
    unit: item?.unit ?? 'g',
    batch: item?.batch ?? '',
    expiresOn: item?.expiresOn ?? '',
    storageLocation: item?.storageLocation ?? '',
    note: item?.note ?? '',
  }
}

function FieldError({ message }: { message?: string }) {
  return message ? <span className="field-error">{message}</span> : null
}

export function InventoryForm({
  references,
  item,
  pending,
  onSubmit,
  onCancel,
}: InventoryFormProps) {
  const [draft, setDraft] = useState(() => initialDraft(item))
  const [errors, setErrors] = useState<InventoryDraftErrors>({})
  const summaryRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (Object.keys(errors).length > 0) summaryRef.current?.focus()
  }, [errors])

  function update<Field extends keyof InventoryDraft>(
    field: Field,
    value: InventoryDraft[Field],
  ) {
    setDraft((current) => ({ ...current, [field]: value }))
    setErrors((current) => {
      if (!current[field]) return current
      const next = { ...current }
      delete next[field]
      return next
    })
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const nextErrors = inventoryDraftErrors(draft)
    if (Object.keys(nextErrors).length > 0) {
      setErrors(nextErrors)
      return
    }
    await onSubmit(validateInventoryDraft(draft))
  }

  return (
    <form className="inventory-form" noValidate onSubmit={submit}>
      <h3>{item ? 'Bestandseintrag bearbeiten' : 'Bestandseintrag hinzufügen'}</h3>

      {Object.keys(errors).length > 0 ? (
        <div
          ref={summaryRef}
          role="alert"
          tabIndex={-1}
          className="error-summary"
        >
          <strong>Prüfe deine Angaben.</strong>
          <ul>
            {Object.values(errors).map((message) => (
              <li key={message}>{message}</li>
            ))}
          </ul>
        </div>
      ) : null}

      <label>
        Sorte oder Produkt
        <select
          required
          value={draft.entityId}
          aria-invalid={Boolean(errors.entityId)}
          onChange={(event) => update('entityId', event.target.value)}
        >
          <option value="">Bitte auswählen</option>
          {references.map((reference) => (
            <option key={reference.id} value={reference.id}>
              {reference.canonicalName}
              {' · '}
              {reference.kind === 'cultivar' ? 'Sorte' : 'Produkt'}
            </option>
          ))}
        </select>
        <FieldError message={errors.entityId} />
      </label>

      <div className="inventory-form-row">
        <label>
          Menge
          <input
            required
            inputMode="decimal"
            autoComplete="off"
            value={draft.quantity}
            aria-invalid={Boolean(errors.quantity)}
            onChange={(event) => update('quantity', event.target.value)}
          />
          <FieldError message={errors.quantity} />
        </label>

        <label>
          Einheit
          <select
            required
            value={draft.unit}
            aria-invalid={Boolean(errors.unit)}
            onChange={(event) => update(
              'unit',
              event.target.value as InventoryUnit,
            )}
          >
            <option value="g">g</option>
            <option value="ml">ml</option>
            <option value="piece">Stück</option>
          </select>
          <FieldError message={errors.unit} />
        </label>
      </div>

      <label>
        Charge (optional)
        <input
          maxLength={120}
          autoComplete="off"
          value={draft.batch}
          aria-invalid={Boolean(errors.batch)}
          onChange={(event) => update('batch', event.target.value)}
        />
        <FieldError message={errors.batch} />
      </label>

      <label>
        Ablaufdatum (optional)
        <input
          type="date"
          value={draft.expiresOn}
          aria-invalid={Boolean(errors.expiresOn)}
          onChange={(event) => update('expiresOn', event.target.value)}
        />
        <FieldError message={errors.expiresOn} />
      </label>

      <label>
        Lagerort (optional)
        <input
          maxLength={120}
          autoComplete="off"
          value={draft.storageLocation}
          aria-invalid={Boolean(errors.storageLocation)}
          onChange={(event) => update('storageLocation', event.target.value)}
        />
        <FieldError message={errors.storageLocation} />
      </label>

      <label>
        Notiz (optional)
        <textarea
          maxLength={1000}
          value={draft.note}
          aria-invalid={Boolean(errors.note)}
          onChange={(event) => update('note', event.target.value)}
        />
        <FieldError message={errors.note} />
      </label>

      <div className="form-actions">
        <button type="submit" disabled={pending}>
          {pending
            ? 'Wird gespeichert …'
            : item
              ? 'Änderungen speichern'
              : 'Speichern'}
        </button>
        <button type="button" disabled={pending} onClick={onCancel}>
          Abbrechen
        </button>
      </div>
    </form>
  )
}

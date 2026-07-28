import {
  useEffect,
  useRef,
  useState,
  type FormEvent,
} from 'react'
import type { CatalogRepository } from '../../catalog/catalog-repository'
import type { CatalogSearchMatch } from '../../catalog/catalog-search'
import type { CommunityRepository } from '../../community/community-repository'
import {
  communityContributionErrors,
  validateCommunityContribution,
  type CommunityContributionDraft,
  type PublishedCommunityAverage,
} from '../../community/community-values'
import {
  inventoryDraftErrors,
  validateInventoryDraft,
  type InventoryDraft,
  type InventoryDraftErrors,
  type InventoryItem,
  type InventoryUnit,
  type ValidInventoryDraft,
} from '../../inventory/inventory'
import type { PendingCommunityMutation } from '../../inventory/save-inventory-entry'
import { CatalogCombobox } from './CatalogCombobox'
import { CommunityAverageCompact } from './CommunityAverageCompact'
import { CommunityContributionFields } from './CommunityContributionFields'

type InventoryFormProps = {
  catalogRepository: CatalogRepository
  communityRepository: CommunityRepository
  communityConsentVersion: string
  item?: InventoryItem
  pending: boolean
  onSubmit(
    input: ValidInventoryDraft,
    communityMutation: PendingCommunityMutation | null,
  ): Promise<void>
  onCancel(): void
}

const emptyContribution: CommunityContributionDraft = {
  enabled: false,
  thcPercent: '',
  cbdPercent: '',
  sourceKind: '',
  declarationAccepted: false,
}

function initialDraft(item?: InventoryItem): InventoryDraft {
  return {
    entryName: item?.entryName ?? '',
    entityId: item?.reference?.id ?? null,
    originOneName: item?.originOneName ?? '',
    originTwoName: item?.originTwoName ?? '',
    quantity: item ? String(item.quantity) : '',
    unit: item?.unit ?? 'g',
    batch: item?.batch ?? '',
    expiresOn: item?.expiresOn ?? '',
    storageLocation: item?.storageLocation ?? '',
    note: item?.note ?? '',
  }
}

function initialMatch(item?: InventoryItem): CatalogSearchMatch | null {
  if (!item?.reference) return null
  return {
    id: item.reference.id,
    kind: item.reference.kind,
    canonicalName: item.reference.canonicalName,
    matchedName: item.entryName,
    matchReason:
      item.entryName === item.reference.canonicalName ? 'canonical' : 'alias',
    canonicalCultivarId: item.canonicalCultivarId,
    isFlower: item.isFlower,
    preferredParents: [item.originOneName, item.originTwoName],
    hasAdditionalLineage: false,
    sourcedThcLabel: null,
    sourcedCbdLabel: null,
    sourcedValueEvidence: [],
  }
}

function FieldError({ message }: { message?: string }) {
  return message ? <span className="field-error">{message}</span> : null
}

export function InventoryForm({
  catalogRepository,
  communityRepository,
  communityConsentVersion,
  item,
  pending,
  onSubmit,
  onCancel,
}: InventoryFormProps) {
  const [draft, setDraft] = useState(() => initialDraft(item))
  const [selectedMatch, setSelectedMatch] =
    useState<CatalogSearchMatch | null>(() => initialMatch(item))
  const [errors, setErrors] = useState<InventoryDraftErrors>({})
  const [contribution, setContribution] =
    useState<CommunityContributionDraft>(emptyContribution)
  const [contributionErrors, setContributionErrors] =
    useState<Partial<Record<keyof CommunityContributionDraft, string>>>({})
  const [average, setAverage] =
    useState<PublishedCommunityAverage | null>(null)
  const [hadOwnContribution, setHadOwnContribution] = useState(false)
  const [communityLoadFailed, setCommunityLoadFailed] = useState(false)
  const summaryRef = useRef<HTMLDivElement>(null)

  const eligibleCultivarId =
    selectedMatch?.isFlower
      ? selectedMatch.canonicalCultivarId
      : null

  useEffect(() => {
    if (Object.keys(errors).length > 0) summaryRef.current?.focus()
  }, [errors])

  useEffect(() => {
    if (!eligibleCultivarId) {
      setContribution(emptyContribution)
      setAverage(null)
      setHadOwnContribution(false)
      setCommunityLoadFailed(false)
      return
    }

    const controller = new AbortController()
    setCommunityLoadFailed(false)
    void Promise.all([
      communityRepository.getOwn(eligibleCultivarId, controller.signal),
      communityRepository.getPublished(
        eligibleCultivarId,
        controller.signal,
      ),
    ]).then(([own, published]) => {
      if (controller.signal.aborted) return
      setAverage(published)
      setHadOwnContribution(own !== null)
      setContribution(own
        ? {
            enabled: true,
            thcPercent: String(own.thcPercent).replace('.', ','),
            cbdPercent: String(own.cbdPercent).replace('.', ','),
            sourceKind: own.sourceKind,
            declarationAccepted: true,
          }
        : emptyContribution)
    }).catch((cause: unknown) => {
      if (
        controller.signal.aborted
        || (cause instanceof DOMException && cause.name === 'AbortError')
      ) return
      setCommunityLoadFailed(true)
    })

    return () => controller.abort()
  }, [communityRepository, eligibleCultivarId])

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

  function catalogChanged(
    entryName: string,
    match: CatalogSearchMatch | null,
  ) {
    setSelectedMatch(match)
    setDraft((current) => ({
      ...current,
      entryName,
      entityId: match?.id ?? null,
      originOneName: match?.preferredParents[0] ?? '',
      originTwoName: match?.preferredParents[1] ?? '',
    }))
    setContribution(emptyContribution)
    setContributionErrors({})
    setAverage(null)
    setHadOwnContribution(false)
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const nextErrors = inventoryDraftErrors(draft)
    const nextContributionErrors = contribution.enabled
      ? communityContributionErrors(contribution)
      : {}
    setErrors(nextErrors)
    setContributionErrors(nextContributionErrors)
    if (
      Object.keys(nextErrors).length > 0
      || Object.keys(nextContributionErrors).length > 0
    ) return

    let mutation: PendingCommunityMutation | null = null
    if (eligibleCultivarId && contribution.enabled) {
      mutation = {
        kind: 'upsert',
        input: validateCommunityContribution({
          cultivarId: eligibleCultivarId,
          consentVersion: communityConsentVersion,
          draft: contribution,
        }),
      }
    } else if (eligibleCultivarId && hadOwnContribution) {
      mutation = { kind: 'remove', cultivarId: eligibleCultivarId }
    }

    await onSubmit(validateInventoryDraft(draft), mutation)
  }

  return (
    <form className="inventory-form" noValidate onSubmit={submit}>
      <h3>{item ? 'Bestandseintrag bearbeiten' : 'Bestandseintrag hinzufügen'}</h3>

      {Object.keys(errors).length > 0
        || Object.keys(contributionErrors).length > 0 ? (
          <div
            ref={summaryRef}
            role="alert"
            tabIndex={-1}
            className="error-summary"
          >
            <strong>Prüfe deine Angaben.</strong>
            <ul>
              {[...Object.values(errors), ...Object.values(contributionErrors)]
                .map((message) => <li key={message}>{message}</li>)}
            </ul>
          </div>
        ) : null}

      <CatalogCombobox
        value={draft.entryName}
        selectedMatch={selectedMatch}
        repository={catalogRepository}
        onChange={catalogChanged}
      />
      <FieldError message={errors.entryName} />

      {draft.entryName.trim() && !selectedMatch ? (
        <p className="private-entry-hint">
          Nur privat gespeichert · keine Weedypedia-Zuordnung
        </p>
      ) : null}

      {draft.entryName.trim() ? (
        <div className="inventory-form-row origin-fields">
          <label>
            Herkunft 1 (optional)
            <input
              maxLength={160}
              autoComplete="off"
              value={draft.originOneName}
              aria-invalid={Boolean(errors.originOneName)}
              onChange={(event) => update('originOneName', event.target.value)}
            />
            <FieldError message={errors.originOneName} />
          </label>
          <label>
            Herkunft 2 (optional)
            <input
              maxLength={160}
              autoComplete="off"
              value={draft.originTwoName}
              aria-invalid={Boolean(errors.originTwoName)}
              onChange={(event) => update('originTwoName', event.target.value)}
            />
            <FieldError message={errors.originTwoName} />
          </label>
        </div>
      ) : null}

      {selectedMatch?.hasAdditionalLineage ? (
        <p className="lineage-hint">
          Weitere belegte Herkunftsangaben im Sortenprofil
        </p>
      ) : null}

      {selectedMatch ? (
        <CommunityAverageCompact match={selectedMatch} average={average} />
      ) : null}
      {communityLoadFailed ? (
        <p role="alert" className="field-error">
          Community-Werte sind derzeit nicht verfügbar.
        </p>
      ) : null}

      <div className="inventory-form-row quantity-row">
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

      {eligibleCultivarId ? (
        <CommunityContributionFields
          draft={contribution}
          errors={contributionErrors}
          onChange={(next) => {
            setContribution(next)
            setContributionErrors({})
          }}
        />
      ) : null}

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

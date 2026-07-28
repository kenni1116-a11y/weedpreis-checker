export const inventoryUnits = ['g', 'ml', 'piece'] as const

export type InventoryUnit = (typeof inventoryUnits)[number]

export type InventoryReference = {
  id: string
  kind: 'cultivar' | 'product'
  canonicalName: string
}

/** @deprecated Inventory search now owns catalog discovery. */
export type CatalogReference = InventoryReference

export type InventoryItem = {
  id: string
  entryName: string
  reference: InventoryReference | null
  canonicalCultivarId: string | null
  isFlower: boolean
  originOneName: string | null
  originTwoName: string | null
  quantity: number
  unit: InventoryUnit
  batch: string | null
  expiresOn: string | null
  storageLocation: string | null
  note: string | null
  createdAt: string
  updatedAt: string
}

export type InventoryDraft = {
  entryName: string
  entityId: string | null
  originOneName: string
  originTwoName: string
  quantity: string
  unit: InventoryUnit
  batch: string
  expiresOn: string
  storageLocation: string
  note: string
}

export type ValidInventoryDraft = {
  entryName: string
  entityId: string | null
  originOneName: string | null
  originTwoName: string | null
  quantity: number
  unit: InventoryUnit
  batch: string | null
  expiresOn: string | null
  storageLocation: string | null
  note: string | null
}

export type InventoryDraftErrors = Partial<
  Record<keyof InventoryDraft, string>
>

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
const decimalPattern = /^(?:0|[1-9]\d*)(?:\.\d{1,3})?$/
const isoDatePattern = /^(\d{4})-(\d{2})-(\d{2})$/

function isStrictIsoDate(value: string): boolean {
  const match = isoDatePattern.exec(value)
  if (!match) return false

  const year = Number(match[1])
  const month = Number(match[2])
  const day = Number(match[3])
  const date = new Date(Date.UTC(year, month - 1, day))

  return (
    date.getUTCFullYear() === year
    && date.getUTCMonth() === month - 1
    && date.getUTCDate() === day
  )
}

function optionalText(
  value: string,
  maximumLength: number,
): string | null {
  const trimmed = value.trim()
  if (!trimmed) return null
  return trimmed.length <= maximumLength ? trimmed : null
}

export function inventoryDraftErrors(
  draft: InventoryDraft,
): InventoryDraftErrors {
  const errors: InventoryDraftErrors = {}
  const entryName = draft.entryName.trim()
  const entityId = draft.entityId?.trim() ?? null
  const quantityText = draft.quantity.trim()
  const quantity = Number(quantityText)

  if (entryName.length < 1 || entryName.length > 160) {
    errors.entryName = 'Der Name muss zwischen 1 und 160 Zeichen lang sein.'
  }

  if (entityId !== null && !uuidPattern.test(entityId)) {
    errors.entityId =
      'Wähle eine gültige Referenz aus oder nutze Freitext.'
  }

  if (draft.originOneName.trim().length > 160) {
    errors.originOneName =
      'Die Herkunft darf höchstens 160 Zeichen enthalten.'
  }

  if (draft.originTwoName.trim().length > 160) {
    errors.originTwoName =
      'Die Herkunft darf höchstens 160 Zeichen enthalten.'
  }

  if (
    !decimalPattern.test(quantityText)
    || !Number.isFinite(quantity)
    || quantity <= 0
    || quantity > 100000
  ) {
    errors.quantity =
      'Die Menge muss größer als 0 und höchstens 100000 sein.'
  }

  if (!inventoryUnits.includes(draft.unit)) {
    errors.unit = 'Wähle eine gültige Einheit: g, ml oder Stück.'
  }

  if (draft.batch.trim().length > 120) {
    errors.batch = 'Die Charge darf höchstens 120 Zeichen enthalten.'
  }

  const expiresOn = draft.expiresOn.trim()
  if (expiresOn && !isStrictIsoDate(expiresOn)) {
    errors.expiresOn =
      'Verwende ein gültiges Datum im Format JJJJ-MM-TT.'
  }

  if (draft.storageLocation.trim().length > 120) {
    errors.storageLocation =
      'Der Lagerort darf höchstens 120 Zeichen enthalten.'
  }

  if (draft.note.trim().length > 1000) {
    errors.note = 'Die Notiz darf höchstens 1000 Zeichen enthalten.'
  }

  return errors
}

export function validateInventoryDraft(
  draft: InventoryDraft,
): ValidInventoryDraft {
  const errors = inventoryDraftErrors(draft)
  const firstError = Object.values(errors)[0]
  if (firstError) throw new Error(firstError)

  return {
    entryName: draft.entryName.trim(),
    entityId: draft.entityId?.trim() || null,
    originOneName: optionalText(draft.originOneName, 160),
    originTwoName: optionalText(draft.originTwoName, 160),
    quantity: Number(draft.quantity.trim()),
    unit: draft.unit,
    batch: optionalText(draft.batch, 120),
    expiresOn: optionalText(draft.expiresOn, 10),
    storageLocation: optionalText(draft.storageLocation, 120),
    note: optionalText(draft.note, 1000),
  }
}

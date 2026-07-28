import { describe, expect, it } from 'vitest'
import {
  inventoryDraftErrors,
  validateInventoryDraft,
  type InventoryDraft,
} from './inventory'

const entityId = '10000000-0000-4000-8000-000000000001'

function validDraft(
  overrides: Partial<InventoryDraft> = {},
): InventoryDraft {
  return {
    entityId,
    quantity: '3.5',
    unit: 'g',
    batch: '',
    expiresOn: '',
    storageLocation: '',
    note: '',
    ...overrides,
  }
}

describe('validateInventoryDraft', () => {
  it('accepts only the minimal required fields', () => {
    expect(validateInventoryDraft(validDraft())).toEqual({
      entityId,
      quantity: 3.5,
      unit: 'g',
      batch: null,
      expiresOn: null,
      storageLocation: null,
      note: null,
    })
  })

  it('trims optional text without inventing values', () => {
    expect(validateInventoryDraft(validDraft({
      batch: '  Charge 24  ',
      expiresOn: '2027-02-28',
      storageLocation: '  Schrank oben ',
      note: '  Originalverpackt.  ',
      unit: 'piece',
    }))).toMatchObject({
      batch: 'Charge 24',
      expiresOn: '2027-02-28',
      storageLocation: 'Schrank oben',
      note: 'Originalverpackt.',
      unit: 'piece',
    })
  })

  it.each(['0', '-1', '100000.001', 'not-a-number', '', '1,5'])(
    'rejects invalid quantity %s',
    (quantity) => {
      expect(() =>
        validateInventoryDraft(validDraft({ quantity })),
      ).toThrow('Menge')
    },
  )

  it('rejects quantities with more precision than the database supports', () => {
    expect(() =>
      validateInventoryDraft(validDraft({ quantity: '0.0001' })),
    ).toThrow('Menge')
  })

  it.each(['kg', 'tablets', ''])('rejects invalid unit %s', (unit) => {
    expect(() =>
      validateInventoryDraft(validDraft({
        unit: unit as InventoryDraft['unit'],
      })),
    ).toThrow('Einheit')
  })

  it('rejects an invalid catalog reference', () => {
    expect(() =>
      validateInventoryDraft(validDraft({ entityId: 'not-a-uuid' })),
    ).toThrow('Referenz')
  })

  it.each([
    ['2026-02-29'],
    ['2027-13-01'],
    ['2027-04-31'],
    ['27-01-01'],
    ['2027-1-01'],
  ])('strictly rejects invalid ISO date %s', (expiresOn) => {
    expect(() =>
      validateInventoryDraft(validDraft({ expiresOn })),
    ).toThrow('Datum')
  })

  it.each([
    ['batch', 'x'.repeat(121)],
    ['storageLocation', 'x'.repeat(121)],
    ['note', 'x'.repeat(1001)],
  ] as const)('enforces the database limit for %s', (field, value) => {
    expect(() =>
      validateInventoryDraft(validDraft({ [field]: value })),
    ).toThrow('Zeichen')
  })

  it('returns a field-error map for accessible forms', () => {
    expect(inventoryDraftErrors(validDraft({
      entityId: '',
      quantity: '0',
      unit: 'kg' as InventoryDraft['unit'],
      expiresOn: '2026-02-29',
      note: 'x'.repeat(1001),
    }))).toEqual({
      entityId: 'Wähle eine gültige Referenz aus.',
      quantity: 'Die Menge muss größer als 0 und höchstens 100000 sein.',
      unit: 'Wähle eine gültige Einheit: g, ml oder Stück.',
      expiresOn: 'Verwende ein gültiges Datum im Format JJJJ-MM-TT.',
      note: 'Die Notiz darf höchstens 1000 Zeichen enthalten.',
    })
  })
})

import { describe, expect, it } from 'vitest'
import { InMemoryInventoryRepository } from './in-memory-inventory-repository'
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
    entryName: 'Gorilla Skittlez',
    entityId,
    originOneName: ' Gorilla Glue ',
    originTwoName: ' Skittlez ',
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
  it('preserves a user alias while retaining a known reference', () => {
    expect(validateInventoryDraft(validDraft())).toEqual({
      entryName: 'Gorilla Skittlez',
      entityId,
      originOneName: 'Gorilla Glue',
      originTwoName: 'Skittlez',
      quantity: 3.5,
      unit: 'g',
      batch: null,
      expiresOn: null,
      storageLocation: null,
      note: null,
    })
  })

  it('accepts an unmatched private entry without a reference', () => {
    expect(
      validateInventoryDraft(
        validDraft({
          entryName: ' Meine private Sorte ',
          entityId: null,
          originOneName: '',
          originTwoName: '',
        }),
      ),
    ).toMatchObject({
      entryName: 'Meine private Sorte',
      entityId: null,
      originOneName: null,
      originTwoName: null,
    })
  })

  it.each(['', ' ', 'x'.repeat(161)])(
    'rejects invalid entry name %j',
    (entryName) => {
      expect(() =>
        validateInventoryDraft(validDraft({ entryName })),
      ).toThrow('Name')
    },
  )

  it.each(['originOneName', 'originTwoName'] as const)(
    'limits the private %s',
    (field) => {
      expect(() =>
        validateInventoryDraft(validDraft({ [field]: 'x'.repeat(161) })),
      ).toThrow('Herkunft')
    },
  )

  it('rejects an invalid non-null catalog reference', () => {
    expect(() =>
      validateInventoryDraft(validDraft({ entityId: 'not-a-uuid' })),
    ).toThrow('Referenz')
  })

  it('does not derive public or flower data for free text in memory', async () => {
    const repository = new InMemoryInventoryRepository({
      createId: () => '20000000-0000-4000-8000-000000000001',
      now: () => new Date('2026-07-28T12:00:00.000Z'),
    })

    await expect(
      repository.create(
        validateInventoryDraft(
          validDraft({
            entryName: 'Nur mein Eintrag',
            entityId: null,
            originOneName: '',
            originTwoName: '',
          }),
        ),
      ),
    ).resolves.toMatchObject({
      entryName: 'Nur mein Eintrag',
      reference: null,
      canonicalCultivarId: null,
      isFlower: false,
    })
  })

  it('keeps existing quantity, unit, date and optional text constraints', () => {
    expect(
      validateInventoryDraft(
        validDraft({
          batch: '  Charge 24  ',
          expiresOn: '2027-02-28',
          storageLocation: '  Schrank oben ',
          note: '  Originalverpackt.  ',
          unit: 'piece',
        }),
      ),
    ).toMatchObject({
      batch: 'Charge 24',
      expiresOn: '2027-02-28',
      storageLocation: 'Schrank oben',
      note: 'Originalverpackt.',
      unit: 'piece',
    })

    for (const quantity of [
      '0',
      '-1',
      '100000.001',
      'not-a-number',
      '',
      '1,5',
      '0.0001',
    ]) {
      expect(() =>
        validateInventoryDraft(validDraft({ quantity })),
      ).toThrow('Menge')
    }

    for (const expiresOn of [
      '2026-02-29',
      '2027-13-01',
      '2027-04-31',
      '27-01-01',
      '2027-1-01',
    ]) {
      expect(() =>
        validateInventoryDraft(validDraft({ expiresOn })),
      ).toThrow('Datum')
    }

    for (const [field, value] of [
      ['batch', 'x'.repeat(121)],
      ['storageLocation', 'x'.repeat(121)],
      ['note', 'x'.repeat(1001)],
    ] as const) {
      expect(() =>
        validateInventoryDraft(validDraft({ [field]: value })),
      ).toThrow('Zeichen')
    }
  })

  it('returns field errors for accessible forms', () => {
    expect(
      inventoryDraftErrors(
        validDraft({
          entryName: '',
          entityId: 'invalid',
          originOneName: 'x'.repeat(161),
          quantity: '0',
          unit: 'kg' as InventoryDraft['unit'],
          expiresOn: '2026-02-29',
        }),
      ),
    ).toMatchObject({
      entryName: 'Der Name muss zwischen 1 und 160 Zeichen lang sein.',
      entityId: 'Wähle eine gültige Referenz aus oder nutze Freitext.',
      originOneName: 'Die Herkunft darf höchstens 160 Zeichen enthalten.',
      quantity: 'Die Menge muss größer als 0 und höchstens 100000 sein.',
      unit: 'Wähle eine gültige Einheit: g, ml oder Stück.',
      expiresOn: 'Verwende ein gültiges Datum im Format JJJJ-MM-TT.',
    })
  })
})

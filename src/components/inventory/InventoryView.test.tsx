import {
  cleanup,
  render,
  screen,
  waitFor,
  within,
} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { InMemoryCatalogRepository } from '../../catalog/in-memory-catalog-repository'
import type { CatalogSearchMatch } from '../../catalog/catalog-search'
import { InMemoryCommunityRepository } from '../../community/in-memory-community-repository'
import type { CommunityRepository } from '../../community/community-repository'
import { unrealisticFlowerValueMessage } from '../../community/community-values'
import { InMemoryInventoryRepository } from '../../inventory/in-memory-inventory-repository'
import type { InventoryItem } from '../../inventory/inventory'
import { InventoryView } from './InventoryView'

const consentVersion = 'weedypedia-community-values-2026-07-28'
const cultivarId = '51000000-0000-4000-8000-000000000001'
const itemId = '52000000-0000-4000-8000-000000000001'

const aliasMatch: CatalogSearchMatch = {
  id: cultivarId,
  kind: 'cultivar',
  canonicalName: 'Synthetic Cultivar',
  matchedName: 'Synthetic Alias',
  matchReason: 'alias',
  canonicalCultivarId: cultivarId,
  isFlower: true,
  preferredParents: ['Parent One', 'Parent Two'],
  hasAdditionalLineage: true,
  sourcedThcLabel: '22,4 %',
  sourcedCbdLabel: '0,8 %',
  sourcedValueEvidence: [],
}

function existingItem(
  overrides: Partial<InventoryItem> = {},
): InventoryItem {
  return {
    id: itemId,
    entryName: 'Synthetic Alias',
    reference: {
      id: cultivarId,
      kind: 'cultivar',
      canonicalName: 'Synthetic Cultivar',
    },
    canonicalCultivarId: cultivarId,
    isFlower: true,
    originOneName: 'Parent One',
    originTwoName: 'Parent Two',
    quantity: 2,
    unit: 'g',
    batch: null,
    expiresOn: null,
    storageLocation: null,
    note: null,
    createdAt: '2026-07-28T12:00:00.000Z',
    updatedAt: '2026-07-28T12:00:00.000Z',
    ...overrides,
  }
}

function setup(options: {
  matches?: CatalogSearchMatch[]
  items?: InventoryItem[]
  community?: CommunityRepository
} = {}) {
  const inventory = new InMemoryInventoryRepository({
    references: [{
      id: cultivarId,
      kind: 'cultivar',
      canonicalName: 'Synthetic Cultivar',
      canonicalCultivarId: cultivarId,
      isFlower: true,
    }],
    items: options.items,
    createId: () => itemId,
    now: () => new Date('2026-07-28T12:30:00.000Z'),
  })
  const catalog = new InMemoryCatalogRepository(
    options.matches ?? [aliasMatch],
  )
  const community = options.community ?? new InMemoryCommunityRepository({
    published: [{
      cultivarId,
      thcMean: 21.3,
      cbdMean: 0.7,
      contributorBand: '5+',
      computedAt: '2026-07-28T12:00:00.000Z',
    }],
    now: () => new Date('2026-07-28T12:31:00.000Z'),
  })
  const view = render(
    <InventoryView
      repository={inventory}
      catalogRepository={catalog}
      communityRepository={community}
      communityConsentVersion={consentVersion}
    />,
  )
  return { inventory, catalog, community, view }
}

async function openAddForm() {
  await userEvent.click(
    await screen.findByRole('button', { name: 'Eintrag hinzufügen' }),
  )
}

async function searchAndSelectAlias() {
  const input = screen.getByRole('combobox', {
    name: 'Sorte oder Produkt',
  })
  await userEvent.type(input, 'Synthetic Alias')
  const listbox = await screen.findByRole('listbox')
  await userEvent.click(within(listbox).getByRole('option'))
  return input
}

describe('InventoryView', () => {
  afterEach(() => {
    cleanup()
    vi.restoreAllMocks()
  })

  it('explains the private empty state', async () => {
    setup()

    expect(
      await screen.findByText('Noch kein Bestand gespeichert.'),
    ).toBeInTheDocument()
    expect(screen.getByText(
      'Deine Einträge sind privat und nur in deinem Konto sichtbar.',
    )).toBeInTheDocument()
  })

  it('preserves an alias, prefills editable origins, and saves one pair', async () => {
    const active = setup()
    const upsert = vi.spyOn(active.community, 'upsert')
    await openAddForm()
    const name = await searchAndSelectAlias()

    expect(name).toHaveValue('Synthetic Alias')
    expect(screen.getByText(
      'Kanonischer Vorschlag: Synthetic Cultivar',
    )).toBeInTheDocument()
    expect(screen.getByLabelText('Herkunft 1 (optional)')).toHaveValue(
      'Parent One',
    )
    expect(screen.getByLabelText('Herkunft 2 (optional)')).toHaveValue(
      'Parent Two',
    )
    expect(screen.getByText(
      'Weitere belegte Herkunftsangaben im Sortenprofil',
    )).toBeInTheDocument()
    expect(screen.getByText('THC 22,4 %')).toBeInTheDocument()
    expect(screen.getByText('THC 21,3 %')).toBeInTheDocument()

    await userEvent.clear(screen.getByLabelText('Herkunft 2 (optional)'))
    await userEvent.type(
      screen.getByLabelText('Herkunft 2 (optional)'),
      'Private Parent',
    )
    await userEvent.type(screen.getByLabelText('Menge'), '3.5')
    await userEvent.click(screen.getByLabelText(
      'Community-Werte freiwillig beitragen',
    ))
    await userEvent.type(screen.getByLabelText('THC in Prozent'), '21,3')
    await userEvent.type(screen.getByLabelText('CBD in Prozent'), '0,7')
    await userEvent.selectOptions(
      screen.getByLabelText('Quelle der Werte'),
      'laboratory',
    )
    await userEvent.click(screen.getByLabelText(
      'Ich bestätige: Die Werte stammen vom Etikett oder aus einem Laborbericht und sind nicht geschätzt.',
    ))
    await userEvent.click(screen.getByRole('button', { name: 'Speichern' }))

    expect(await screen.findByRole('status')).toHaveTextContent(
      'Gespeichert. Der Community-Mittelwert wird später aktualisiert.',
    )
    expect(upsert).toHaveBeenCalledWith(expect.objectContaining({
      cultivarId,
      thcPercent: 21.3,
      cbdPercent: 0.7,
      sourceKind: 'laboratory',
    }))
    expect(screen.getByRole(
      'heading',
      { name: 'Synthetic Alias' },
    )).toBeInTheDocument()
    expect(screen.getByText('Private Parent')).toBeInTheDocument()
  })

  it('saves an unmatched name privately without community calls', async () => {
    const active = setup({ matches: [] })
    const upsert = vi.spyOn(active.community, 'upsert')
    await openAddForm()

    await userEvent.type(
      screen.getByRole('combobox', { name: 'Sorte oder Produkt' }),
      'My unmatched flower',
    )
    expect(await screen.findByText(
      'Kein Katalogtreffer. Der Name kann privat gespeichert werden.',
    )).toBeInTheDocument()
    expect(screen.getByText(
      'Nur privat gespeichert · keine Weedypedia-Zuordnung',
    )).toBeInTheDocument()
    expect(screen.queryByLabelText(
      'Community-Werte freiwillig beitragen',
    )).not.toBeInTheDocument()

    await userEvent.type(screen.getByLabelText('Menge'), '1')
    await userEvent.click(screen.getByRole('button', { name: 'Speichern' }))

    expect(await screen.findByRole(
      'heading',
      { name: 'My unmatched flower' },
    )).toBeInTheDocument()
    expect(upsert).not.toHaveBeenCalled()
  })

  it('rejects flower values above 70 with the approved copy', async () => {
    const active = setup()
    const create = vi.spyOn(active.inventory, 'create')
    await openAddForm()
    await searchAndSelectAlias()
    await userEvent.type(screen.getByLabelText('Menge'), '1')
    await userEvent.click(screen.getByLabelText(
      'Community-Werte freiwillig beitragen',
    ))
    await userEvent.type(screen.getByLabelText('THC in Prozent'), '70,01')
    await userEvent.type(screen.getByLabelText('CBD in Prozent'), '0')
    await userEvent.selectOptions(
      screen.getByLabelText('Quelle der Werte'),
      'label',
    )
    await userEvent.click(screen.getByLabelText(
      'Ich bestätige: Die Werte stammen vom Etikett oder aus einem Laborbericht und sind nicht geschätzt.',
    ))
    await userEvent.click(screen.getByRole('button', { name: 'Speichern' }))

    expect(screen.getByRole('alert')).toHaveTextContent(
      unrealisticFlowerValueMessage,
    )
    expect(create).not.toHaveBeenCalled()
  })

  it('shows partial success and retries only the contribution', async () => {
    const community = new InMemoryCommunityRepository()
    const upsert = vi.spyOn(community, 'upsert')
      .mockRejectedValueOnce(new Error('failed'))
      .mockResolvedValueOnce({
        cultivarId,
        thcPercent: 20,
        cbdPercent: 1,
        sourceKind: 'label',
        consentVersion,
        updatedAt: '2026-07-28T13:00:00.000Z',
      })
    const active = setup({ community })
    const create = vi.spyOn(active.inventory, 'create')
    await openAddForm()
    await searchAndSelectAlias()
    await userEvent.type(screen.getByLabelText('Menge'), '1')
    await userEvent.click(screen.getByLabelText(
      'Community-Werte freiwillig beitragen',
    ))
    await userEvent.type(screen.getByLabelText('THC in Prozent'), '20')
    await userEvent.type(screen.getByLabelText('CBD in Prozent'), '1')
    await userEvent.selectOptions(
      screen.getByLabelText('Quelle der Werte'),
      'label',
    )
    await userEvent.click(screen.getByLabelText(
      'Ich bestätige: Die Werte stammen vom Etikett oder aus einem Laborbericht und sind nicht geschätzt.',
    ))
    await userEvent.click(screen.getByRole('button', { name: 'Speichern' }))

    expect(await screen.findByRole('alert')).toHaveTextContent(
      'Der Bestand wurde gespeichert. Der Community-Beitrag konnte nicht übernommen werden.',
    )
    await userEvent.click(screen.getByRole(
      'button',
      { name: 'Community-Beitrag erneut versuchen' },
    ))
    await waitFor(() => expect(upsert).toHaveBeenCalledTimes(2))
    expect(create).toHaveBeenCalledTimes(1)
    expect(await screen.findByRole('status')).toHaveTextContent(
      'Gespeichert. Der Community-Mittelwert wird später aktualisiert.',
    )
  })

  it('keeps the user-entered name and private origins on the card', async () => {
    setup({ items: [existingItem()] })

    expect(await screen.findByRole(
      'heading',
      { name: 'Synthetic Alias' },
    )).toBeInTheDocument()
    expect(screen.getByText('Kanonisch: Synthetic Cultivar')).toBeInTheDocument()
    expect(screen.getByText('Parent One')).toBeInTheDocument()
    expect(screen.getByText('Parent Two')).toBeInTheDocument()
    expect(screen.queryByText('THC 21,3 %')).not.toBeInTheDocument()
  })

  it('requires confirmation before deleting', async () => {
    const active = setup({ items: [existingItem()] })
    const remove = vi.spyOn(active.inventory, 'remove')

    await userEvent.click(await screen.findByRole(
      'button',
      { name: 'Synthetic Alias löschen' },
    ))
    expect(remove).not.toHaveBeenCalled()
    await userEvent.click(screen.getByRole(
      'button',
      { name: 'Löschen bestätigen' },
    ))

    await waitFor(() => expect(remove).toHaveBeenCalledWith(itemId))
    expect(screen.queryByRole(
      'heading',
      { name: 'Synthetic Alias' },
    )).not.toBeInTheDocument()
  })

  it('never asks for price, scanner, health, or consumption data', async () => {
    setup()
    await openAddForm()

    expect(screen.queryByLabelText(/preis/i)).not.toBeInTheDocument()
    expect(screen.queryByLabelText(/scanner|kamera|upload/i))
      .not.toBeInTheDocument()
    expect(screen.queryByLabelText(/dosierung|konsum|diagnose|rezept|wirkung/i))
      .not.toBeInTheDocument()
  })
})

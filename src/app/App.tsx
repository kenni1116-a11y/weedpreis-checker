import { useMemo, useState } from 'react'
import { AgeGate } from '../components/AgeGate'
import { AppNavigation, type AppTab } from '../components/AppNavigation'
import { FavoritesView } from '../components/FavoritesView'
import { InfoView } from '../components/InfoView'
import { SearchExperience } from '../components/SearchExperience'
import { rankOffers } from '../domain/pricing'
import { inMemoryOffersRepository, syntheticOffers } from '../data/synthetic-offers'
import { devicePreferences } from '../storage/device-preferences'

export function App() {
  const [adult, setAdult] = useState(devicePreferences.isAdultConfirmed())
  const [tab, setTab] = useState<AppTab>('search')
  const favoriteResults = useMemo(
    () => rankOffers(syntheticOffers, { mode: 'shipping', grams: 10 }, new Date()),
    [],
  )

  if (!adult) {
    return (
      <main className="app-shell">
        <AgeGate onConfirm={() => { devicePreferences.confirmAdult(); setAdult(true) }} />
      </main>
    )
  }

  return (
    <main className="app-shell">
      <header><h1>Weedpreis</h1><p>Neutraler Apothekenvergleich</p></header>
      <div role="status" className="test-data-banner">Ausschließlich synthetische Testdaten</div>
      <AppNavigation active={tab} onSelect={setTab} />
      {tab === 'search' && <SearchExperience repository={inMemoryOffersRepository} />}
      {tab === 'favorites' && <FavoritesView results={favoriteResults} grams={10} />}
      {tab === 'info' && <InfoView />}
    </main>
  )
}

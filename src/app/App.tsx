import { useState } from 'react'
import { AgeGate } from '../components/AgeGate'
import { AppNavigation, type AppTab } from '../components/AppNavigation'
import { FavoritesView } from '../components/FavoritesView'
import { InfoView } from '../components/InfoView'
import { SearchExperience } from '../components/SearchExperience'
import type { OffersRepository } from '../data/offers-repository'
import type { PricingContext } from '../domain/offer'
import { inMemoryOffersRepository } from '../data/synthetic-offers'
import { devicePreferences } from '../storage/device-preferences'

export function App({ repository = inMemoryOffersRepository }: { repository?: OffersRepository } = {}) {
  const [adult, setAdult] = useState(devicePreferences.isAdultConfirmed())
  const [tab, setTab] = useState<AppTab>('search')
  const [pricingContext, setPricingContext] = useState<PricingContext>({ mode: 'shipping', quantity: 10 })

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
      {tab === 'search' && (
        <SearchExperience
          repository={repository}
          onResultsChange={(_, query) => {
            setPricingContext({ mode: query.mode, quantity: query.quantity })
          }}
        />
      )}
      {tab === 'favorites' && (
        <FavoritesView repository={repository} pricingContext={pricingContext} />
      )}
      {tab === 'info' && <InfoView />}
    </main>
  )
}

import { useState } from 'react'
import { AgeGate } from '../components/AgeGate'
import { SearchExperience } from '../components/SearchExperience'
import { inMemoryOffersRepository } from '../data/synthetic-offers'
import { devicePreferences } from '../storage/device-preferences'

export function App() {
  const [adult, setAdult] = useState(devicePreferences.isAdultConfirmed())

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
      <SearchExperience repository={inMemoryOffersRepository} />
    </main>
  )
}

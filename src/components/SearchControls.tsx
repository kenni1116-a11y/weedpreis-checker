import { useState } from 'react'
import type { FulfillmentMode, OfferQuery, ProductForm } from '../domain/offer'

type SearchControlsProps = {
  onSearch: (query: OfferQuery) => void
}

export function SearchControls({ onSearch }: SearchControlsProps) {
  const [text, setText] = useState('')
  const [quantity, setQuantity] = useState(10)
  const [mode, setMode] = useState<FulfillmentMode>('shipping')
  const [form, setForm] = useState<ProductForm | ''>('')
  const [minThcPercent, setMinThcPercent] = useState('')

  function submitSearch(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    onSearch({
      text,
      quantity,
      mode,
      form: form || undefined,
      minThcPercent: minThcPercent === '' ? undefined : Number(minThcPercent),
    })
  }

  return (
    <form onSubmit={submitSearch} aria-label="Angebote suchen">
      <fieldset>
        <legend>Bezugsart</legend>
        <button type="button" aria-pressed={mode === 'shipping'} onClick={() => setMode('shipping')}>
          Versand
        </button>
        <button type="button" aria-pressed={mode === 'pickup'} onClick={() => setMode('pickup')}>
          Abholung
        </button>
      </fieldset>

      <label>
        Präparat oder Hersteller
        <input type="search" value={text} onChange={(event) => setText(event.target.value)} />
      </label>
      <label htmlFor="quantity">Menge</label>
      <input
        id="quantity"
        type="number"
        min="1"
        max="100"
        value={quantity}
        aria-describedby="quantity-hint"
        onChange={(event) => setQuantity(Number(event.target.value))}
      />
      <p id="quantity-hint" className="field-hint">Blüten in g, Extrakte in ml</p>
      <label>
        Darreichungsform
        <select value={form} onChange={(event) => setForm(event.target.value as ProductForm | '')}>
          <option value="">Alle Formen</option>
          <option value="flower">Blüten</option>
          <option value="extract">Extrakte</option>
        </select>
      </label>
      <label>
        THC mindestens in Prozent
        <input
          type="number"
          min="0"
          max="100"
          step="0.1"
          value={minThcPercent}
          onChange={(event) => setMinThcPercent(event.target.value)}
        />
      </label>
      {mode === 'pickup' && (
        <p className="field-hint">
          Keine Live-Standortsuche: Entfernungen sind ausschließlich synthetische Testwerte.
        </p>
      )}
      <button type="submit">Suchen</button>
    </form>
  )
}

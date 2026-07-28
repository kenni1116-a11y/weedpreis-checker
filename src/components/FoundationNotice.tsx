type FoundationNoticeProps = {
  title: 'Entdecken' | 'Suche'
}

export function FoundationNotice({ title }: FoundationNoticeProps) {
  return (
    <section className="foundation-notice" aria-labelledby="foundation-title">
      <p className="eyebrow">Wissenskatalog in Vorbereitung</p>
      <h2 id="foundation-title">{title}</h2>
      <p>
        Der nachweisbare Weedypedia-Wissenskatalog wird in der nächsten
        freigegebenen Etappe verbunden. Konto und persönlicher Bestand sind
        bereits getrennt abgesichert.
      </p>
    </section>
  )
}

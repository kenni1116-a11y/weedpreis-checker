type AgeGateProps = {
  onConfirm: () => void
}

export function AgeGate({ onConfirm }: AgeGateProps) {
  return (
    <section className="age-gate" aria-labelledby="age-title">
      <h1 id="age-title">Nur für Erwachsene</h1>
      <p>
        Diese App vergleicht verschreibungspflichtiges Medizinalcannabis. Sie ersetzt keine medizinische Beratung.
      </p>
      <button onClick={onConfirm}>Ich bin mindestens 18 Jahre alt</button>
    </section>
  )
}

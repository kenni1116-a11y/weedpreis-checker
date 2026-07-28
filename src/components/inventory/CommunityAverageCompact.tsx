import type { CatalogSearchMatch } from '../../catalog/catalog-search'
import {
  formatCommunityPercent,
  type PublishedCommunityAverage,
} from '../../community/community-values'

type CommunityAverageCompactProps = {
  match: CatalogSearchMatch
  average: PublishedCommunityAverage | null
}

export function CommunityPeopleIcon() {
  return (
    <svg
      className="community-people-icon"
      aria-hidden="true"
      viewBox="0 0 36 24"
      width="36"
      height="24"
    >
      <circle cx="8" cy="7" r="3" />
      <circle cx="18" cy="5" r="3.5" />
      <circle cx="28" cy="7" r="3" />
      <path d="M2 21c0-5 2.2-8 6-8s6 3 6 8" />
      <path d="M10 21c0-6 3-10 8-10s8 4 8 10" />
      <path d="M22 21c0-5 2.2-8 6-8s6 3 6 8" />
    </svg>
  )
}

function retrievedDate(value: string): string {
  return new Intl.DateTimeFormat('de-DE', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    timeZone: 'UTC',
  }).format(new Date(value))
}

function CommunityHeading() {
  return (
    <>
      <strong className="community-average-symbol">Ø</strong>
      <CommunityPeopleIcon />
      <span className="community-average-label">Community-Mittelwert</span>
    </>
  )
}

export function CommunityAverageCompact({
  match,
  average,
}: CommunityAverageCompactProps) {
  const hasSourcedValues =
    match.sourcedThcLabel !== null
    || match.sourcedCbdLabel !== null
    || match.sourcedValueEvidence.length > 0

  return (
    <div className="inventory-value-layers">
      {hasSourcedValues ? (
        <section className="sourced-values" aria-label="Belegte Produktwerte">
          <span className="value-layer-label">Hersteller-/Labordaten</span>
          <div className="compact-value-row">
            {match.sourcedThcLabel ? (
              <span>THC {match.sourcedThcLabel}</span>
            ) : null}
            {match.sourcedCbdLabel ? (
              <span>CBD {match.sourcedCbdLabel}</span>
            ) : null}
          </div>
          {match.sourcedValueEvidence.length > 0 ? (
            <details className="source-evidence">
              <summary>Belege</summary>
              <ul>
                {match.sourcedValueEvidence.map((evidence, index) => (
                  <li key={`${evidence.sourceName}-${index}`}>
                    <strong>{evidence.sourceName}</strong>
                    {evidence.sourceVersion ? (
                      <span>Version {evidence.sourceVersion}</span>
                    ) : null}
                    <span>Abruf {retrievedDate(evidence.retrievedAt)}</span>
                    <span>{evidence.attribution}</span>
                    {evidence.citationUrl ? (
                      <a
                        href={evidence.citationUrl}
                        target="_blank"
                        rel="noreferrer"
                      >
                        Quelle öffnen
                      </a>
                    ) : null}
                  </li>
                ))}
              </ul>
            </details>
          ) : null}
        </section>
      ) : null}

      <section className="community-average" aria-label="Community-Werte">
        <div className="community-average-heading">
          <CommunityHeading />
        </div>
        {average ? (
          <div className="compact-value-row">
            <span>{formatCommunityPercent(average.thcMean, 'THC')}</span>
            <span>{formatCommunityPercent(average.cbdMean, 'CBD')}</span>
            <span className="contributor-band">{average.contributorBand}</span>
          </div>
        ) : (
          <span className="community-threshold-copy">
            Noch nicht genügend Community-Werte.
          </span>
        )}
      </section>
    </div>
  )
}

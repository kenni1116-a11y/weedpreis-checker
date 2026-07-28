export type CommunityValueSource = 'label' | 'laboratory'
export type ContributorBand = '5+' | '10+' | '25+' | '50+'

export type CommunityContributionDraft = {
  enabled: boolean
  thcPercent: string
  cbdPercent: string
  sourceKind: CommunityValueSource | ''
  declarationAccepted: boolean
}

export type ValidCommunityContribution = {
  cultivarId: string
  thcPercent: number
  cbdPercent: number
  sourceKind: CommunityValueSource
  consentVersion: string
  declarationAccepted: true
  optIn: true
}

export type OwnCommunityContribution = {
  cultivarId: string
  thcPercent: number
  cbdPercent: number
  sourceKind: CommunityValueSource
  consentVersion: string
  updatedAt: string
}

export type PublishedCommunityAverage = {
  cultivarId: string
  thcMean: number
  cbdMean: number
  contributorBand: ContributorBand
  computedAt: string
}

export const unrealisticFlowerValueMessage =
  'Keine Fantasiewerte. Bitte AUSSCHLIESSLICH die Werte des Labels oder eines Laborberichts angeben.'

const exactPercentMessage =
  'Bitte einen exakten Wert von 0 bis 70 eingeben.'
const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
const exactPercentPattern = /^\d+(?:[.,]\d{1,2})?$/
const isoTimestampPattern =
  /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?(?:Z|[+-]\d{2}:\d{2})$/

function isUuid(value: string): boolean {
  return uuidPattern.test(value)
}

function isIsoTimestamp(value: string): boolean {
  return isoTimestampPattern.test(value) && Number.isFinite(Date.parse(value))
}

export function parseFlowerPercent(input: string): number {
  const trimmed = input.trim()
  if (!exactPercentPattern.test(trimmed)) {
    throw new Error(exactPercentMessage)
  }

  const value = Number(trimmed.replace(',', '.'))
  if (!Number.isFinite(value) || value < 0) {
    throw new Error(exactPercentMessage)
  }
  if (value > 70) {
    throw new Error(unrealisticFlowerValueMessage)
  }
  return value
}

export function communityContributionErrors(
  draft: CommunityContributionDraft,
): Partial<Record<keyof CommunityContributionDraft, string>> {
  const errors: Partial<Record<keyof CommunityContributionDraft, string>> = {}

  if (!draft.enabled) {
    errors.enabled = 'Bitte der freiwilligen Übermittlung zustimmen.'
  }

  for (const field of ['thcPercent', 'cbdPercent'] as const) {
    try {
      parseFlowerPercent(draft[field])
    } catch (error) {
      errors[field] =
        error instanceof Error ? error.message : exactPercentMessage
    }
  }

  if (draft.sourceKind !== 'label' && draft.sourceKind !== 'laboratory') {
    errors.sourceKind = 'Bitte Etikett oder Labor/Analyse auswählen.'
  }

  if (!draft.declarationAccepted) {
    errors.declarationAccepted =
      'Bitte bestätigen, dass die Werte nicht geschätzt wurden.'
  }

  return errors
}

export function validateCommunityContribution(input: {
  cultivarId: string
  consentVersion: string
  draft: CommunityContributionDraft
}): ValidCommunityContribution {
  if (!isUuid(input.cultivarId)) {
    throw new Error('Ungültige Sortenzuordnung.')
  }

  const consentVersion = input.consentVersion.trim()
  if (!consentVersion) {
    throw new Error('Die Einwilligungsversion fehlt.')
  }

  const errors = communityContributionErrors(input.draft)
  const firstError = Object.values(errors)[0]
  if (firstError) throw new Error(firstError)

  if (
    input.draft.sourceKind !== 'label' &&
    input.draft.sourceKind !== 'laboratory'
  ) {
    throw new Error('Bitte Etikett oder Labor/Analyse auswählen.')
  }

  return {
    cultivarId: input.cultivarId,
    thcPercent: parseFlowerPercent(input.draft.thcPercent),
    cbdPercent: parseFlowerPercent(input.draft.cbdPercent),
    sourceKind: input.draft.sourceKind,
    consentVersion,
    declarationAccepted: true,
    optIn: true,
  }
}

function finiteNumeric(value: unknown, field: string): number {
  if (
    (typeof value !== 'string' && typeof value !== 'number') ||
    (typeof value === 'string' && value.trim() === '')
  ) {
    throw new Error(`Invalid ${field}`)
  }

  const parsed = Number(value)
  if (!Number.isFinite(parsed)) throw new Error(`Invalid ${field}`)
  return parsed
}

export function mapPublishedCommunityAverage(
  row: unknown,
): PublishedCommunityAverage {
  if (!row || typeof row !== 'object') {
    throw new Error('Invalid community average')
  }

  const candidate = row as Record<string, unknown>
  const cultivarId = candidate.cultivar_id
  const contributorBand = candidate.contributor_band
  const computedAt = candidate.computed_at

  if (typeof cultivarId !== 'string' || !isUuid(cultivarId)) {
    throw new Error('Invalid cultivar_id')
  }
  if (
    contributorBand !== '5+' &&
    contributorBand !== '10+' &&
    contributorBand !== '25+' &&
    contributorBand !== '50+'
  ) {
    throw new Error('Invalid contributor_band')
  }
  if (typeof computedAt !== 'string' || !isIsoTimestamp(computedAt)) {
    throw new Error('Invalid computed_at')
  }

  return {
    cultivarId,
    thcMean: finiteNumeric(candidate.thc_mean, 'thc_mean'),
    cbdMean: finiteNumeric(candidate.cbd_mean, 'cbd_mean'),
    contributorBand,
    computedAt,
  }
}

export function formatCommunityPercent(
  value: number,
  cannabinoid: 'THC' | 'CBD',
): string {
  if (!Number.isFinite(value)) throw new Error('Invalid percentage')
  return `${cannabinoid} ${value.toLocaleString('de-DE', {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  })} %`
}

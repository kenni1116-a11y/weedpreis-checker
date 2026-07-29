import { describe, expect, it } from 'vitest'
import {
  communityContributionErrors,
  formatCommunityPercent,
  mapPublishedCommunityAverage,
  parseFlowerPercent,
  unrealisticFlowerValueMessage,
  validateCommunityContribution,
  type CommunityContributionDraft,
} from './community-values'

const cultivarId = '11111111-1111-4111-8111-111111111111'

function validDraft(
  overrides: Partial<CommunityContributionDraft> = {},
): CommunityContributionDraft {
  return {
    enabled: true,
    thcPercent: '21,30',
    cbdPercent: '0.75',
    sourceKind: 'label',
    declarationAccepted: true,
    ...overrides,
  }
}

describe('parseFlowerPercent', () => {
  it.each([
    ['0', 0],
    ['0,75', 0.75],
    ['21.30', 21.3],
    ['70,00', 70],
  ])('parses the exact flower percentage %s', (input, expected) => {
    expect(parseFlowerPercent(input)).toBe(expected)
  })

  it.each([
    '-0.1',
    '+1',
    '1e1',
    '70.01',
    '71',
    '1.234',
    'unter 1 %',
    '1 %',
    'NaN',
    'Infinity',
    '',
    ' ',
  ])('rejects the non-exact or unrealistic value %j', (input) => {
    expect(() => parseFlowerPercent(input)).toThrow()
  })

  it('uses the approved copy for values above the flower limit', () => {
    expect(() => parseFlowerPercent('70.01')).toThrow(
      unrealisticFlowerValueMessage,
    )
  })
})

describe('validateCommunityContribution', () => {
  it('returns a narrow valid contribution payload', () => {
    expect(
      validateCommunityContribution({
        cultivarId,
        consentVersion: 'weedypedia-community-values-2026-07-28',
        draft: validDraft({ sourceKind: 'laboratory' }),
      }),
    ).toEqual({
      cultivarId,
      thcPercent: 21.3,
      cbdPercent: 0.75,
      sourceKind: 'laboratory',
      consentVersion: 'weedypedia-community-values-2026-07-28',
      declarationAccepted: true,
      optIn: true,
    })
  })

  it.each([
    {
      label: 'invalid cultivar',
      cultivarId: 'not-a-uuid',
      consentVersion: 'consent-v1',
      draft: validDraft(),
    },
    {
      label: 'missing consent version',
      cultivarId,
      consentVersion: ' ',
      draft: validDraft(),
    },
    {
      label: 'disabled contribution',
      cultivarId,
      consentVersion: 'consent-v1',
      draft: validDraft({ enabled: false }),
    },
    {
      label: 'missing source',
      cultivarId,
      consentVersion: 'consent-v1',
      draft: validDraft({ sourceKind: '' }),
    },
    {
      label: 'missing declaration',
      cultivarId,
      consentVersion: 'consent-v1',
      draft: validDraft({ declarationAccepted: false }),
    },
    {
      label: 'missing THC',
      cultivarId,
      consentVersion: 'consent-v1',
      draft: validDraft({ thcPercent: '' }),
    },
    {
      label: 'missing CBD',
      cultivarId,
      consentVersion: 'consent-v1',
      draft: validDraft({ cbdPercent: '' }),
    },
  ])('rejects $label', ({ cultivarId, consentVersion, draft }) => {
    expect(() =>
      validateCommunityContribution({ cultivarId, consentVersion, draft }),
    ).toThrow()
  })

  it('reports field-specific form errors', () => {
    expect(
      communityContributionErrors(
        validDraft({
          enabled: false,
          thcPercent: '71',
          cbdPercent: 'unter 1 %',
          sourceKind: '',
          declarationAccepted: false,
        }),
      ),
    ).toEqual({
      enabled: 'Bitte der freiwilligen Übermittlung zustimmen.',
      thcPercent: unrealisticFlowerValueMessage,
      cbdPercent: 'Bitte einen exakten Wert von 0 bis 70 eingeben.',
      sourceKind: 'Bitte Etikett oder Labor/Analyse auswählen.',
      declarationAccepted:
        'Bitte bestätigen, dass die Werte nicht geschätzt wurden.',
    })
  })
})

describe('published community averages', () => {
  it.each(['5+', '10+', '25+', '50+'] as const)(
    'maps database numerics and accepts the %s band',
    (contributorBand) => {
      expect(
        mapPublishedCommunityAverage({
          cultivar_id: cultivarId,
          thc_mean: '21.30',
          cbd_mean: '0.70',
          contributor_band: contributorBand,
          computed_at: '2026-07-28T12:00:00.000Z',
        }),
      ).toEqual({
        cultivarId,
        thcMean: 21.3,
        cbdMean: 0.7,
        contributorBand,
        computedAt: '2026-07-28T12:00:00.000Z',
      })
    },
  )

  it.each([
    { thc_mean: 'NaN' },
    { cbd_mean: 'Infinity' },
    { contributor_band: '4+' },
    { contributor_band: '100+' },
    { computed_at: 'not-a-date' },
    { computed_at: '2026-07-28' },
    { cultivar_id: 'not-a-uuid' },
  ])('fails closed for malformed aggregate rows %#', (override) => {
    expect(() =>
      mapPublishedCommunityAverage({
        cultivar_id: cultivarId,
        thc_mean: '21.3',
        cbd_mean: '0.7',
        contributor_band: '5+',
        computed_at: '2026-07-28T12:00:00.000Z',
        ...override,
      }),
    ).toThrow()
  })

  it('formats German decimals without adding another average sign', () => {
    expect(formatCommunityPercent(21.3, 'THC')).toBe('THC 21,3 %')
    expect(formatCommunityPercent(0.7, 'CBD')).toBe('CBD 0,7 %')
    expect(formatCommunityPercent(21.3, 'THC')).not.toContain('Ø')
  })
})

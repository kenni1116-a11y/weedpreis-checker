import type {
  CommunityContributionDraft,
  CommunityValueSource,
} from '../../community/community-values'
import { unrealisticFlowerValueMessage } from '../../community/community-values'

type CommunityContributionFieldsProps = {
  draft: CommunityContributionDraft
  errors: Partial<Record<keyof CommunityContributionDraft, string>>
  onChange(draft: CommunityContributionDraft): void
}

function FieldError({ message }: { message?: string }) {
  return message ? <span className="field-error">{message}</span> : null
}

export function CommunityContributionFields({
  draft,
  errors,
  onChange,
}: CommunityContributionFieldsProps) {
  function update<Field extends keyof CommunityContributionDraft>(
    field: Field,
    value: CommunityContributionDraft[Field],
  ) {
    onChange({ ...draft, [field]: value })
  }

  return (
    <fieldset className="community-contribution">
      <legend>Eigene Werte für den Community-Mittelwert</legend>
      <label className="checkbox-field">
        <input
          type="checkbox"
          checked={draft.enabled}
          onChange={(event) => update('enabled', event.target.checked)}
        />
        Community-Werte freiwillig beitragen
      </label>
      <FieldError message={errors.enabled} />

      {draft.enabled ? (
        <>
          <div className="inventory-form-row compact-community-inputs">
            <label>
              THC in Prozent
              <input
                inputMode="decimal"
                autoComplete="off"
                value={draft.thcPercent}
                aria-invalid={Boolean(errors.thcPercent)}
                onChange={(event) => update('thcPercent', event.target.value)}
              />
              <FieldError message={errors.thcPercent} />
            </label>
            <label>
              CBD in Prozent
              <input
                inputMode="decimal"
                autoComplete="off"
                value={draft.cbdPercent}
                aria-invalid={Boolean(errors.cbdPercent)}
                onChange={(event) => update('cbdPercent', event.target.value)}
              />
              <FieldError message={errors.cbdPercent} />
            </label>
          </div>

          <label>
            Quelle der Werte
            <select
              value={draft.sourceKind}
              aria-invalid={Boolean(errors.sourceKind)}
              onChange={(event) => update(
                'sourceKind',
                event.target.value as CommunityValueSource | '',
              )}
            >
              <option value="">Bitte auswählen</option>
              <option value="label">Etikett</option>
              <option value="laboratory">Labor/Analyse</option>
            </select>
            <FieldError message={errors.sourceKind} />
          </label>

          <label className="checkbox-field">
            <input
              type="checkbox"
              checked={draft.declarationAccepted}
              aria-invalid={Boolean(errors.declarationAccepted)}
              onChange={(event) => update(
                'declarationAccepted',
                event.target.checked,
              )}
            />
            Ich bestätige: Die Werte stammen vom Etikett oder aus einem
            Laborbericht und sind nicht geschätzt.
          </label>
          <FieldError message={errors.declarationAccepted} />

          <p className="community-value-warning">
            {unrealisticFlowerValueMessage}
          </p>
        </>
      ) : null}
    </fieldset>
  )
}

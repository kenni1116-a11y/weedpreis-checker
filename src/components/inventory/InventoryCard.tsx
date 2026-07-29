import type { InventoryItem } from '../../inventory/inventory'

type InventoryCardProps = {
  item: InventoryItem
  onEdit(): void
  onDelete(): void
}

const quantityFormatter = new Intl.NumberFormat('de-DE', {
  maximumFractionDigits: 3,
})

function unitLabel(item: InventoryItem): string {
  return item.unit === 'piece' ? 'Stück' : item.unit
}

export function InventoryCard({
  item,
  onEdit,
  onDelete,
}: InventoryCardProps) {
  return (
    <article className="inventory-card">
      <header>
        <div>
          <p className="eyebrow">
            {item.reference?.kind === 'product'
              ? 'Produkt'
              : item.reference
                ? 'Sorte'
                : 'Privater Eintrag'}
          </p>
          <h3>{item.entryName}</h3>
          {item.reference
            && item.reference.canonicalName !== item.entryName ? (
              <small>Kanonisch: {item.reference.canonicalName}</small>
            ) : null}
        </div>
        <strong>
          {quantityFormatter.format(item.quantity)} {unitLabel(item)}
        </strong>
      </header>

      {item.originOneName
        || item.originTwoName
        || item.batch
        || item.expiresOn
        || item.storageLocation
        || item.note ? (
        <dl>
          {item.originOneName ? (
            <>
              <dt>Herkunft 1</dt>
              <dd>{item.originOneName}</dd>
            </>
          ) : null}
          {item.originTwoName ? (
            <>
              <dt>Herkunft 2</dt>
              <dd>{item.originTwoName}</dd>
            </>
          ) : null}
          {item.batch ? (
            <>
              <dt>Charge</dt>
              <dd>{item.batch}</dd>
            </>
          ) : null}
          {item.expiresOn ? (
            <>
              <dt>Ablaufdatum</dt>
              <dd>{item.expiresOn}</dd>
            </>
          ) : null}
          {item.storageLocation ? (
            <>
              <dt>Lagerort</dt>
              <dd>{item.storageLocation}</dd>
            </>
          ) : null}
          {item.note ? (
            <>
              <dt>Notiz</dt>
              <dd>{item.note}</dd>
            </>
          ) : null}
        </dl>
      ) : null}

      <div className="card-actions">
        <button
          type="button"
          aria-label={`${item.entryName} bearbeiten`}
          onClick={onEdit}
        >
          Bearbeiten
        </button>
        <button
          type="button"
          aria-label={`${item.entryName} löschen`}
          onClick={onDelete}
        >
          Löschen
        </button>
      </div>
    </article>
  )
}

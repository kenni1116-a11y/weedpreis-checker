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
            {item.reference.kind === 'cultivar' ? 'Sorte' : 'Produkt'}
          </p>
          <h3>{item.reference.canonicalName}</h3>
        </div>
        <strong>
          {quantityFormatter.format(item.quantity)} {unitLabel(item)}
        </strong>
      </header>

      {item.batch || item.expiresOn || item.storageLocation || item.note ? (
        <dl>
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
          aria-label={`${item.reference.canonicalName} bearbeiten`}
          onClick={onEdit}
        >
          Bearbeiten
        </button>
        <button
          type="button"
          aria-label={`${item.reference.canonicalName} löschen`}
          onClick={onDelete}
        >
          Löschen
        </button>
      </div>
    </article>
  )
}

import {
  useEffect,
  useId,
  useState,
  type KeyboardEvent,
} from 'react'
import type { CatalogRepository } from '../../catalog/catalog-repository'
import type { CatalogSearchMatch } from '../../catalog/catalog-search'

type CatalogComboboxProps = {
  value: string
  selectedMatch: CatalogSearchMatch | null
  repository: CatalogRepository
  onChange(
    value: string,
    selectedMatch: CatalogSearchMatch | null,
  ): void
}

function visibleLength(value: string): number {
  return Array.from(value.trim()).length
}

function reasonLabel(match: CatalogSearchMatch): string {
  if (match.matchReason === 'alias') return 'Alias'
  if (match.matchReason === 'product') return 'Produkt'
  return 'Kanonischer Name'
}

export function CatalogCombobox({
  value,
  selectedMatch,
  repository,
  onChange,
}: CatalogComboboxProps) {
  const listboxId = useId()
  const [results, setResults] = useState<CatalogSearchMatch[]>([])
  const [activeIndex, setActiveIndex] = useState(-1)
  const [open, setOpen] = useState(false)
  const [state, setState] =
    useState<'idle' | 'loading' | 'empty' | 'failed'>('idle')

  useEffect(() => {
    if (selectedMatch || visibleLength(value) < 2) {
      setResults([])
      setActiveIndex(-1)
      setOpen(false)
      setState('idle')
      return
    }

    const controller = new AbortController()
    const timeout = window.setTimeout(() => {
      setState('loading')
      void repository.search(value, controller.signal)
        .then((matches) => {
          if (controller.signal.aborted) return
          setResults(matches)
          setActiveIndex(-1)
          setOpen(matches.length > 0)
          setState(matches.length > 0 ? 'idle' : 'empty')
        })
        .catch((cause: unknown) => {
          if (
            controller.signal.aborted
            || (cause instanceof DOMException && cause.name === 'AbortError')
          ) return
          setResults([])
          setOpen(false)
          setState('failed')
        })
    }, 200)

    return () => {
      window.clearTimeout(timeout)
      controller.abort()
    }
  }, [repository, selectedMatch, value])

  function select(match: CatalogSearchMatch) {
    setResults([])
    setActiveIndex(-1)
    setOpen(false)
    setState('idle')
    onChange(match.matchedName, match)
  }

  function keyDown(event: KeyboardEvent<HTMLInputElement>) {
    if (event.key === 'Escape') {
      setOpen(false)
      setActiveIndex(-1)
      return
    }
    if (!open || results.length === 0) return

    if (event.key === 'ArrowDown') {
      event.preventDefault()
      setActiveIndex((current) => (
        current >= results.length - 1 ? 0 : current + 1
      ))
      return
    }
    if (event.key === 'ArrowUp') {
      event.preventDefault()
      setActiveIndex((current) => (
        current <= 0 ? results.length - 1 : current - 1
      ))
      return
    }
    if (event.key === 'Enter' && activeIndex >= 0) {
      event.preventDefault()
      const match = results[activeIndex]
      if (match) select(match)
    }
  }

  return (
    <div className="catalog-combobox">
      <label htmlFor={`${listboxId}-input`}>Sorte oder Produkt</label>
      <input
        id={`${listboxId}-input`}
        role="combobox"
        aria-autocomplete="list"
        aria-expanded={open}
        aria-controls={listboxId}
        aria-activedescendant={
          activeIndex >= 0 ? `${listboxId}-option-${activeIndex}` : undefined
        }
        autoComplete="off"
        maxLength={160}
        required
        value={value}
        onChange={(event) => onChange(event.target.value, null)}
        onKeyDown={keyDown}
      />

      {state === 'loading' ? (
        <p role="status" className="combobox-status">Suche …</p>
      ) : null}
      {state === 'empty' ? (
        <p role="status" className="combobox-status">
          Kein Katalogtreffer. Der Name kann privat gespeichert werden.
        </p>
      ) : null}
      {state === 'failed' ? (
        <p role="alert" className="field-error">
          Die Bestandssuche ist derzeit nicht verfügbar.
        </p>
      ) : null}

      {open ? (
        <ul id={listboxId} role="listbox" className="combobox-results">
          {results.map((match, index) => (
            <li
              id={`${listboxId}-option-${index}`}
              key={match.id}
              role="option"
              aria-selected={activeIndex === index}
              className={activeIndex === index ? 'is-active' : undefined}
              onMouseDown={(event) => event.preventDefault()}
              onClick={() => select(match)}
            >
              <strong>{match.matchedName}</strong>
              <span>{reasonLabel(match)}</span>
              {match.canonicalName !== match.matchedName ? (
                <small>{match.canonicalName}</small>
              ) : null}
            </li>
          ))}
        </ul>
      ) : null}

      {selectedMatch
        && selectedMatch.canonicalName !== value ? (
          <p className="catalog-suggestion">
            Kanonischer Vorschlag: {selectedMatch.canonicalName}
          </p>
        ) : null}
    </div>
  )
}

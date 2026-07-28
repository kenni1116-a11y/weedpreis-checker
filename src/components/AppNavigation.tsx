export type AppTab = 'discover' | 'search' | 'inventory' | 'profile'

type AppNavigationProps = {
  active: AppTab
  onSelect: (tab: AppTab) => void
}

const tabs: ReadonlyArray<readonly [AppTab, string]> = [
  ['discover', 'Entdecken'],
  ['search', 'Suche'],
  ['inventory', 'Bestand'],
  ['profile', 'Profil'],
]

export function AppNavigation({ active, onSelect }: AppNavigationProps) {
  return (
    <nav className="app-navigation" aria-label="Hauptnavigation">
      {tabs.map(([tab, label]) => (
        <button
          key={tab}
          type="button"
          aria-current={active === tab ? 'page' : undefined}
          aria-pressed={active === tab}
          onClick={() => onSelect(tab)}
        >
          {label}
        </button>
      ))}
    </nav>
  )
}

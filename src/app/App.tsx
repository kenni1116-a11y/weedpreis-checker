import { createClient } from '@supabase/supabase-js'
import { useMemo, useState } from 'react'
import { AuthProvider } from '../auth/AuthProvider'
import type { AuthService } from '../auth/auth-service'
import {
  createSupabaseAuthService,
  type SupabaseClientPort,
} from '../auth/supabase-auth-service'
import { AccountSettings } from '../components/auth/AccountSettings'
import { AuthGate } from '../components/auth/AuthGate'
import { AppNavigation, type AppTab } from '../components/AppNavigation'
import { FoundationNotice } from '../components/FoundationNotice'
import { InventoryView } from '../components/inventory/InventoryView'
import {
  readRuntimeConfig,
  type RuntimeConfig,
} from '../config/runtime-config'
import type { InventoryRepository } from '../inventory/inventory-repository'
import {
  createSupabaseInventoryRepository,
  type SupabaseInventoryClientPort,
} from '../inventory/supabase-inventory-repository'

type AppProps = {
  authService?: AuthService
  inventoryRepository?: InventoryRepository
  config?: RuntimeConfig
}

type AppDependencies = {
  authService: AuthService
  inventoryRepository: InventoryRepository
  config: RuntimeConfig
}

function createBrowserDependencies(config: RuntimeConfig): AppDependencies {
  const client = createClient(
    config.supabaseUrl,
    config.supabasePublishableKey,
    {
      db: { schema: 'api' },
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
      },
    },
  )

  return {
    config,
    authService: createSupabaseAuthService({
      client: client as unknown as SupabaseClientPort,
      config,
      createProofClient: () => createClient(
        config.supabaseUrl,
        config.supabasePublishableKey,
        {
          db: { schema: 'api' },
          auth: {
            persistSession: false,
            autoRefreshToken: false,
            detectSessionInUrl: false,
          },
        },
      ) as unknown as SupabaseClientPort,
    }),
    inventoryRepository: createSupabaseInventoryRepository({
      client: client as unknown as SupabaseInventoryClientPort,
    }),
  }
}

function resolveDependencies({
  authService,
  inventoryRepository,
  config,
}: AppProps): AppDependencies {
  const activeConfig = config ?? readRuntimeConfig(import.meta.env)
  if (authService && inventoryRepository) {
    return { authService, inventoryRepository, config: activeConfig }
  }
  if (authService || inventoryRepository) {
    throw new Error(
      'Auth-Service und Bestands-Repository müssen gemeinsam gesetzt werden.',
    )
  }
  return createBrowserDependencies(activeConfig)
}

function WeedypediaShell({
  inventoryRepository,
}: {
  inventoryRepository: InventoryRepository
}) {
  const [tab, setTab] = useState<AppTab>('discover')

  return (
    <>
      <header className="app-header">
        <p className="eyebrow">Nachvollziehbares Sortenwissen</p>
        <h1>Weedypedia</h1>
        <p>Sorten, Herkunft und Produkte nachvollziehbar verbunden</p>
      </header>

      <AppNavigation active={tab} onSelect={setTab} />

      <div className="app-content">
        {tab === 'discover' ? (
          <FoundationNotice title="Entdecken" />
        ) : null}
        {tab === 'search' ? (
          <FoundationNotice title="Suche" />
        ) : null}
        {tab === 'inventory' ? (
          <InventoryView repository={inventoryRepository} />
        ) : null}
        {tab === 'profile' ? <AccountSettings /> : null}
      </div>
    </>
  )
}

export function App(props: AppProps = {}) {
  const dependencies = useMemo(
    () => resolveDependencies(props),
    [
      props.authService,
      props.config,
      props.inventoryRepository,
    ],
  )

  return (
    <AuthProvider service={dependencies.authService}>
      <main className="app-shell">
        <AuthGate
          privacyVersion={dependencies.config.privacyVersion}
          termsVersion={dependencies.config.termsVersion}
        >
          <WeedypediaShell
            inventoryRepository={dependencies.inventoryRepository}
          />
        </AuthGate>
      </main>
    </AuthProvider>
  )
}

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
import type { CatalogRepository } from '../catalog/catalog-repository'
import {
  createSupabaseCatalogRepository,
  type SupabaseCatalogClientPort,
} from '../catalog/supabase-catalog-repository'
import type { CommunityRepository } from '../community/community-repository'
import {
  createSupabaseCommunityRepository,
  type SupabaseCommunityClientPort,
} from '../community/supabase-community-repository'
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
  catalogRepository?: CatalogRepository
  communityRepository?: CommunityRepository
  inventoryRepository?: InventoryRepository
  config?: RuntimeConfig
}

type AppDependencies = {
  authService: AuthService
  catalogRepository: CatalogRepository
  communityRepository: CommunityRepository
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
    catalogRepository: createSupabaseCatalogRepository({
      client: client as unknown as SupabaseCatalogClientPort,
    }),
    communityRepository: createSupabaseCommunityRepository({
      client: client as unknown as SupabaseCommunityClientPort,
    }),
    inventoryRepository: createSupabaseInventoryRepository({
      client: client as unknown as SupabaseInventoryClientPort,
    }),
  }
}

function resolveDependencies({
  authService,
  catalogRepository,
  communityRepository,
  inventoryRepository,
  config,
}: AppProps): AppDependencies {
  const activeConfig = config ?? readRuntimeConfig(import.meta.env)
  if (
    authService
    && catalogRepository
    && communityRepository
    && inventoryRepository
  ) {
    return {
      authService,
      catalogRepository,
      communityRepository,
      inventoryRepository,
      config: activeConfig,
    }
  }
  if (
    authService
    || catalogRepository
    || communityRepository
    || inventoryRepository
  ) {
    throw new Error(
      'Auth-Service, Bestands-, Katalog- und Community-Repository müssen gemeinsam gesetzt werden.',
    )
  }
  return createBrowserDependencies(activeConfig)
}

function WeedypediaShell({
  catalogRepository,
  communityRepository,
  communityConsentVersion,
  inventoryRepository,
}: {
  catalogRepository: CatalogRepository
  communityRepository: CommunityRepository
  communityConsentVersion: string
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
          <InventoryView
            repository={inventoryRepository}
            catalogRepository={catalogRepository}
            communityRepository={communityRepository}
            communityConsentVersion={communityConsentVersion}
          />
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
      props.catalogRepository,
      props.communityRepository,
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
            catalogRepository={dependencies.catalogRepository}
            communityRepository={dependencies.communityRepository}
            communityConsentVersion={
              dependencies.config.communityValuesConsentVersion
            }
            inventoryRepository={dependencies.inventoryRepository}
          />
        </AuthGate>
      </main>
    </AuthProvider>
  )
}

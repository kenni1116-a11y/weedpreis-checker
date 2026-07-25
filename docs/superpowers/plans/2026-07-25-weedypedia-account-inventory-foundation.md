# Weedypedia Account and Inventory Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the device-only age gate with a verified email/password Weedypedia account, a private pseudonymous profile, optional TOTP protection, and an account-scoped personal inventory that works reliably on iPhone.

**Architecture:** Supabase Auth owns email verification, password hashing, sessions, recovery links, secure email changes, and TOTP. The public profile stores only a unique pseudonymous username; the email remains in the protected Auth system and is never copied into inventory, analytics, or public data. Postgres RLS isolates profiles and inventory and conditionally enforces AAL2 after TOTP enrollment, an Auth trigger writes immutable age/consent receipts, and one freshly authenticated Edge Function performs complete account deletion.

**Tech Stack:** Node.js 24, pnpm 11.9.0, React 19.2.8, TypeScript 7.0.2, Vite 8.1.5, Vitest 4.1.10, Playwright 1.61.1, Supabase CLI 2.109.1, `@supabase/supabase-js` 2.110.8, `@supabase/server` 1.4.1, Supabase Postgres/Auth/Edge Functions/Mailpit, Deno 2.8.1

## Global Constraints

- Implement `docs/superpowers/specs/2026-07-25-weedypedia-design.md`; a product-scope change requires updating that design before code changes.
- Registration requires only pseudonymous username, verified email, password, 18+ confirmation, and acceptance of the active privacy and terms versions.
- Never request or store real name, postal address, phone number, birthdate, diagnosis, prescription, therapy, dosage, payment, or consumption history.
- Email is used only for authentication, verification, recovery, secure email change, and security notices.
- Email is never public and is never copied into `api.profiles`, inventory rows, URLs, logs, analytics, exports intended for public sharing, or knowledge records.
- Passwords are handled only by Supabase Auth and are never stored, logged, or hashed by PWA code.
- Confirm Email and Secure Email Change remain enabled. Email changes require current-password reauthentication and confirmation at both old and new addresses.
- Password recovery uses Supabase's time-limited recovery flow and returns the same UI response whether an email exists or not.
- TOTP is optional for users and mandatory for administrators. Do not use SMS as the second factor.
- Personal inventory is isolated from the public knowledge graph and never affects ranking, recommendations, advertising, or analytics.
- An inventory entry requires a catalog reference, positive quantity, and unit; batch, expiry, storage location, and note are optional.
- Anonymous users cannot read profiles, consent receipts, catalog references, or inventory.
- Authenticated users can read only their own profile and can change only their own inventory; consent receipts are append-only system records.
- After a user verifies TOTP, restrictive database policies require AAL2 for profile, consent, and inventory access; an AAL1 token alone is insufficient.
- Preserve the visible iPhone status bar, dark background, reduced-motion support, keyboard access, and 44-pixel touch targets.
- Do not restore price comparison, ordering, prescription, payment, therapy, effect ranking, or consumption features.
- Production registration remains disabled until legal copy, data-protection review, SMTP, redirect URLs, rate limits, RLS, account deletion, and the security acceptance suite are approved.
- A request containing only `Prüfen` or `Überprüfen` authorizes read-only verification, not edits.

---

## Product Roadmap

This is the first independently testable implementation stage:

1. **This plan:** verified account, consent, optional TOTP, private inventory, and Weedypedia shell
2. Knowledge graph, source register, immutable source versions, and evidence claims
3. Search, category overviews, and gesture-driven cultivar profile
4. Products, batches, transparent averages, and left-to-right timeline
5. Approved connectors, daily/on-demand refresh, review queue, and monitoring

Each later stage receives a separate plan after the preceding stage passes review.

## Target File Structure

### Tooling and configuration

- `package.json`: pinned Supabase packages and platform scripts.
- `pnpm-lock.yaml`: exact dependency graph.
- `.env.example`: browser-safe variables only.
- `.gitignore`: local Supabase secrets and generated files.
- `supabase/config.toml`: local email confirmation, secure email change, password, redirect, and function policy.
- `supabase/deno.json`: pinned function imports and Deno tests.
- `supabase/seed.sql`: synthetic catalog references.
- `src/config/runtime-config.ts`: strict public runtime configuration.
- `src/config/runtime-config.test.ts`: missing and malformed configuration tests.

### Database and account deletion

- `supabase/migrations/*_weedypedia_account_inventory.sql`: profile, legal version, consent, catalog-reference, inventory, trigger, RLS, grants, and indexes.
- `supabase/tests/database/01_account_inventory_schema.test.sql`: constraints, trigger, and lifecycle tests.
- `supabase/tests/database/02_account_inventory_access.test.sql`: anonymous and cross-user negative tests.
- `supabase/functions/account-delete/index.ts`: authenticated full-account deletion.
- `supabase/functions/tests/account-delete.test.ts`: bearer, deletion, and retry behavior.

### PWA authentication

- `src/auth/auth-service.ts`: exact browser-facing Auth interface.
- `src/auth/supabase-auth-service.ts`: Supabase Auth adapter.
- `src/auth/in-memory-auth-service.ts`: deterministic component-test adapter only.
- `src/auth/AuthProvider.tsx`: session/profile state.
- `src/auth/useAuth.ts`: guarded Auth context.
- `src/components/auth/AuthGate.tsx`: login/register/recovery/callback routing.
- `src/components/auth/RegisterForm.tsx`: username, email, password, adult, and consent.
- `src/components/auth/LoginForm.tsx`: email/password login.
- `src/components/auth/EmailVerificationNotice.tsx`: non-enumerating confirmation state.
- `src/components/auth/RecoveryForm.tsx`: recovery-email request.
- `src/components/auth/UpdatePasswordForm.tsx`: password-recovery callback.
- `src/components/auth/MfaChallenge.tsx`: TOTP challenge when an enrolled factor requires AAL2.
- `src/components/auth/AccountSettings.tsx`: username, secure email change, TOTP enrollment, export, logout, and deletion.
- `src/components/auth/*.test.tsx`: account-flow and accessibility tests.

### Personal inventory

- `src/inventory/inventory.ts`: reference, item, draft, and validation types.
- `src/inventory/inventory-repository.ts`: list/create/update/delete interface.
- `src/inventory/supabase-inventory-repository.ts`: authenticated RLS implementation.
- `src/inventory/in-memory-inventory-repository.ts`: deterministic test implementation.
- `src/inventory/*.test.ts`: validation and mapping.
- `src/components/inventory/InventoryView.tsx`: loading, empty, error, and list states.
- `src/components/inventory/InventoryForm.tsx`: add/edit form.
- `src/components/inventory/InventoryCard.tsx`: private item presentation.
- `src/components/inventory/*.test.tsx`: UI tests.

### Shell, verification, and operations

- `src/app/App.tsx`: mandatory account gate and Weedypedia shell.
- `src/app/App.test.tsx`: signed-out/signed-in behavior.
- `src/components/AppNavigation.tsx`: Entdecken, Suche, Bestand, Profil.
- `src/components/AppNavigation.test.tsx`: four destinations.
- `src/components/FoundationNotice.tsx`: explicit boundary until the knowledge stage.
- `src/components/AgeGate.tsx`: removed after registration owns age confirmation.
- `src/components/AgeGate.test.tsx`: removed with the local gate.
- `src/styles/app.css`: account and inventory iPhone styling.
- `vite.config.ts`: Weedypedia PWA metadata.
- `tests/e2e/weedypedia-account-inventory.spec.ts`: verified email, TOTP, isolation, recovery, export, deletion, and iPhone journey.
- `.github/workflows/verify.yml`: database, function, unit, build, and browser gates.
- `.github/workflows/pages.yml`: fail-closed hosted Auth configuration with registration disabled until approval.
- `playwright.config.ts`: local Supabase and Mailpit environment for the iPhone journey.
- `docs/operations/weedypedia-account-activation.md`: SMTP, privacy, activation, rollback, and incident runbook.
- `README.md`: Weedypedia purpose and local workflow.

---

### Task 1: Pin Supabase and Validate Browser-Safe Configuration

**Files:**
- Modify: `package.json`
- Modify: `pnpm-lock.yaml`
- Modify: `.gitignore`
- Create: `.env.example`
- Create: `supabase/config.toml`
- Create: `supabase/deno.json`
- Create: `src/config/runtime-config.ts`
- Create: `src/config/runtime-config.test.ts`
- Modify: `README.md`

**Interfaces:**
- Scripts: `supabase:start`, `supabase:stop`, `test:functions`, `test:db`, `check:platform`, `types:db`.
- Browser variables: `VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY`, `VITE_PRIVACY_VERSION`, `VITE_TERMS_VERSION`, `VITE_AUTH_REDIRECT_URL`.
- Server secret: `SUPABASE_SECRET_KEY` for `account-delete`.
- Produces `RuntimeConfig` and `readRuntimeConfig(env)`.

- [ ] **Step 1: Verify toolchain prerequisites**

Run:

```sh
node --version
pnpm --version
deno --version
docker version
```

Expected: Node 24.x, pnpm 11.9.0, Deno 2.8.1, and a reachable Docker engine.
If the shell has no plain `node`, load the bundled workspace dependencies and
use their Node binary. Stop before repository changes if a prerequisite cannot
be aligned.

- [ ] **Step 2: Write the failing runtime tests**

```ts
import { describe, expect, it } from 'vitest'
import { readRuntimeConfig } from './runtime-config'

const valid = {
  VITE_SUPABASE_URL: 'https://project.supabase.co',
  VITE_SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_test',
  VITE_PRIVACY_VERSION: 'weedypedia-privacy-2026-07-25',
  VITE_TERMS_VERSION: 'weedypedia-terms-2026-07-25',
  VITE_AUTH_REDIRECT_URL: 'https://example.invalid/auth/callback',
}

describe('readRuntimeConfig', () => {
  it('accepts complete public configuration', () => {
    expect(readRuntimeConfig(valid)).toEqual({
      supabaseUrl: valid.VITE_SUPABASE_URL,
      supabasePublishableKey: valid.VITE_SUPABASE_PUBLISHABLE_KEY,
      privacyVersion: valid.VITE_PRIVACY_VERSION,
      termsVersion: valid.VITE_TERMS_VERSION,
      authRedirectUrl: valid.VITE_AUTH_REDIRECT_URL,
    })
  })

  it.each(Object.keys(valid))('rejects missing %s', (key) => {
    expect(() => readRuntimeConfig({ ...valid, [key]: '' })).toThrow(key)
  })
})
```

- [ ] **Step 3: Run the test and verify failure**

Run:

```sh
pnpm test -- src/config/runtime-config.test.ts
```

Expected: FAIL because the configuration module does not exist.

- [ ] **Step 4: Add the pinned dependencies and scripts**

Run:

```sh
pnpm add @supabase/supabase-js@2.110.8
pnpm add -D supabase@2.109.1
```

Add:

```json
{
  "scripts": {
    "supabase:start": "supabase start",
    "supabase:stop": "supabase stop",
    "test:functions": "deno task --config supabase/deno.json test",
    "test:db": "supabase test db",
    "check:platform": "pnpm test:functions && pnpm test:db",
    "types:db": "supabase gen types typescript --local --schema api > src/data/database.types.ts"
  }
}
```

Keep the existing `dev`, `build`, `test`, `test:e2e`, and `check` scripts.

- [ ] **Step 5: Implement strict runtime parsing**

```ts
export type RuntimeConfig = {
  supabaseUrl: string
  supabasePublishableKey: string
  privacyVersion: string
  termsVersion: string
  authRedirectUrl: string
}

type RuntimeEnv = Record<string, string | undefined>

function required(env: RuntimeEnv, key: string): string {
  const value = env[key]?.trim()
  if (!value) throw new Error(`Missing ${key}`)
  return value
}

export function readRuntimeConfig(env: RuntimeEnv): RuntimeConfig {
  const supabaseUrl = required(env, 'VITE_SUPABASE_URL')
  const authRedirectUrl = required(env, 'VITE_AUTH_REDIRECT_URL')
  if (!URL.canParse(supabaseUrl)) throw new Error('Invalid VITE_SUPABASE_URL')
  if (!URL.canParse(authRedirectUrl)) throw new Error('Invalid VITE_AUTH_REDIRECT_URL')
  return {
    supabaseUrl,
    supabasePublishableKey: required(env, 'VITE_SUPABASE_PUBLISHABLE_KEY'),
    privacyVersion: required(env, 'VITE_PRIVACY_VERSION'),
    termsVersion: required(env, 'VITE_TERMS_VERSION'),
    authRedirectUrl,
  }
}
```

- [ ] **Step 6: Initialize and harden local Auth**

Run:

```sh
pnpm exec supabase init
```

Configure:

- Data API exposes `api` and required built-in schemas, never `private` or `catalog`.
- email/password provider enabled;
- Confirm Email enabled;
- Secure Email Change enabled;
- minimum password length 12;
- leaked-password protection enabled in hosted staging/production when the selected plan supports it;
- local Site URL `http://127.0.0.1:4173`;
- local redirect `http://127.0.0.1:4173/auth/callback`;
- only `account-delete` exists as a custom function and requires JWT verification;
- local Mailpit captures verification, recovery, and email-change messages.

Create:

```json
{
  "imports": {
    "@supabase/supabase-js": "npm:@supabase/supabase-js@2.110.8",
    "@supabase/server": "npm:@supabase/server@1.4.1",
    "@std/assert": "jsr:@std/assert@1.0.18"
  },
  "tasks": {
    "test": "deno test functions/tests --allow-env"
  }
}
```

- [ ] **Step 7: Define public environment and secret boundaries**

Create `.env.example`:

```dotenv
VITE_SUPABASE_URL=
VITE_SUPABASE_PUBLISHABLE_KEY=
VITE_PRIVACY_VERSION=weedypedia-privacy-2026-07-25
VITE_TERMS_VERSION=weedypedia-terms-2026-07-25
VITE_AUTH_REDIRECT_URL=http://127.0.0.1:4173/auth/callback
```

Ignore `.env`, `.env.local`, `supabase/.temp/`, function environment files, and generated database types. Document `SUPABASE_SECRET_KEY` only as a server-side secret name without a value.

- [ ] **Step 8: Verify and commit**

Run:

```sh
pnpm test -- src/config/runtime-config.test.ts
pnpm build
git diff --check
```

```sh
git add package.json pnpm-lock.yaml .gitignore .env.example supabase/config.toml supabase/deno.json src/config/runtime-config.ts src/config/runtime-config.test.ts README.md
git commit -m "chore: initialize verified Weedypedia auth"
```

---

### Task 2: Create Profiles, Immutable Consent, Catalog References, and Inventory RLS

**Files:**
- Create via CLI: `supabase/migrations/*_weedypedia_account_inventory.sql`
- Create: `supabase/tests/database/01_account_inventory_schema.test.sql`
- Create: `supabase/tests/database/02_account_inventory_access.test.sql`
- Modify: `supabase/seed.sql`

**Interfaces:**
- Private table: `private.legal_versions`.
- Catalog table: `catalog.entities`.
- API tables: `api.profiles`, `api.consent_receipts`, `api.catalog_references`, `api.inventory_items`.
- Auth trigger: `private.handle_new_auth_user()`.

- [ ] **Step 1: Create the migration filename**

Run:

```sh
pnpm exec supabase migration new weedypedia_account_inventory
```

Use the CLI-generated filename unchanged.

- [ ] **Step 2: Write failing pgTAP schema and trigger tests**

The schema test must assert:

```sql
select plan(22);
select has_schema('private');
select has_schema('catalog');
select has_schema('api');
select has_table('private', 'legal_versions');
select has_table('catalog', 'entities');
select has_table('api', 'profiles');
select has_table('api', 'consent_receipts');
select has_table('api', 'catalog_references');
select has_table('api', 'inventory_items');
select has_index('private', 'legal_versions', 'legal_versions_one_active_per_kind');
select col_is_pk('api', 'profiles', 'user_id');
select col_is_pk('api', 'inventory_items', 'id');
select has_index('api', 'profiles', 'profiles_username_normalized_key');
select has_index('api', 'inventory_items', 'inventory_items_user_id_idx');
select throws_ok(
  $$insert into api.inventory_items(user_id, entity_id, quantity, unit)
    values (gen_random_uuid(), gen_random_uuid(), 0, 'g')$$,
  '23514'
);
select throws_ok(
  $$insert into api.inventory_items(user_id, entity_id, quantity, unit, note)
    values (gen_random_uuid(), gen_random_uuid(), 1, 'g', repeat('x', 1001))$$,
  '23514'
);
select finish();
```

Add trigger cases:

- a new Auth user with valid metadata creates one profile and three receipts,
  while RLS keeps them inaccessible before email confirmation;
- metadata email is not copied to any API table;
- `adult_confirmed = false` rejects creation;
- inactive privacy or terms version, or a missing active adult version, rejects
  creation;
- invalid or duplicate normalized username rejects creation;
- updating Auth user metadata later cannot rewrite profile or consent history.

- [ ] **Step 3: Write failing access tests**

Create two confirmed Auth users and prove:

- `anon` cannot select any API table;
- user A can read only user A's profile, receipts, and inventory;
- user B cannot select, update, or delete user A's inventory;
- authenticated users can read published catalog references;
- users cannot insert, update, or delete consent receipts;
- users cannot update any profile column through the browser role;
- after TOTP enrollment, an AAL1 token cannot read profile, receipts, or
  inventory, while an AAL2 token can;
- browser roles cannot resolve `private` or `catalog`;
- RLS is enabled on every API table.

- [ ] **Step 4: Run tests and verify failure**

Run:

```sh
pnpm exec supabase start
pnpm test:db
```

Expected: FAIL because the schemas do not exist.

- [ ] **Step 5: Implement legal versions, profile, and consent trigger**

Use:

```sql
create schema if not exists private;
create schema if not exists catalog;
create schema if not exists api;

create table private.legal_versions (
  kind text not null check (kind in ('privacy', 'terms', 'adult')),
  version text not null,
  active boolean not null default false,
  effective_at timestamptz not null,
  primary key (kind, version)
);
create unique index legal_versions_one_active_per_kind
  on private.legal_versions(kind)
  where active;

create table api.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  username text not null check (char_length(username) between 3 and 32),
  username_normalized text not null unique
    check (username_normalized ~ '^[a-z0-9][a-z0-9._-]{2,31}$'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table api.consent_receipts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('privacy', 'terms', 'adult')),
  version text not null check (char_length(version) between 1 and 80),
  accepted_at timestamptz not null,
  unique (user_id, kind, version)
);
```

`private.handle_new_auth_user()` is `SECURITY DEFINER SET search_path = ''`.
It reads only these signup metadata keys:

```text
registration_username
adult_confirmed
privacy_version
terms_version
```

It lowercases and trims the username, validates the ASCII policy, requires
`adult_confirmed = true`, verifies both active legal versions, inserts the
profile, and writes privacy, terms, and adult receipts with the Auth user's
creation timestamp. The adult receipt uses the single active server-side
`adult` wording version rather than trusting a client-supplied value. It never
reads or stores the Auth email. Attach it as an `AFTER INSERT` trigger on
`auth.users`.

- [ ] **Step 6: Implement catalog and inventory**

```sql
create table catalog.entities (
  id uuid primary key,
  kind text not null check (kind in ('cultivar', 'product')),
  canonical_name text not null check (char_length(canonical_name) between 1 and 160),
  published boolean not null default false,
  unique (kind, canonical_name)
);

create table api.catalog_references (
  id uuid primary key references catalog.entities(id) on delete cascade,
  kind text not null check (kind in ('cultivar', 'product')),
  canonical_name text not null check (char_length(canonical_name) between 1 and 160)
);

create table api.inventory_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  entity_id uuid not null references api.catalog_references(id) on delete restrict,
  quantity numeric(12,3) not null check (quantity > 0 and quantity <= 100000),
  unit text not null check (unit in ('g', 'ml', 'piece')),
  batch text check (batch is null or char_length(batch) <= 120),
  expires_on date,
  storage_location text check (
    storage_location is null or char_length(storage_location) <= 120
  ),
  note text check (note is null or char_length(note) <= 1000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index inventory_items_user_id_idx on api.inventory_items(user_id);
```

Enable RLS on every API table. Authenticated users receive:

- own-row select on profiles, with no browser update in this stage;
- own-row select on consent receipts, with no browser writes;
- select on all catalog references;
- own-row select, insert, update, and delete on inventory.

Add a restrictive policy to profiles, consent receipts, and inventory: when
`auth.mfa_factors` contains a verified factor for `auth.uid()`, only a JWT with
`auth.jwt()->>'aal' = 'aal2'` may access that row. Catalog references remain
readable at AAL1 because they contain no personal data.

Revoke all defaults first. Only service-role publication may write catalog
references.

- [ ] **Step 7: Seed active legal versions and synthetic references**

```sql
insert into private.legal_versions(kind, version, active, effective_at) values
  ('privacy', 'weedypedia-privacy-2026-07-25', true, '2026-07-25T00:00:00Z'),
  ('terms', 'weedypedia-terms-2026-07-25', true, '2026-07-25T00:00:00Z'),
  ('adult', 'weedypedia-adult-2026-07-25', true, '2026-07-25T00:00:00Z');

insert into catalog.entities(id, kind, canonical_name, published) values
  ('10000000-0000-4000-8000-000000000001', 'cultivar', 'Test-Cultivar – keine Echtdaten', true),
  ('10000000-0000-4000-8000-000000000002', 'product', 'Testprodukt – keine Echtdaten', true);

insert into api.catalog_references(id, kind, canonical_name) values
  ('10000000-0000-4000-8000-000000000001', 'cultivar', 'Test-Cultivar – keine Echtdaten'),
  ('10000000-0000-4000-8000-000000000002', 'product', 'Testprodukt – keine Echtdaten');
```

- [ ] **Step 8: Verify and commit**

Run:

```sh
pnpm exec supabase db reset
pnpm test:db
pnpm exec supabase db lint --level error
git diff --check
```

```sh
git add supabase/migrations supabase/tests/database supabase/seed.sql
git commit -m "feat: add Weedypedia account and inventory boundary"
```

---

### Task 3: Implement Native Supabase Auth, Recovery, Secure Email Change, and TOTP

**Files:**
- Create: `src/auth/auth-service.ts`
- Create: `src/auth/supabase-auth-service.ts`
- Create: `src/auth/in-memory-auth-service.ts`
- Create: `src/auth/AuthProvider.tsx`
- Create: `src/auth/useAuth.ts`
- Create: `src/auth/supabase-auth-service.test.ts`
- Create: `supabase/functions/account-delete/index.ts`
- Create: `supabase/functions/tests/account-delete.test.ts`

**Interfaces:**
- `AuthService.currentState(): Promise<AuthState>`.
- `AuthService.subscribe(listener: (state: AuthState) => void): () => void`.
- `AuthService.register(input: RegistrationInput): Promise<'verification-sent'>`.
- `AuthService.login(input: { email: string; password: string }): Promise<void>`.
- `AuthService.requestPasswordRecovery(email: string): Promise<void>`.
- `AuthService.updateRecoveredPassword(password: string): Promise<void>`.
- `AuthService.changeEmail(input: EmailChangeInput): Promise<'verification-sent'>`.
- `AuthService.enrollTotp(): Promise<TotpEnrollment>`.
- `AuthService.listTotpFactors(): Promise<TotpFactor[]>`.
- `AuthService.verifyTotp(input: TotpVerificationInput): Promise<void>`.
- `AuthService.unenrollTotp(input: UnenrollTotpInput): Promise<void>`.
- `AuthService.logout(): Promise<void>`.
- `AuthService.exportAccount(proof: SensitiveActionProof): Promise<AccountExport>`.
- `AuthService.deleteAccount(input: DeleteAccountInput): Promise<void>`.

- [ ] **Step 1: Define types and write failing adapter tests**

```ts
export type AuthUser = {
  id: string
  username: string
  email: string
  emailVerified: boolean
  aal: 'aal1' | 'aal2'
}

export type AuthState =
  | { status: 'loading' }
  | { status: 'signed-out' }
  | { status: 'verification-required'; email: string }
  | { status: 'mfa-required'; email: string; factors: TotpFactor[] }
  | { status: 'signed-in'; user: AuthUser }
  | { status: 'error'; message: string }

export type RegistrationInput = {
  username: string
  email: string
  password: string
  adultConfirmed: true
  privacyVersion: string
  termsVersion: string
}

export type EmailChangeInput = {
  email: string
  currentPassword: string
}

export type TotpEnrollment = {
  factorId: string
  qrCode: string
  secret: string
}

export type TotpFactor = {
  id: string
  friendlyName: string
  status: 'unverified' | 'verified'
}

export type TotpVerificationInput = {
  factorId: string
  code: string
}

export type UnenrollTotpInput = {
  factorId: string
  currentPassword: string
}

export type SensitiveActionProof = {
  currentPassword: string
  totpCode?: string
}

export type DeleteAccountInput = SensitiveActionProof & {
  usernameConfirmation: string
}

export type AccountExport = {
  exportedAt: string
  account: Pick<AuthUser, 'id' | 'username' | 'email' | 'emailVerified'>
  consents: Array<{
    kind: 'privacy' | 'terms' | 'adult'
    version: string
    acceptedAt: string
  }>
  inventory: Array<{
    id: string
    entityId: string
    canonicalName: string
    quantity: number
    unit: 'g' | 'ml' | 'piece'
    batch: string | null
    expiresOn: string | null
    storageLocation: string | null
    note: string | null
    createdAt: string
    updatedAt: string
  }>
}
```

Map `emailVerified` exactly as `Boolean(session.user.email_confirmed_at)`; never
infer it from the presence of an address.

Mock the Supabase client and prove:

- signup passes email/password and only the four approved metadata fields;
- signup uses the configured callback URL;
- login maps all credential failures to one German message;
- profile loading never copies email into the profile query;
- recovery always resolves to the same visible result;
- recovered password uses the `PASSWORD_RECOVERY` session;
- email change sends current password and preserves Secure Email Change;
- TOTP enrollment never uses phone, and factor listing exposes TOTP only;
- verified-factor removal requires current AAL2 plus fresh password proof;
- sensitive-action proof uses a separate non-persistent Auth client, matches the
  returned user ID to the active user, and never replaces the active session;
- export contains email, profile, receipts, and inventory, but no password,
  token, Auth metadata, or internal database role;
- export and deletion require a fresh password sign-in and, when TOTP is
  enrolled, a fresh TOTP challenge;
- deletion calls only the authenticated function with the fresh proof session
  and then clears the active session.

- [ ] **Step 2: Run tests and verify failure**

Run:

```sh
pnpm test -- src/auth/supabase-auth-service.test.ts
```

Expected: FAIL because the Auth modules do not exist.

- [ ] **Step 3: Implement signup and session mapping**

Signup:

```ts
await supabase.auth.signUp({
  email: input.email.trim(),
  password: input.password,
  options: {
    emailRedirectTo: config.authRedirectUrl,
    data: {
      registration_username: input.username.trim(),
      adult_confirmed: input.adultConfirmed,
      privacy_version: input.privacyVersion,
      terms_version: input.termsVersion,
    },
  },
})
```

Validate username with `^[A-Za-z0-9][A-Za-z0-9._-]{2,31}$`, password length
12–128, email through browser validity plus Supabase, both active consent
versions, and adult confirmation before the request. After Auth state changes,
read `email_confirmed_at`, factor list, and current AAL first. If a verified
factor exists at AAL1, return `mfa-required` without querying any personal API
table. Load the user's `api.profiles` row only after the session satisfies the
required AAL.

- [ ] **Step 4: Implement login, verification, recovery, and email change**

Use:

```ts
supabase.auth.signInWithPassword({ email, password })
supabase.auth.resetPasswordForEmail(email, { redirectTo: config.authRedirectUrl })
supabase.auth.updateUser({ password: newPassword })
supabase.auth.updateUser({ email: newEmail, current_password: currentPassword })
```

Do not expose whether a login or recovery email exists. Keep Supabase Secure
Email Change enabled so both addresses confirm a change. Clear password values
from component state after every completed operation.

- [ ] **Step 5: Implement TOTP AAL2**

Use Supabase MFA:

```ts
supabase.auth.mfa.enroll({ factorType: 'totp', friendlyName: 'Weedypedia' })
supabase.auth.mfa.challenge({ factorId })
supabase.auth.mfa.verify({ factorId, challengeId, code })
supabase.auth.mfa.getAuthenticatorAssuranceLevel()
supabase.auth.mfa.listFactors()
supabase.auth.mfa.unenroll({ factorId })
```

If a verified TOTP factor exists and the current level is AAL1, Auth state is
`mfa-required`; do not render inventory until AAL2 succeeds. Store neither the
TOTP secret nor the verification code outside Supabase's enrollment response
and the active form. Unenrolling a verified factor requires current AAL2 and
fresh password proof.

- [ ] **Step 6: Implement fresh proof for export and deletion**

For export or deletion, create an isolated Supabase client with
`persistSession: false`, `autoRefreshToken: false`, and no shared storage. Sign
in with the current Auth user's email and the supplied password, require the
returned user ID to match the active user, and inspect the factor list. If a
verified TOTP factor exists, challenge and verify it with the supplied fresh
code. Never return the proof token to UI components, persist it, or write it to
logs.

Use this proof-scoped client for export reads. For deletion, send only its
fresh access token to the deletion function. Clear the isolated session and all
password/TOTP fields on success or failure. Before creating proof, require
`usernameConfirmation` to equal the current normalized username exactly.

- [ ] **Step 7: Implement authenticated account deletion**

The function:

1. accepts only `DELETE`;
2. uses `withSupabase({ auth: 'user' })` with JWT verification enabled;
3. requires `jwtClaims.iat` to be no older than five minutes and `amr` to
   contain a recent `password` method;
4. lists factors with
   `supabaseAdmin.auth.admin.mfa.listFactors({ userId: userClaims.id })`;
5. rejects with one generic 403 when a verified factor exists but
   `jwtClaims.aal !== 'aal2'`;
6. calls `supabaseAdmin.auth.admin.deleteUser(userClaims.id)`;
7. relies on foreign-key cascades for profile, receipts, and inventory;
8. returns 204 for a successful or already-completed retry;
9. sets `Cache-Control: no-store`;
10. never logs email, token, claims, profile, inventory, or request body.

The Deno test injects Auth/admin ports and proves missing token, wrong method,
stale proof, missing password AMR, missing AAL2 for a TOTP account, successful
deletion, and idempotent retry behavior.

- [ ] **Step 8: Implement deterministic in-memory Auth for UI tests**

The in-memory implementation exposes configurable states and records exact
calls. It may contain synthetic `.invalid` emails only and must never be chosen
by runtime configuration.

- [ ] **Step 9: Verify and commit**

Run:

```sh
pnpm test -- src/auth
pnpm test:functions
pnpm build
git diff --check
```

```sh
git add src/auth supabase/functions/account-delete supabase/functions/tests/account-delete.test.ts
git commit -m "feat: add verified Weedypedia authentication"
```

---

### Task 4: Build the Accessible Account Gate and Settings

**Files:**
- Create: `src/components/auth/AuthGate.tsx`
- Create: `src/components/auth/RegisterForm.tsx`
- Create: `src/components/auth/LoginForm.tsx`
- Create: `src/components/auth/EmailVerificationNotice.tsx`
- Create: `src/components/auth/RecoveryForm.tsx`
- Create: `src/components/auth/UpdatePasswordForm.tsx`
- Create: `src/components/auth/MfaChallenge.tsx`
- Create: `src/components/auth/AccountSettings.tsx`
- Create: `src/components/auth/AuthGate.test.tsx`
- Create: `src/components/auth/AccountSettings.test.tsx`

**Interfaces:**
- Consumes `AuthService` through `useAuth()`.
- Produces a complete signed-out, callback, AAL2, and account-settings flow.

- [ ] **Step 1: Write failing account-gate tests**

Prove:

- loading has a labelled progress status;
- signed-out starts with email/password login;
- registration has only username, email, password, 18+, privacy, and terms;
- no name, address, phone, birthdate, diagnosis, prescription, or inventory
  field appears during registration;
- registration cannot submit without email, adult, and both consents;
- success says a neutral verification email was sent;
- login and recovery do not reveal whether an email exists;
- a `PASSWORD_RECOVERY` callback renders the new-password form;
- enrolled TOTP at AAL1 blocks the app and renders the six-digit challenge;
- focus moves to the error summary;
- all controls remain keyboard accessible.

- [ ] **Step 2: Run tests and verify failure**

Run:

```sh
pnpm test -- src/components/auth/AuthGate.test.tsx
```

Expected: FAIL because the components do not exist.

- [ ] **Step 3: Implement registration and verification states**

Use `autocomplete="username"`, `autocomplete="email"`, and
`autocomplete="new-password"`. Registration copy states:

```text
Deine E-Mail bleibt privat und dient nur Anmeldung, Verifizierung,
Wiederherstellung und Sicherheitsmeldungen. Öffentlich sichtbar ist nur dein
pseudonymer Benutzername.
```

Disable submit while pending. On success, clear password state and show
`EmailVerificationNotice` without echoing the full address on a shared screen;
mask it as `k***@example.de`.

- [ ] **Step 4: Implement login, recovery, callback, and TOTP challenge**

Use `autocomplete="current-password"` for login. Recovery always shows:

```text
Falls ein passendes Konto existiert, wurde eine Wiederherstellungsnachricht
versendet.
```

The callback route handles email confirmation, password recovery, and secure
email change without putting tokens into app logs. TOTP input is numeric,
six-character, one-time, and cleared after each attempt.

- [ ] **Step 5: Write and satisfy account-settings tests**

Prove:

- email is shown only inside the private account panel;
- changing email requires current password and explains dual confirmation;
- TOTP enrollment shows QR/secret only until verification;
- verified TOTP factors can be listed and removed only at AAL2 with a fresh
  password confirmation;
- export downloads a private JSON file only after fresh password confirmation
  and, when enabled, a fresh TOTP code;
- logout clears the session;
- deletion requires typing the username, current password, a second
  confirmation, and a fresh TOTP code when enabled;
- email and inventory never appear in URLs or telemetry calls.

- [ ] **Step 6: Implement account settings**

Provide:

- pseudonymous username;
- masked current email and verification state;
- secure email-change form;
- TOTP enrollment/removal with reauthentication;
- private JSON export with fresh sensitive-action proof;
- logout;
- destructive deletion with username confirmation and fresh
  sensitive-action proof.

The export filename is `weedypedia-private-export-YYYY-MM-DD.json`. The screen
warns users that the file contains personal data and must be stored securely.

- [ ] **Step 7: Verify and commit**

Run:

```sh
pnpm test -- src/components/auth
pnpm build
git diff --check
```

```sh
git add src/components/auth
git commit -m "feat: add Weedypedia account experience"
```

---

### Task 5: Implement the Private Inventory Domain, Repository, and UI

**Files:**
- Create: `src/inventory/inventory.ts`
- Create: `src/inventory/inventory-repository.ts`
- Create: `src/inventory/supabase-inventory-repository.ts`
- Create: `src/inventory/in-memory-inventory-repository.ts`
- Create: `src/inventory/inventory.test.ts`
- Create: `src/inventory/supabase-inventory-repository.test.ts`
- Create: `src/components/inventory/InventoryView.tsx`
- Create: `src/components/inventory/InventoryForm.tsx`
- Create: `src/components/inventory/InventoryCard.tsx`
- Create: `src/components/inventory/InventoryView.test.tsx`

**Interfaces:**
- Produces `CatalogReference`, `InventoryItem`, `InventoryDraft`, and `InventoryRepository`.
- Repository methods: `references`, `list`, `create`, `update`, `remove`.

- [ ] **Step 1: Write failing validation tests**

```ts
it('accepts only the minimal required fields', () => {
  expect(validateInventoryDraft({
    entityId: '10000000-0000-4000-8000-000000000001',
    quantity: '3.5',
    unit: 'g',
    batch: '',
    expiresOn: '',
    storageLocation: '',
    note: '',
  })).toEqual({
    entityId: '10000000-0000-4000-8000-000000000001',
    quantity: 3.5,
    unit: 'g',
    batch: null,
    expiresOn: null,
    storageLocation: null,
    note: null,
  })
})

it.each(['0', '-1', '100000.001', 'not-a-number'])(
  'rejects invalid quantity %s',
  (quantity) => {
    expect(() => validateInventoryDraft(validDraft({ quantity }))).toThrow('Menge')
  },
)
```

Also test the database text limits and strict ISO date parsing.

- [ ] **Step 2: Define exact domain and repository types**

```ts
export type InventoryUnit = 'g' | 'ml' | 'piece'

export type CatalogReference = {
  id: string
  kind: 'cultivar' | 'product'
  canonicalName: string
}

export type InventoryItem = {
  id: string
  reference: CatalogReference
  quantity: number
  unit: InventoryUnit
  batch: string | null
  expiresOn: string | null
  storageLocation: string | null
  note: string | null
  createdAt: string
  updatedAt: string
}

export type InventoryRepository = {
  references(signal?: AbortSignal): Promise<CatalogReference[]>
  list(signal?: AbortSignal): Promise<InventoryItem[]>
  create(input: ValidInventoryDraft): Promise<InventoryItem>
  update(id: string, input: ValidInventoryDraft): Promise<InventoryItem>
  remove(id: string): Promise<void>
}
```

- [ ] **Step 3: Run the domain tests and verify failure**

Run:

```sh
pnpm test -- src/inventory/inventory.test.ts
```

Expected: FAIL because the inventory module does not exist.

- [ ] **Step 4: Implement validation**

Parse decimal quantity, require `0 < quantity <= 100000`, allow only `g`, `ml`,
or `piece`, trim optional text, and enforce database lengths before network
calls. Return both a field-error map for the form and a validated repository
value.

- [ ] **Step 5: Write failing repository tests**

Mock Supabase and prove:

- references read only `api.catalog_references`;
- list joins the referenced canonical name;
- create omits `user_id` so the database uses `auth.uid()`;
- update/delete filter only by item ID and rely on RLS;
- permission errors become `INVENTORY_FORBIDDEN`;
- aborted reads cannot update UI state;
- no query selects Auth email or consent metadata.

- [ ] **Step 6: Implement both repository adapters**

The Supabase adapter maps snake_case rows to domain types and never accepts a
user ID. The in-memory adapter clones values, accepts injected ID/time
generators, supports abort signals, and is used only by component tests.

- [ ] **Step 7: Write failing inventory UI tests**

Prove:

- empty state explains that no stock exists;
- add requires reference, quantity, and unit only;
- batch, expiry, storage location, and note are optional;
- add/edit updates the list;
- delete requires confirmation;
- failure preserves the previous list and announces the error;
- no price, dosage, consumption, diagnosis, prescription, email, or effect
  field appears.

- [ ] **Step 8: Implement inventory components**

Use labelled controls, native date input, unit select, inline errors, and an
error summary. Cancel stale loads. Never place item values in URLs, logs, or
analytics.

- [ ] **Step 9: Verify and commit**

Run:

```sh
pnpm test -- src/inventory src/components/inventory
pnpm build
git diff --check
```

```sh
git add src/inventory src/components/inventory
git commit -m "feat: add private Weedypedia inventory"
```

---

### Task 6: Replace the Legacy Shell with the Authenticated Weedypedia Foundation

**Files:**
- Modify: `src/app/App.tsx`
- Modify: `src/app/App.test.tsx`
- Modify: `src/components/AppNavigation.tsx`
- Modify: `src/components/AppNavigation.test.tsx`
- Create: `src/components/FoundationNotice.tsx`
- Delete: `src/components/AgeGate.tsx`
- Delete: `src/components/AgeGate.test.tsx`
- Modify: `src/styles/app.css`
- Modify: `vite.config.ts`
- Modify: `README.md`

**Interfaces:**
- `AppTab = 'discover' | 'search' | 'inventory' | 'profile'`.
- Signed-out users see `AuthGate`.
- AAL1 users with verified TOTP see `MfaChallenge`.
- AAL2/signed-in users see the Weedypedia shell.

- [ ] **Step 1: Rewrite failing shell and navigation tests**

```ts
it('identifies itself as Weedypedia after authentication', async () => {
  render(<TestApp signedIn />)
  expect(await screen.findByRole('heading', { name: 'Weedypedia' })).toBeInTheDocument()
  expect(screen.getByText('Sorten, Herkunft und Produkte nachvollziehbar verbunden')).toBeInTheDocument()
})

it('keeps inventory behind verified authentication', () => {
  render(<TestApp signedOut />)
  expect(screen.getByRole('heading', { name: 'Bei Weedypedia anmelden' })).toBeInTheDocument()
  expect(screen.queryByRole('button', { name: 'Bestand' })).not.toBeInTheDocument()
})
```

Expected navigation labels:

```ts
['Entdecken', 'Suche', 'Bestand', 'Profil']
```

- [ ] **Step 2: Run tests and verify legacy failure**

Run:

```sh
pnpm test -- src/app/App.test.tsx src/components/AppNavigation.test.tsx
```

Expected: FAIL because the shell still says Weedpreis.

- [ ] **Step 3: Implement the authenticated shell**

Wrap the app in `AuthProvider`. Render:

- progress during session loading;
- `AuthGate` when signed out or verification is pending;
- `MfaChallenge` when AAL2 is required;
- four-tab shell when fully authenticated;
- `InventoryView` for Bestand;
- `AccountSettings` for Profil.

Until the knowledge plan is implemented, Entdecken and Suche render:

```text
Der nachweisbare Weedypedia-Wissenskatalog wird in der nächsten freigegebenen
Etappe verbunden. Konto und persönlicher Bestand sind bereits getrennt
abgesichert.
```

Production activation remains disabled until those stages are complete.

- [ ] **Step 4: Remove the obsolete local age gate**

Delete `AgeGate` and remove `weedpreis.adult` access. Age confirmation is now an
immutable registration receipt. Leave pure legacy pricing modules unreachable
until the knowledge-shell migration plan removes them with their dependent
tests.

- [ ] **Step 5: Rebrand the manifest**

Use:

```text
name: Weedypedia – Sortenwissen mit Quellen
short_name: Weedypedia
description: Nachvollziehbare Informationen zu Cannabis-Sorten, Herkunft,
Verwandtschaft und medizinischen Produkten.
theme_color: #07110f
background_color: #07110f
display: standalone
lang: de
```

- [ ] **Step 6: Style iPhone account and inventory flows**

Preserve safe areas and the dark status bar. Add four-tab navigation, clear
private-data and verification states, 44-pixel targets, focus-visible styles,
no horizontal overflow, and reduced-motion rules.

- [ ] **Step 7: Verify and commit**

Run:

```sh
pnpm test
pnpm build
git diff --check
```

```sh
git add src/app src/components src/styles/app.css vite.config.ts README.md
git commit -m "feat: introduce authenticated Weedypedia shell"
```

---

### Task 7: Prove Verification, TOTP, Isolation, Recovery, Export, Deletion, and iPhone Usability

**Files:**
- Create: `tests/e2e/weedypedia-account-inventory.spec.ts`
- Delete: `tests/e2e/iphone-flow.spec.ts`
- Modify: `playwright.config.ts`
- Modify: `.github/workflows/verify.yml`
- Modify: `.github/workflows/pages.yml`
- Create: `docs/operations/weedypedia-account-activation.md`
- Modify: `README.md`

**Interfaces:**
- CI gate: `pnpm check:platform && pnpm check && pnpm test:e2e`.
- Registration remains disabled in production until the runbook is signed off.

- [ ] **Step 1: Write failing two-user iPhone tests**

With local Supabase and Mailpit, cover:

1. register user A with pseudonym, email, password, 18+, and both consents;
2. prove no app access before clicking the verification email;
3. confirm through Mailpit and sign in;
4. enroll TOTP, verify AAL2, log out, and prove the next login requires TOTP;
5. add minimal and fully optional inventory entries;
6. reload and verify the session and items;
7. export JSON after fresh password plus TOTP proof and verify profile, email,
   receipts, and inventory are present but password, token, Auth metadata, and
   internal roles are absent;
8. log out and register verified user B;
9. prove user B cannot read or mutate user A's profile or items through UI or
   direct Data API calls;
10. request password recovery for user A and for an unknown email and prove the
    visible responses are identical;
11. complete user A's Mailpit recovery link and change the password;
12. change user A's email only after current-password reauthentication and
    confirmation at both old and new Mailpit inboxes;
13. delete user A after typing the username and supplying fresh password plus
    TOTP proof, then prove login and API access fail.

Also assert theme-color metadata, dark status bar integration, 44-pixel
controls, keyboard focus order, reduced-motion behavior, and no horizontal page
overflow.

Update `playwright.config.ts` to read the ignored
`supabase/.temp/status.env` produced by `supabase status -o env`. Map `API_URL`
to `VITE_SUPABASE_URL` and `ANON_KEY` to
`VITE_SUPABASE_PUBLISHABLE_KEY` in `webServer.env`; set the two legal versions
and local callback URL explicitly. Fail before launching the browser if the
status file or either key is missing. Never pass `SERVICE_ROLE_KEY` to Vite or
the browser process.

- [ ] **Step 2: Run the E2E test and verify failure**

Run:

```sh
pnpm exec supabase start
pnpm exec supabase status -o env > supabase/.temp/status.env
pnpm test:e2e -- tests/e2e/weedypedia-account-inventory.spec.ts
```

Expected: FAIL until Auth, Mailpit, and the new shell are wired.

- [ ] **Step 3: Add CI gates**

Add:

```yaml
- run: pnpm install --frozen-lockfile
- run: pnpm exec supabase start
- run: pnpm exec supabase status -o env > supabase/.temp/status.env
- run: pnpm test:db
- run: pnpm test:functions
- run: pnpm exec supabase db lint --level error
- run: pnpm test
- run: pnpm build
- run: pnpm exec playwright install --with-deps webkit
- run: pnpm test:e2e
```

CI uses synthetic `.invalid` emails and local Mailpit only. It never sends
external email or contacts a production project.

Update the Pages build to require repository environment variables
`SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `PRIVACY_VERSION`,
`TERMS_VERSION`, and `AUTH_REDIRECT_URL`, map only those values to their
`VITE_` names, and keep hosted Auth signups disabled until the runbook gate is
approved. Do not add the secret key or any SMTP credential to the Pages job.

- [ ] **Step 4: Write the activation and incident runbook**

Include exact gates:

- EU-region Supabase project and data-processing agreement approved;
- legal privacy/terms copy and 18+ wording approved;
- custom SMTP provider approved with data-minimizing templates;
- production Site URL and exact GitHub Pages redirects allowlisted;
- Confirm Email, Secure Email Change, 12-character minimum, Auth rate limits,
  and administrator MFA verified;
- publishable key only in browser configuration and secret key only in the
  deletion function;
- cross-user RLS tests repeated against staging;
- email never duplicated into API profile/inventory tables or analytics;
- Auth emails contain no cannabis, medical, or inventory details in subject or
  preview text;
- SMTP open/click tracking is disabled;
- export and deletion require a proof session no older than five minutes,
  password AMR, and AAL2 whenever a verified TOTP factor exists;
- export and deletion sample audit complete;
- backup/restore test complete;
- incident procedure for account enumeration, mailbox compromise, unauthorized
  inventory access, token leak, and deletion failure;
- rollback disables registration and writes without deleting existing accounts.

- [ ] **Step 5: Run complete verification**

Run:

```sh
pnpm exec supabase db reset
pnpm check:platform
pnpm check
pnpm test:e2e
pnpm exec supabase db lint --level error
git diff --check
git status --short
```

Expected: all database, function, unit, build, and iPhone checks pass; only
intended account-foundation files changed.

- [ ] **Step 6: Commit the verified foundation**

```sh
git add .github/workflows/verify.yml .github/workflows/pages.yml playwright.config.ts tests/e2e README.md docs/operations/weedypedia-account-activation.md
git commit -m "test: verify Weedypedia account privacy"
```

- [ ] **Step 7: Request review before planning the knowledge graph**

Provide commit list, verification output, cross-user RLS evidence, Auth email
screenshots from Mailpit, TOTP evidence, export/deletion evidence, iPhone trace,
and confirmation that production registration remains disabled.

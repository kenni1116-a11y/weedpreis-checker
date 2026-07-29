-- Remote staging version: 20260729190114; original version: 20260729190049.
update private.legal_versions
set active = false
where kind in ('privacy', 'terms', 'adult')
  and version not in (
    'weedypedia-privacy-2026-07-25',
    'weedypedia-terms-2026-07-25',
    'weedypedia-adult-2026-07-25'
  );

insert into private.legal_versions(kind, version, active, effective_at)
values
  (
    'privacy',
    'weedypedia-privacy-2026-07-25',
    true,
    '2026-07-25T00:00:00Z'
  ),
  (
    'terms',
    'weedypedia-terms-2026-07-25',
    true,
    '2026-07-25T00:00:00Z'
  ),
  (
    'adult',
    'weedypedia-adult-2026-07-25',
    true,
    '2026-07-25T00:00:00Z'
  )
on conflict (kind, version) do update
set active = excluded.active,
    effective_at = excluded.effective_at;

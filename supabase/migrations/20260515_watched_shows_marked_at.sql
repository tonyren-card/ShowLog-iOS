-- Add marked_at timestamp to watched_shows so rows can be ordered by when
-- the user marked the show as watched. Existing rows are backfilled to now().

alter table public.watched_shows
    add column if not exists marked_at timestamptz not null default now();

-- Backfill any existing rows that have NULL (shouldn't happen with the default,
-- but included for safety).
update public.watched_shows
set marked_at = now()
where marked_at is null;

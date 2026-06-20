-- NOTE: This schema is already LIVE — it was applied from the web app's
-- FEA-11 (Social / Friends Feed) work against the shared Supabase project.
-- This file exists only to document it in this repo's migration history;
-- there is nothing to run here.

-- profiles: public-facing mirror of auth.users metadata + privacy flag
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text,
  avatar_url text,
  is_public boolean not null default true,
  created_at timestamptz not null default now()
);

grant select on public.profiles to anon;
grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.profiles to service_role;

alter table public.profiles enable row level security;

create policy "profiles visible if public or own"
  on public.profiles for select
  using (is_public = true or id = auth.uid());

create policy "users update own profile"
  on public.profiles for update to authenticated
  using (auth.uid() = id) with check (auth.uid() = id);

-- keep profiles.username/avatar_url synced with auth.users metadata
-- (username/avatar are edited via the auth user_metadata update endpoint,
-- the same one SupabaseService.updateUsername/updateAvatarUrl call)
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username, avatar_url)
  values (new.id, new.raw_user_meta_data->>'username', new.raw_user_meta_data->>'avatar_url');
  return new;
end; $$;

create trigger on_auth_user_created
  after insert on auth.users for each row execute function public.handle_new_user();

create or replace function public.handle_user_metadata_update()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.profiles
  set username = new.raw_user_meta_data->>'username',
      avatar_url = new.raw_user_meta_data->>'avatar_url'
  where id = new.id;
  return new;
end; $$;

create trigger on_auth_user_updated
  after update of raw_user_meta_data on auth.users for each row execute function public.handle_user_metadata_update();

-- backfill rows for every existing user (default public)
insert into public.profiles (id, username, avatar_url)
select id, raw_user_meta_data->>'username', raw_user_meta_data->>'avatar_url' from auth.users
on conflict (id) do nothing;

-- follows: drives the personalized Feed + Popular with Friends only
create table public.follows (
  follower_id uuid not null references auth.users(id) on delete cascade,
  following_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  constraint no_self_follow check (follower_id <> following_id)
);

grant select, insert, delete on public.follows to authenticated;
grant select, insert, update, delete on public.follows to service_role;

alter table public.follows enable row level security;

create policy "see own follow graph"
  on public.follows for select to authenticated
  using (follower_id = auth.uid() or following_id = auth.uid());

create policy "follow public profiles only"
  on public.follows for insert to authenticated
  with check (follower_id = auth.uid()
    and exists (select 1 from public.profiles p where p.id = following_id and p.is_public = true));

create policy "unfollow own rows"
  on public.follows for delete to authenticated
  using (follower_id = auth.uid());

-- open up diary_entries read access to public profiles (everyone, not just followers)
-- this ADDS a policy; Postgres OR's multiple permissive policies together,
-- so it purely widens access on top of the existing owner-only policy.
grant select on public.diary_entries to anon;

create policy "diary entries readable on public profiles"
  on public.diary_entries for select to authenticated
  using (exists (select 1 from public.profiles p where p.id = diary_entries.user_id and p.is_public = true));

create policy "anon can read diary entries on public profiles"
  on public.diary_entries for select to anon
  using (exists (select 1 from public.profiles p where p.id = diary_entries.user_id and p.is_public = true));

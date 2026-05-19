-- Create a public avatars bucket for profile pictures.
-- File path per user: avatars/{user_id}.jpg

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'avatars',
    'avatars',
    true,
    5242880,  -- 5 MB
    array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

-- Authenticated users can upload/replace their own avatar
create policy "users can upload their own avatar"
    on storage.objects for insert to authenticated
    with check (
        bucket_id = 'avatars'
        and name = (auth.uid()::text || '.jpg')
    );

create policy "users can update their own avatar"
    on storage.objects for update to authenticated
    using (
        bucket_id = 'avatars'
        and name = (auth.uid()::text || '.jpg')
    );

-- Public read access (bucket is public, avatars are not sensitive)
create policy "anyone can view avatars"
    on storage.objects for select to public
    using (bucket_id = 'avatars');

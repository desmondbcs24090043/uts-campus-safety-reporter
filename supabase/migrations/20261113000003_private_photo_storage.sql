-- =====================================================================
-- Migration 0003 : Private storage bucket for report photos
-- Owner          : Member 4
--
-- Bucket   : report-photos   (PRIVATE -> no public URLs)
-- Max size : 5 MB, images only (jpeg / png / webp)
--
-- FOLDER RULE (very important for Member 3's upload code):
--   Every photo must be uploaded to   <user-id>/<file-name>
--   e.g.  3f2a...-....-..../1731480000000.jpg
--   The first folder MUST be the uploader's own auth user id.
--
-- WHO CAN DO WHAT
--   student : upload into own folder, view own photos
--   admin   : view ALL photos (Web Admin uses short-lived signed URLs)
--   nobody  : overwrite or delete photos through the API
-- =====================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'report-photos',
  'report-photos',
  false,                                         -- PRIVATE
  5242880,                                       -- 5 MB
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
  set public             = excluded.public,
      file_size_limit    = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;


-- storage.objects already has RLS enabled by Supabase; we only add policies.
drop policy if exists "report-photos: student uploads to own folder" on storage.objects;
drop policy if exists "report-photos: student reads own"             on storage.objects;
drop policy if exists "report-photos: admin reads all"               on storage.objects;

-- UPLOAD: only into a folder named after your own user id.
create policy "report-photos: student uploads to own folder"
  on storage.objects for insert
  to authenticated
  with check (
        bucket_id = 'report-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- VIEW / DOWNLOAD / SIGNED URL: your own photos.
create policy "report-photos: student reads own"
  on storage.objects for select
  to authenticated
  using (
        bucket_id = 'report-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- VIEW / DOWNLOAD / SIGNED URL: admins can see every report photo.
create policy "report-photos: admin reads all"
  on storage.objects for select
  to authenticated
  using (
        bucket_id = 'report-photos'
    and (select public.is_admin())
  );

-- No UPDATE / DELETE policies -> photos are evidence and cannot be
-- replaced or removed from the app.

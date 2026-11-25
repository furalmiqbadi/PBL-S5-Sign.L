-- Backend profil pengguna.
--
-- Menambahkan preferensi belajar, validasi, satu RPC update yang aman
-- (tanpa policy UPDATE tabel agar `role`, `points`, `xp`, `is_banned`
-- tidak bisa diubah sendiri), serta bucket `avatars` untuk foto profil.
--
-- Jalankan sekali via Supabase Dashboard -> SQL Editor atau `supabase db push`.
-- Aman dijalankan berulang (idempotent).

alter table public.profiles
  add column if not exists learning_motivations text[] not null default '{}'::text[];

-- Validasi panjang/format dilakukan di RPC `update_my_profile` (bukan CHECK
-- constraint) agar baris lama yang belum sesuai tidak menghalangi update.

create unique index if not exists profiles_username_lower_idx
  on public.profiles (lower(username));

create or replace function public.set_profiles_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function public.set_profiles_updated_at();

create or replace function public.update_my_profile(
  p_full_name text default null,
  p_username text default null,
  p_bio text default null,
  p_phone text default null,
  p_level integer default null,
  p_avatar_url text default null,
  p_featured_badges text[] default null,
  p_motivations text[] default null
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_username text;
  v_result public.profiles;
begin
  if v_uid is null then
    raise exception 'Silakan login untuk mengubah profil';
  end if;

  if p_full_name is not null
     and (char_length(btrim(p_full_name)) < 1 or char_length(btrim(p_full_name)) > 80) then
    raise exception 'Nama lengkap harus 1-80 karakter';
  end if;

  if p_bio is not null and char_length(btrim(p_bio)) > 150 then
    raise exception 'Bio maksimal 150 karakter';
  end if;

  if p_username is not null then
    v_username := lower(btrim(p_username));
    if v_username !~ '^[a-z0-9._]{3,30}$' then
      raise exception 'Username 3-30 karakter: huruf kecil, angka, titik, atau garis bawah';
    end if;
    if exists (
      select 1
      from public.profiles p
      where lower(p.username) = v_username
        and p.id <> v_uid
    ) then
      raise exception using errcode = '23505', message = 'Username sudah dipakai';
    end if;
  end if;

  if p_level is not null and (p_level < 1 or p_level > 3) then
    raise exception 'Level harus 1, 2, atau 3';
  end if;

  if p_phone is not null
     and btrim(p_phone) <> ''
     and btrim(p_phone) !~ '^\+?[0-9][0-9 ()\-]{6,19}$' then
    raise exception 'Nomor telepon tidak valid';
  end if;

  if p_featured_badges is not null and cardinality(p_featured_badges) > 3 then
    raise exception 'Maksimal 3 lencana unggulan';
  end if;

  if p_avatar_url is not null
     and btrim(p_avatar_url) <> ''
     and p_avatar_url not like (
       '%/storage/v1/object/public/avatars/' || v_uid::text || '/%'
     ) then
    raise exception 'URL avatar tidak valid';
  end if;

  update public.profiles p
  set
    full_name = coalesce(nullif(btrim(p_full_name), ''), p.full_name),
    username = coalesce(v_username, p.username),
    bio = case
      when p_bio is null then p.bio
      else btrim(p_bio)
    end,
    phone = case
      when p_phone is null then p.phone
      when btrim(p_phone) = '' then null
      else btrim(p_phone)
    end,
    level = coalesce(p_level, p.level),
    avatar_url = case
      when p_avatar_url is null then p.avatar_url
      when btrim(p_avatar_url) = '' then null
      else p_avatar_url
    end,
    featured_badges = case
      when p_featured_badges is null then p.featured_badges
      else coalesce(
        (
          select array_agg(distinct b)
          from unnest(p_featured_badges) as badge(b)
          where btrim(b) <> ''
        ),
        '{}'::text[]
      )
    end,
    learning_motivations = case
      when p_motivations is null then p.learning_motivations
      else coalesce(
        (
          select array_agg(distinct m)
          from unnest(p_motivations) as motivation(m)
          where btrim(m) <> ''
        ),
        '{}'::text[]
      )
    end,
    updated_at = now()
  where p.id = v_uid
  returning * into v_result;

  if v_result.id is null then
    raise exception 'Profil tidak ditemukan';
  end if;

  return v_result;
end;
$$;

revoke all on function
  public.update_my_profile(text, text, text, text, integer, text, text[], text[])
  from public, anon;

grant execute on function
  public.update_my_profile(text, text, text, text, integer, text, text[], text[])
  to authenticated;

-- Bucket avatar: publik untuk dibaca (dipakai chat/komunitas), tetapi hanya
-- pemilik folder `{uid}/...` yang boleh menulis.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  2097152,
  array['image/webp', 'image/jpeg', 'image/png']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "avatars_public_read" on storage.objects;
create policy "avatars_public_read"
  on storage.objects for select
  using (bucket_id = 'avatars');

drop policy if exists "avatars_insert_own" on storage.objects;
create policy "avatars_insert_own"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "avatars_update_own" on storage.objects;
create policy "avatars_update_own"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "avatars_delete_own" on storage.objects;
create policy "avatars_delete_own"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

notify pgrst, 'reload schema';

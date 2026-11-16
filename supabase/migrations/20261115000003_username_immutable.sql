-- Kunci username agar tidak bisa diubah, hanya nama (dan field profil lain)
-- yang bisa diedit. Sekaligus menyelaraskan data akun yang terlanjur berubah
-- username profilnya dengan identitas login di auth.users.

-- 1. Kembalikan username profil yang berbeda dari metadata auth (identitas
--    login) ke nilai metadata tersebut. Lewati bila username itu sudah dipakai
--    akun lain agar tidak melanggar unique index case-insensitive.
update public.profiles p
set username = lower(btrim(u.raw_user_meta_data ->> 'username'))
from auth.users u
where u.id = p.id
  and coalesce(u.raw_user_meta_data ->> 'username', '') <> ''
  and lower(btrim(p.username)) <>
      lower(btrim(u.raw_user_meta_data ->> 'username'))
  and not exists (
    select 1
    from public.profiles p2
    where p2.id <> p.id
      and lower(p2.username) =
          lower(btrim(u.raw_user_meta_data ->> 'username'))
  );

-- 2. Samakan metadata nama di auth dengan profil (best-effort). Ini membuat
--    notifikasi baru ikut memakai nama terbaru bila trigger notifikasi membaca
--    raw_user_meta_data. Username sengaja tidak disentuh.
do $$
begin
  update auth.users u
  set raw_user_meta_data = coalesce(u.raw_user_meta_data, '{}'::jsonb)
    || jsonb_build_object(
         'full_name', p.full_name,
         'name', p.full_name)
  from public.profiles p
  where p.id = u.id
    and coalesce(p.full_name, '') <> ''
    and coalesce(u.raw_user_meta_data ->> 'full_name', '') <> p.full_name;
exception
  when others then
    raise warning 'sync auth name failed: %', sqlerrm;
end $$;

-- 3. update_my_profile v3: p_username tetap diterima demi kompatibilitas
--    client lama, tetapi diabaikan. Username bersifat permanen.
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

  -- Samakan metadata nama tanpa menyentuh username. Best-effort agar
  -- kegagalan izin ke auth.users tidak membatalkan penyimpanan profil.
  begin
    update auth.users u
    set raw_user_meta_data = coalesce(u.raw_user_meta_data, '{}'::jsonb)
      || jsonb_build_object(
           'full_name', v_result.full_name,
           'name', v_result.full_name)
    where u.id = v_uid;
  exception
    when others then
      raise warning 'sync auth name failed: %', sqlerrm;
  end;

  return v_result;
end;
$$;

revoke all on function
  public.update_my_profile(text, text, text, text, integer, text, text[], text[])
  from public, anon;

grant execute on function
  public.update_my_profile(text, text, text, text, integer, text, text[], text[])
  to authenticated;

notify pgrst, 'reload schema';

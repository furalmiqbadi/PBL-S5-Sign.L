-- Pembuatan grup chat.
--
-- RPC `create_chat_group` membuat room bertipe grup beserta seluruh anggotanya
-- dalam satu transaksi, lalu memberi notifikasi in-app ke setiap anggota yang
-- diundang. Pembuat grup otomatis menjadi anggota.
--
-- Jalankan sekali via Supabase Dashboard -> SQL Editor atau `supabase db push`.

create or replace function public.create_chat_group(
  group_name text,
  member_ids uuid[]
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  creator uuid := (select auth.uid());
  clean_name text := btrim(coalesce(group_name, ''));
  clean_members uuid[];
  new_room_id uuid;
begin
  if creator is null then
    raise exception 'Silakan login untuk membuat grup';
  end if;

  if length(clean_name) < 1 or length(clean_name) > 80 then
    raise exception 'Nama grup harus 1-80 karakter';
  end if;

  select array_agg(distinct candidate)
  into clean_members
  from unnest(coalesce(member_ids, '{}'::uuid[])) as candidate
  where candidate <> creator;

  if clean_members is null or array_length(clean_members, 1) is null then
    raise exception 'Pilih minimal satu anggota grup';
  end if;

  if array_length(clean_members, 1) > 50 then
    raise exception 'Anggota grup maksimal 50 orang';
  end if;

  insert into public.chat_rooms (name, is_group, created_by)
  values (clean_name, true, creator)
  returning id into new_room_id;

  insert into public.chat_room_members (room_id, user_id)
  select new_room_id, member
  from unnest(array_append(clean_members, creator)) as member;

  insert into public.notifications (
    user_id, category, title, body, action_label, avatar_url, target_type, target_id
  )
  select member,
         'chat',
         'Grup baru',
         'Kamu ditambahkan ke ' || clean_name,
         'Buka chat',
         null,
         'chat',
         new_room_id
  from unnest(clean_members) as member;

  return new_room_id;
end;
$$;

grant execute on function public.create_chat_group(text, uuid[]) to authenticated;
revoke all on function public.create_chat_group(text, uuid[]) from public, anon;

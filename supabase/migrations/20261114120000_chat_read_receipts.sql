-- Centang biru (read receipt) untuk chat.
--
-- Menyediakan:
--   1. Helper `is_chat_room_member` agar policy SELECT antaranggota tidak
--      rekursif saat mengevaluasi RLS pada tabel yang sama.
--   2. Policy SELECT antaranggota room sehingga pengirim dapat melihat
--      `last_read_at` lawan bicara (dibutuhkan juga oleh Supabase Realtime).
--   3. RPC `get_chat_room_read_at` yang mengembalikan waktu baca paling awal
--      di antara seluruh anggota lain (direct: lawan bicara, grup: semua).
--   4. Realtime untuk tabel `chat_room_members`.
--
-- Jalankan sekali via Supabase Dashboard -> SQL Editor atau `supabase db push`.

create or replace function public.is_chat_room_member(target_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.chat_room_members m
    where m.room_id = target_room_id
      and m.user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_chat_room_member(uuid) from public, anon;
grant execute on function public.is_chat_room_member(uuid) to authenticated;

drop policy if exists "chat_members_select_co_members"
  on public.chat_room_members;
create policy "chat_members_select_co_members"
  on public.chat_room_members for select to authenticated
  using (public.is_chat_room_member(room_id));

create or replace function public.get_chat_room_read_at(target_room_id uuid)
returns timestamptz
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when not exists (
      select 1
      from public.chat_room_members self
      where self.room_id = target_room_id
        and self.user_id = (select auth.uid())
    ) then null
    else (
      select min(other.last_read_at)
      from public.chat_room_members other
      where other.room_id = target_room_id
        and other.user_id <> (select auth.uid())
    )
  end;
$$;

revoke all on function public.get_chat_room_read_at(uuid) from public, anon;
grant execute on function public.get_chat_room_read_at(uuid) to authenticated;

-- Supabase Realtime butuh replika penuh agar payload UPDATE memuat
-- `last_read_at` dan `user_id` secara utuh.
alter table public.chat_room_members replica identity full;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chat_room_members'
  ) then
    alter publication supabase_realtime add table public.chat_room_members;
  end if;
end;
$$;

-- Aktifkan Supabase Realtime untuk tabel chat_messages dan notifications.
-- Tanpa ini, perubahan data di Postgres tidak akan dikirim ke client Flutter.
--
-- Jalankan sekali via:
--   supabase db push
-- atau paste langsung di Supabase Dashboard → SQL Editor.

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chat_messages'
  ) then
    alter publication supabase_realtime add table public.chat_messages;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  full_name text,
  username text unique,
  avatar_url text,
  role text not null default 'user',
  created_at timestamptz not null default now()
);

alter table public.profiles
  add column if not exists email text,
  add column if not exists full_name text,
  add column if not exists username text,
  add column if not exists avatar_url text,
  add column if not exists role text not null default 'user',
  add column if not exists created_at timestamptz not null default now();

create table if not exists public.chat_rooms (
  id uuid primary key default gen_random_uuid(),
  name text,
  is_group boolean not null default false,
  direct_key text unique,
  created_by uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint chat_rooms_direct_key_check
    check ((is_group and direct_key is null) or (not is_group and direct_key is not null))
);

create table if not exists public.chat_room_members (
  room_id uuid not null references public.chat_rooms (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  joined_at timestamptz not null default now(),
  last_read_at timestamptz not null default now(),
  cleared_at timestamptz not null default 'epoch',
  is_muted boolean not null default false,
  primary key (room_id, user_id)
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.chat_rooms (id) on delete cascade,
  sender_id uuid not null references auth.users (id) on delete cascade,
  body text not null check (length(btrim(body)) between 1 and 4000),
  created_at timestamptz not null default now()
);

create index if not exists chat_room_members_user_idx
  on public.chat_room_members (user_id, room_id);
create index if not exists chat_messages_room_created_idx
  on public.chat_messages (room_id, created_at desc);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  category text not null check (category in ('komunitas', 'belajar', 'pencapaian', 'chat')),
  title text not null,
  body text not null default '',
  action_label text,
  avatar_url text,
  target_type text check (target_type in ('community', 'learning', 'achievement', 'chat')),
  target_id uuid,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index if not exists notifications_user_created_idx
  on public.notifications (user_id, created_at desc);

alter table public.notifications
  add column if not exists target_type text,
  add column if not exists target_id uuid;

create or replace function public.handle_new_auth_user_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, full_name, username, role, created_at)
  values (
    new.id,
    new.email,
    coalesce(
  nullif(new.raw_user_meta_data ->> 'username', ''),
  'user_' || substr(replace(new.id::text, '-', ''), 1, 16)
),
    new.raw_user_meta_data ->> 'username',
    'user',
    now()
  )
  on conflict do nothing;
  return new;
end;
$$;

drop trigger if exists auth_user_profile_after_insert on auth.users;
create trigger auth_user_profile_after_insert
  after insert on auth.users
  for each row execute function public.handle_new_auth_user_profile();

insert into public.profiles (id, email, full_name, username, role, created_at)
select
  u.id,
  u.email,
  coalesce(u.raw_user_meta_data ->> 'full_name', u.raw_user_meta_data ->> 'name'),
  u.raw_user_meta_data ->> 'username',
  'user',
  coalesce(u.created_at, now())
from auth.users u
on conflict do nothing;

update public.profiles p
set email = coalesce(p.email, u.email),
    full_name = coalesce(
      p.full_name,
      u.raw_user_meta_data ->> 'full_name',
      u.raw_user_meta_data ->> 'name'
    ),
    username = case
      when p.username is not null then p.username
      when u.raw_user_meta_data ->> 'username' is null then null
      when exists (
        select 1
        from public.profiles other
        where other.username = u.raw_user_meta_data ->> 'username'
          and other.id <> p.id
      ) then null
      else u.raw_user_meta_data ->> 'username'
    end
from auth.users u
where p.id = u.id;

alter table public.profiles enable row level security;
alter table public.chat_rooms enable row level security;
alter table public.chat_room_members enable row level security;
alter table public.chat_messages enable row level security;
alter table public.notifications enable row level security;

drop policy if exists "profiles_select_self" on public.profiles;
create policy "profiles_select_self"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()));

drop policy if exists "chat_rooms_select_member" on public.chat_rooms;
create policy "chat_rooms_select_member"
  on public.chat_rooms for select to authenticated
  using (
    exists (
      select 1 from public.chat_room_members m
      where m.room_id = chat_rooms.id and m.user_id = (select auth.uid())
    )
  );

drop policy if exists "chat_members_select_room_member" on public.chat_room_members;
create policy "chat_members_select_room_member"
  on public.chat_room_members for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "chat_messages_select_room_member" on public.chat_messages;
create policy "chat_messages_select_room_member"
  on public.chat_messages for select to authenticated
  using (
    exists (
      select 1 from public.chat_room_members m
      where m.room_id = chat_messages.room_id
        and m.user_id = (select auth.uid())
        and chat_messages.created_at > m.cleared_at
    )
  );

drop policy if exists "chat_messages_insert_as_self" on public.chat_messages;
create policy "chat_messages_insert_as_self"
  on public.chat_messages for insert to authenticated
  with check (
    sender_id = (select auth.uid())
    and exists (
      select 1 from public.chat_room_members m
      where m.room_id = chat_messages.room_id
        and m.user_id = (select auth.uid())
    )
  );

drop policy if exists "notifications_select_self" on public.notifications;
create policy "notifications_select_self"
  on public.notifications for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "notifications_update_self" on public.notifications;
create policy "notifications_update_self"
  on public.notifications for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create or replace function public.get_chat_contacts()
returns table (user_id uuid, full_name text, username text, avatar_url text)
language sql
stable
security definer
set search_path = ''
as $$
  select p.id, p.full_name, p.username, p.avatar_url
  from public.profiles p
  where p.id <> (select auth.uid())
    and (select auth.uid()) is not null
  order by coalesce(p.full_name, p.username, '') asc;
$$;

create or replace function public.get_or_create_direct_chat(target_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  room_id uuid;
  room_key text;
begin
  if caller_id is null then
    raise exception 'Authentication required';
  end if;
  if target_user_id is null or target_user_id = caller_id then
    raise exception 'A different user must be selected';
  end if;
  if not exists (select 1 from public.profiles p where p.id = target_user_id) then
    raise exception 'User profile not found';
  end if;

  room_key := least(caller_id::text, target_user_id::text) || ':' ||
              greatest(caller_id::text, target_user_id::text);
  insert into public.chat_rooms (direct_key, created_by)
  values (room_key, caller_id)
  on conflict (direct_key) do update set direct_key = excluded.direct_key
  returning id into room_id;

  insert into public.chat_room_members (room_id, user_id)
  values (room_id, caller_id), (room_id, target_user_id)
  on conflict (room_id, user_id) do nothing;
  return room_id;
end;
$$;

create or replace function public.get_chat_rooms()
returns table (
  id uuid,
  name text,
  avatar_url text,
  last_message text,
  last_message_time timestamptz,
  unread_count bigint,
  is_group boolean,
  member_count bigint,
  last_sender_name text,
  is_muted boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select r.id,
         case when r.is_group then r.name else coalesce(other.full_name, other.username, 'Pengguna') end,
         case when r.is_group then null else other.avatar_url end,
         coalesce(latest.body, ''),
         coalesce(latest.created_at, r.updated_at),
         coalesce(unread.count, 0),
         r.is_group,
         members.count,
         case when r.is_group then sender.full_name else null end,
         own.is_muted
  from public.chat_room_members own
  join public.chat_rooms r on r.id = own.room_id
  left join lateral (
    select p.full_name, p.username, p.avatar_url
    from public.chat_room_members m
    join public.profiles p on p.id = m.user_id
    where m.room_id = r.id and m.user_id <> (select auth.uid())
    order by m.joined_at
    limit 1
  ) other on not r.is_group
  left join lateral (
    select msg.body, msg.created_at, msg.sender_id
    from public.chat_messages msg
    where msg.room_id = r.id and msg.created_at > own.cleared_at
    order by msg.created_at desc
    limit 1
  ) latest on true
  left join lateral (
    select count(*) as count
    from public.chat_messages msg
    where msg.room_id = r.id
      and msg.sender_id <> (select auth.uid())
      and msg.created_at > own.last_read_at
      and msg.created_at > own.cleared_at
  ) unread on true
  left join lateral (
    select count(*) as count
    from public.chat_room_members m
    where m.room_id = r.id
  ) members on true
  left join public.profiles sender on sender.id = latest.sender_id
  where own.user_id = (select auth.uid())
  order by coalesce(latest.created_at, r.updated_at) desc;
$$;

create or replace function public.mark_chat_room_read(target_room_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.chat_room_members
  set last_read_at = now()
  where room_id = target_room_id and user_id = (select auth.uid());
  if not found then raise exception 'Chat room not found'; end if;

  update public.notifications
  set read_at = now()
  where user_id = (select auth.uid())
    and target_type = 'chat'
    and target_id = target_room_id
    and read_at is null;
end;
$$;

create or replace function public.clear_chat_room_history(target_room_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.chat_room_members
  set cleared_at = now(), last_read_at = now()
  where room_id = target_room_id and user_id = (select auth.uid());
  if not found then raise exception 'Chat room not found'; end if;

  update public.notifications
  set read_at = now()
  where user_id = (select auth.uid())
    and target_type = 'chat'
    and target_id = target_room_id
    and read_at is null;
end;
$$;

create or replace function public.set_chat_room_muted(target_room_id uuid, muted boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.chat_room_members
  set is_muted = muted
  where room_id = target_room_id and user_id = (select auth.uid());
  if not found then raise exception 'Chat room not found'; end if;
end;
$$;

create or replace function public.handle_new_chat_message()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  sender_name text;
begin
  update public.chat_rooms set updated_at = new.created_at where id = new.room_id;
  select coalesce(p.full_name, p.username, 'Pengguna')
  into sender_name from public.profiles p where p.id = new.sender_id;

  insert into public.notifications (
    user_id, category, title, body, action_label, avatar_url, target_type, target_id
  )
   select m.user_id, 'chat', coalesce(sender_name, 'Pengguna') || ' mengirim pesan',
         left(new.body, 180), 'Buka chat', p.avatar_url, 'chat', new.room_id
  from public.chat_room_members m
  left join public.profiles p on p.id = new.sender_id
  where m.room_id = new.room_id
    and m.user_id <> new.sender_id
    and not m.is_muted;
  return new;
end;
$$;

drop trigger if exists chat_message_after_insert on public.chat_messages;
create trigger chat_message_after_insert
  after insert on public.chat_messages
  for each row execute function public.handle_new_chat_message();

grant execute on function public.get_chat_contacts() to authenticated;
grant execute on function public.get_or_create_direct_chat(uuid) to authenticated;
grant execute on function public.get_chat_rooms() to authenticated;
grant execute on function public.mark_chat_room_read(uuid) to authenticated;
grant execute on function public.clear_chat_room_history(uuid) to authenticated;
grant execute on function public.set_chat_room_muted(uuid, boolean) to authenticated;

revoke all on function public.get_chat_contacts() from public, anon;
revoke all on function public.get_or_create_direct_chat(uuid) from public, anon;
revoke all on function public.get_chat_rooms() from public, anon;
revoke all on function public.mark_chat_room_read(uuid) from public, anon;
revoke all on function public.clear_chat_room_history(uuid) from public, anon;
revoke all on function public.set_chat_room_muted(uuid, boolean) from public, anon;

revoke all on public.profiles, public.chat_rooms, public.chat_room_members,
  public.chat_messages, public.notifications from public, anon, authenticated;

grant select on public.chat_rooms, public.chat_room_members, public.chat_messages to authenticated;
grant insert on public.chat_messages to authenticated;
grant select on public.profiles to authenticated;
grant select on public.notifications to authenticated;
grant update (read_at) on public.notifications to authenticated;

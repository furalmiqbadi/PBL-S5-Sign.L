# Supabase chat and notifications

Apply `migrations/20261111230000_chat_notifications.sql` first, then
`migrations/20261112000000_enable_realtime.sql`, then
`migrations/20261114120000_chat_read_receipts.sql`, then
`migrations/20261115000000_chat_groups.sql`, and finally
`migrations/20261115000001_chat_groups_notify_safe.sql`, to the same Supabase
project configured by the app. Paste the files into the Supabase SQL Editor in that
order, or link the local Supabase CLI project and run `supabase db push`.

The migration creates the chat and in-app notification tables, enables
row-level security, and adds RPCs for private contact lookup, direct-chat
creation, read state, clearing the current user's view of chat history, and
muting a room. It also creates a profile row for existing and newly registered
users. Direct messages generate an in-app notification for each unmuted
recipient.

The Flutter app reads and writes chat messages and notifications through the
authenticated Supabase client. In-memory sample data is available only through
the explicit `*.inMemory()` service constructors used by controller tests.
There is no push-notification delivery or learning/achievement notification
producer yet; those need a trusted server-side event source and, for push,
device-token/FCM setup.

The Realtime migration is idempotent and can be run again safely. Test with
two authenticated accounts: inserts in `chat_messages` should arrive in the
open room and inserts in `notifications` should arrive without refreshing.

The read-receipt migration adds a co-member SELECT policy on
`chat_room_members`, an `is_chat_room_member` helper, and the
`get_chat_room_read_at` RPC. It also publishes `chat_room_members` to Realtime
so the sender's double checkmark turns blue without reopening the room. The
value returned is the earliest `last_read_at` among the other members, so a
group chat only shows blue once every member has read the message.

The group migration adds `create_chat_group(group_name, member_ids)`, which
creates the group room, adds the creator and selected members, and notifies the
invited members. The chat list also listens to `chat_room_members` inserts, so
invited users see the new group without restarting the app.

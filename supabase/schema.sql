-- نفّذ هذا في Supabase: SQL Editor → New query → Run
-- يُنشئ جدول المزامنة ويفعّل القراءة/الكتابة والتحديث الفوري.

create table if not exists public.app_state (
  key text primary key,
  data jsonb not null default '{}'::jsonb,
  updated bigint not null default 0
);

alter table public.app_state enable row level security;

drop policy if exists "app_state_select" on public.app_state;
drop policy if exists "app_state_insert" on public.app_state;
drop policy if exists "app_state_update" on public.app_state;

create policy "app_state_select"
  on public.app_state for select
  using (true);

create policy "app_state_insert"
  on public.app_state for insert
  with check (true);

create policy "app_state_update"
  on public.app_state for update
  using (true);

alter table public.app_state replica identity full;

-- إذا ظهر خطأ "already member of publication" تجاهله وأكمل.
alter publication supabase_realtime add table public.app_state;

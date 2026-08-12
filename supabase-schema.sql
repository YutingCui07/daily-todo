-- 紫气日程 / daily-todo 的云端数据表
-- 在 Supabase Dashboard -> SQL Editor 中一次性运行

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text default '',
  task_date date not null default current_date,
  task_time time,
  priority text not null default 'medium' check (priority in ('high','medium','low')),
  duration integer not null default 30,
  tags text[] not null default '{}',
  repeat_rule text not null default '不重复',
  reminder boolean not null default false,
  done boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.daily_notes (
  user_id uuid not null references auth.users(id) on delete cascade,
  note_date date not null default current_date,
  review text not null default '',
  tomorrow text not null default '',
  updated_at timestamptz not null default now(),
  primary key (user_id, note_date)
);

alter table public.tasks enable row level security;
alter table public.daily_notes enable row level security;

drop policy if exists "Users can read own tasks" on public.tasks;
drop policy if exists "Users can insert own tasks" on public.tasks;
drop policy if exists "Users can update own tasks" on public.tasks;
drop policy if exists "Users can delete own tasks" on public.tasks;
create policy "Users can read own tasks" on public.tasks for select using (auth.uid() = user_id);
create policy "Users can insert own tasks" on public.tasks for insert with check (auth.uid() = user_id);
create policy "Users can update own tasks" on public.tasks for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own tasks" on public.tasks for delete using (auth.uid() = user_id);

drop policy if exists "Users can read own notes" on public.daily_notes;
drop policy if exists "Users can insert own notes" on public.daily_notes;
drop policy if exists "Users can update own notes" on public.daily_notes;
drop policy if exists "Users can delete own notes" on public.daily_notes;
create policy "Users can read own notes" on public.daily_notes for select using (auth.uid() = user_id);
create policy "Users can insert own notes" on public.daily_notes for insert with check (auth.uid() = user_id);
create policy "Users can update own notes" on public.daily_notes for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own notes" on public.daily_notes for delete using (auth.uid() = user_id);

-- 开启实时变更推送，让手机和电脑能收到对方的修改
alter table public.tasks replica identity full;
alter table public.daily_notes replica identity full;
do $$ begin
  alter publication supabase_realtime add table public.tasks;
exception when duplicate_object then null;
end $$;
do $$ begin
  alter publication supabase_realtime add table public.daily_notes;
exception when duplicate_object then null;
end $$;

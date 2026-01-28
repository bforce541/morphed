-- Created images per profile + storage policies

create extension if not exists "pgcrypto";

create table if not exists public.created_images (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  original_path text not null,
  created_path text not null,
  mode text,
  created_at timestamptz not null default now()
);

alter table public.created_images enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'created_images'
      and policyname = 'created_images_select_own'
  ) then
    create policy "created_images_select_own"
      on public.created_images
      for select
      using (auth.uid() = profile_id);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'created_images'
      and policyname = 'created_images_insert_own'
  ) then
    create policy "created_images_insert_own"
      on public.created_images
      for insert
      with check (auth.uid() = profile_id);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'created_images'
      and policyname = 'created_images_delete_own'
  ) then
    create policy "created_images_delete_own"
      on public.created_images
      for delete
      using (auth.uid() = profile_id);
  end if;
end $$;

-- Storage bucket for originals + created images
insert into storage.buckets (id, name, public)
values ('morphed-images', 'morphed-images', false)
on conflict (id) do nothing;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'morphed_images_select_own'
  ) then
    create policy "morphed_images_select_own"
      on storage.objects
      for select
      using (bucket_id = 'morphed-images' and auth.uid() = owner);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'morphed_images_insert_own'
  ) then
    create policy "morphed_images_insert_own"
      on storage.objects
      for insert
      with check (bucket_id = 'morphed-images' and auth.uid() = owner);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'morphed_images_delete_own'
  ) then
    create policy "morphed_images_delete_own"
      on storage.objects
      for delete
      using (bucket_id = 'morphed-images' and auth.uid() = owner);
  end if;
end $$;

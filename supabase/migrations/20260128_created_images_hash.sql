alter table public.created_images
  add column if not exists original_hash text;

create unique index if not exists created_images_profile_original_hash_idx
  on public.created_images (profile_id, original_hash)
  where original_hash is not null;

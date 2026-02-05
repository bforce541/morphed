drop index if exists public.created_images_profile_original_hash_idx;

create unique index if not exists created_images_profile_original_hash_mode_idx
  on public.created_images (profile_id, original_hash, mode)
  where original_hash is not null and mode is not null;

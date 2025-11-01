create or replace function public.ensure_points_row(uid uuid) returns void language sql as $$
  insert into public.user_points (user_id) values (uid) on conflict (user_id) do nothing;
$$;

create or replace function public.spend_points(uid uuid, amount int, note text) returns boolean
language plpgsql as $$
begin
  perform public.ensure_points_row(uid);
  update public.user_points set available_points = available_points - amount, updated_at = now()
  where user_id = uid and available_points >= amount;
  if not found then return false; end if;
  insert into public.point_ledger(user_id, kind, amount, note) values (uid, 'spend', amount, note);
  return true;
end; $$;

create or replace function public.earn_points(uid uuid, amount int, note text) returns void
language plpgsql as $$
begin
  perform public.ensure_points_row(uid);
  update public.user_points set available_points = available_points + amount, total_earned = total_earned + amount, updated_at = now()
  where user_id = uid;
  insert into public.point_ledger(user_id, kind, amount, note) values (uid, 'earn', amount, note);
end; $$;

create or replace function public.credit_purchase_points(uid uuid, amount int, ref text) returns void
language plpgsql as $$
begin
  perform public.ensure_points_row(uid);
  update public.user_points set available_points = available_points + amount, total_purchased = total_purchased + amount, updated_at = now()
  where user_id = uid;
  insert into public.point_ledger(user_id, kind, amount, note, ref_id) values (uid, 'purchase', amount, 'RevenueCat Purchase', ref);
end; $$;

create or replace function public.request_media_unlock(conversation_id bigint, uid uuid, media_type text) returns text
language plpgsql as $$
declare ua uuid; ub uuid; a_consent boolean; b_consent boolean; cost int; success boolean;
begin
  if media_type not in ('photo','video') then return 'invalid_media_type'; end if;
  select user_a, user_b into ua, ub from public.conversations where id = conversation_id;
  if ua is null then return 'not_found'; end if;

  if media_type = 'photo' then
    update public.conversations set consent_photo_a = (uid = ua) or consent_photo_a,
                                    consent_photo_b = (uid = ub) or consent_photo_b
    where id = conversation_id;
    select consent_photo_a, consent_photo_b into a_consent, b_consent from public.conversations where id = conversation_id;
    if a_consent and b_consent and not (select photo_unlocked from public.conversations where id = conversation_id) then
      cost := 25;
      success := public.spend_points(ua, cost, 'Photo unlock'); if not success then return 'insufficient_points_a'; end if;
      success := public.spend_points(ub, cost, 'Photo unlock'); if not success then perform public.earn_points(ua, cost, 'Refund A'); return 'insufficient_points_b'; end if;
      update public.conversations set photo_unlocked = true where id = conversation_id; return 'unlocked';
    end if; return 'consent_recorded';
  end if;

  if media_type = 'video' then
    update public.conversations set consent_video_a = (uid = ua) or consent_video_a,
                                    consent_video_b = (uid = ub) or consent_video_b
    where id = conversation_id;
    select consent_video_a, consent_video_b into a_consent, b_consent from public.conversations where id = conversation_id;
    if a_consent and b_consent and not (select video_unlocked from public.conversations where id = conversation_id) then
      cost := 60;
      success := public.spend_points(ua, cost, 'Video unlock'); if not success then return 'insufficient_points_a'; end if;
      success := public.spend_points(ub, cost, 'Video unlock'); if not success then perform public.earn_points(ua, cost, 'Refund A'); return 'insufficient_points_b'; end if;
      update public.conversations set video_unlocked = true where id = conversation_id; return 'unlocked';
    end if; return 'consent_recorded';
  end if;
  return 'noop';
end; $$;

-- Daily Dice RPC (1..6, up to 3/day)
create or replace function public.roll_daily_dice(uid uuid) returns int
language plpgsql as $$
declare today date := current_date; current_rolls int; gained int;
begin
  insert into public.daily_checkins(user_id, date, rolls) values (uid, today, 0)
  on conflict (user_id, date) do nothing;
  select rolls into current_rolls from public.daily_checkins where user_id = uid and date = today;
  if current_rolls >= 3 then return 0; end if;
  gained := (1 + (floor(random()*6))::int);
  perform public.earn_points(uid, gained, 'Daily dice');
  update public.daily_checkins set rolls = current_rolls + 1, last_roll_at = now() where user_id = uid and date = today;
  return gained;
end; $$;

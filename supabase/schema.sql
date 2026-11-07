-- Backend del tavolo online di Arkham Horror LCG Supporter (migrazione "ah_tavolo_schema").
-- Stesso progetto Supabase di Four Against, tabelle e funzioni con prefisso ah_.
-- Tabelle chiuse (RLS attivo, nessuna policy): i client chiamano solo le funzioni qui sotto,
-- che richiedono il codice della guida (salvato come hash) o il codice del giocatore.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.ah_games (
  id uuid primary key default gen_random_uuid(),
  host_hash text not null,
  state jsonb not null default '{}'::jsonb,
  doom int not null default 0,
  odoom int not null default 0,
  draw jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.ah_players (
  game_id uuid not null references public.ah_games(id) on delete cascade,
  slot text not null,
  code text not null unique,
  data jsonb not null default '{}'::jsonb,
  primary key (game_id, slot)
);
create table if not exists public.ah_log (
  id bigserial primary key,
  game_id uuid not null references public.ah_games(id) on delete cascade,
  ts timestamptz not null default now(),
  who text not null default '',
  text text not null
);
create index if not exists ah_log_game_idx on public.ah_log(game_id, id desc);

alter table public.ah_games enable row level security;
alter table public.ah_players enable row level security;
alter table public.ah_log enable row level security;
revoke all on public.ah_games, public.ah_players, public.ah_log from anon, authenticated;
revoke all on sequence public.ah_log_id_seq from anon, authenticated;

-- ===== helper interni =====
create or replace function public.ah__merge(a jsonb, b jsonb)
returns jsonb language plpgsql immutable set search_path = '' as $$
declare k text; v jsonb; r jsonb;
begin
  if a is null or jsonb_typeof(a) <> 'object' then r := '{}'::jsonb; else r := a; end if;
  for k, v in select * from jsonb_each(b) loop
    if jsonb_typeof(v) = 'object' and jsonb_typeof(r->k) = 'object' then
      r := r || jsonb_build_object(k, public.ah__merge(r->k, v));
    else
      r := r || jsonb_build_object(k, v);
    end if;
  end loop;
  return r;
end $$;

create or replace function public.ah__hash(t text) returns text
language sql immutable set search_path = '' as $$ select encode(extensions.digest(t, 'sha256'), 'hex') $$;

create or replace function public.ah__host(p_token text) returns uuid
language plpgsql stable security definer set search_path = '' as $$
declare g uuid;
begin
  select id into g from public.ah_games where host_hash = public.ah__hash(p_token);
  if g is null then raise exception 'codice guida non valido'; end if;
  return g;
end $$;

create or replace function public.ah__player(p_code text, out g uuid, out s text)
language plpgsql stable security definer set search_path = '' as $$
begin
  select game_id, slot into g, s from public.ah_players where code = upper(trim(p_code));
  if g is null then raise exception 'codice giocatore non valido'; end if;
end $$;

-- accetta sia il codice guida sia un codice giocatore
create or replace function public.ah__any(p_auth text) returns uuid
language plpgsql stable security definer set search_path = '' as $$
declare g uuid;
begin
  select id into g from public.ah_games where host_hash = public.ah__hash(p_auth);
  if g is null then select game_id into g from public.ah_players where code = upper(trim(p_auth)); end if;
  if g is null then raise exception 'codice non valido'; end if;
  return g;
end $$;

create or replace function public.ah__code() returns text
language plpgsql volatile security definer set search_path = '' as $$
declare alphabet text := 'ACDEFGHJKLMNPQRTUVWXY34679'; c text; i int; b bytea;
begin
  loop
    b := extensions.gen_random_bytes(6); c := '';
    for i in 0..5 loop c := c || substr(alphabet, (get_byte(b, i) % length(alphabet)) + 1, 1); end loop;
    exit when not exists (select 1 from public.ah_players where code = c);
  end loop;
  return c;
end $$;

create or replace function public.ah__pack(g uuid, with_codes boolean) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'game_id', ga.id, 'state', ga.state, 'doom', ga.doom, 'odoom', ga.odoom, 'draw', ga.draw,
    'players', coalesce((select jsonb_object_agg(p.slot, case when with_codes then jsonb_build_object('code', p.code, 'data', p.data) else jsonb_build_object('data', p.data) end)
                          from public.ah_players p where p.game_id = ga.id), '{}'::jsonb),
    'log', coalesce((select jsonb_agg(jsonb_build_object('ts', extract(epoch from l.ts)*1000, 'who', l.who, 'text', l.text) order by l.id desc)
                     from (select * from public.ah_log where game_id = ga.id order by id desc limit 60) l), '[]'::jsonb))
  from public.ah_games ga where ga.id = g
$$;

-- ===== API della guida =====
create or replace function public.ah_create_game(p_state jsonb, p_doom int, p_odoom int) returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare t text := encode(extensions.gen_random_bytes(18), 'hex'); g uuid;
begin
  insert into public.ah_games(host_hash, state, doom, odoom)
  values (public.ah__hash(t), coalesce(p_state, '{}'::jsonb), greatest(0, coalesce(p_doom,0)), greatest(0, coalesce(p_odoom,0)))
  returning id into g;
  return jsonb_build_object('game_id', g, 'token', t);
end $$;

create or replace function public.ah_host_get(p_token text) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin return public.ah__pack(public.ah__host(p_token), true); end $$;

create or replace function public.ah_host_set_state(p_token text, p_state jsonb) returns void
language plpgsql volatile security definer set search_path = '' as $$
declare g uuid := public.ah__host(p_token);
begin update public.ah_games set state = coalesce(p_state, '{}'::jsonb), updated_at = now() where id = g; end $$;

create or replace function public.ah_host_add_player(p_token text, p_slot text, p_data jsonb) returns text
language plpgsql volatile security definer set search_path = '' as $$
declare g uuid := public.ah__host(p_token); c text := public.ah__code();
begin
  delete from public.ah_players where game_id = g and slot = p_slot;
  insert into public.ah_players(game_id, slot, code, data) values (g, left(p_slot, 20), c, coalesce(p_data, '{}'::jsonb));
  return c;
end $$;

create or replace function public.ah_host_remove_player(p_token text, p_slot text) returns void
language plpgsql volatile security definer set search_path = '' as $$
declare g uuid := public.ah__host(p_token);
begin delete from public.ah_players where game_id = g and slot = p_slot; end $$;

create or replace function public.ah_host_patch_player(p_token text, p_slot text, p_patch jsonb) returns void
language plpgsql volatile security definer set search_path = '' as $$
declare g uuid := public.ah__host(p_token);
begin update public.ah_players set data = public.ah__merge(data, p_patch) where game_id = g and slot = p_slot; end $$;

create or replace function public.ah_host_delta(p_token text, p_slot text, p_field text, p_delta int) returns void
language plpgsql volatile security definer set search_path = '' as $$
declare g uuid := public.ah__host(p_token);
begin
  if p_field not in ('res','clues','dmg','hor') then raise exception 'campo non valido'; end if;
  update public.ah_players set data = jsonb_set(data, array[p_field], to_jsonb(greatest(0, coalesce((data->>p_field)::int, 0) + p_delta)))
  where game_id = g and slot = p_slot;
end $$;

-- ===== API del giocatore =====
create or replace function public.ah_player_get(p_code text) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare p record;
begin
  select * into p from public.ah__player(p_code);
  return public.ah__pack(p.g, false) || jsonb_build_object('slot', p.s);
end $$;

create or replace function public.ah_player_patch(p_code text, p_patch jsonb) returns void
language plpgsql volatile security definer set search_path = '' as $$
declare p record;
begin
  select * into p from public.ah__player(p_code);
  update public.ah_players set data = public.ah__merge(data, p_patch) where game_id = p.g and slot = p.s;
end $$;

create or replace function public.ah_player_delta(p_code text, p_field text, p_delta int) returns void
language plpgsql volatile security definer set search_path = '' as $$
declare p record;
begin
  if p_field not in ('res','clues','dmg','hor') then raise exception 'campo non valido'; end if;
  select * into p from public.ah__player(p_code);
  update public.ah_players set data = jsonb_set(data, array[p_field], to_jsonb(greatest(0, coalesce((data->>p_field)::int, 0) + p_delta)))
  where game_id = p.g and slot = p.s;
end $$;

-- ===== condivise (guida o giocatore) =====
create or replace function public.ah_doom(p_auth text, p_field text, p_delta int) returns void
language plpgsql volatile security definer set search_path = '' as $$
declare g uuid := public.ah__any(p_auth);
begin
  if p_field = 'doom' then update public.ah_games set doom = greatest(0, doom + p_delta), updated_at = now() where id = g;
  elsif p_field = 'odoom' then update public.ah_games set odoom = greatest(0, odoom + p_delta), updated_at = now() where id = g;
  else raise exception 'campo non valido'; end if;
end $$;

create or replace function public.ah_draw(p_auth text, p_tok text, p_who text) returns void
language plpgsql volatile security definer set search_path = '' as $$
declare g uuid := public.ah__any(p_auth);
begin
  update public.ah_games set draw = jsonb_build_object('t', left(p_tok, 12), 'who', left(coalesce(p_who,''), 60),
    'ts', extract(epoch from now())*1000, 'n', coalesce((draw->>'n')::int, 0) + 1), updated_at = now() where id = g;
end $$;

create or replace function public.ah_log(p_auth text, p_who text, p_text text) returns void
language plpgsql volatile security definer set search_path = '' as $$
declare g uuid := public.ah__any(p_auth);
begin
  insert into public.ah_log(game_id, who, text) values (g, left(coalesce(p_who,''), 60), left(p_text, 300));
  delete from public.ah_log where game_id = g and id < (select min(id) from (select id from public.ah_log where game_id = g order by id desc limit 200) t);
end $$;

-- ===== permessi: solo le funzioni pubbliche sono richiamabili =====
revoke execute on function public.ah__merge(jsonb, jsonb), public.ah__hash(text), public.ah__host(text), public.ah__player(text),
  public.ah__any(text), public.ah__code(), public.ah__pack(uuid, boolean),
  public.ah_create_game(jsonb, int, int), public.ah_host_get(text), public.ah_host_set_state(text, jsonb),
  public.ah_host_add_player(text, text, jsonb), public.ah_host_remove_player(text, text), public.ah_host_patch_player(text, text, jsonb),
  public.ah_host_delta(text, text, text, int), public.ah_player_get(text), public.ah_player_patch(text, jsonb),
  public.ah_player_delta(text, text, int), public.ah_doom(text, text, int), public.ah_draw(text, text, text), public.ah_log(text, text, text)
  from public, anon, authenticated;
grant execute on function public.ah_create_game(jsonb, int, int), public.ah_host_get(text), public.ah_host_set_state(text, jsonb),
  public.ah_host_add_player(text, text, jsonb), public.ah_host_remove_player(text, text), public.ah_host_patch_player(text, text, jsonb),
  public.ah_host_delta(text, text, text, int), public.ah_player_get(text), public.ah_player_patch(text, jsonb),
  public.ah_player_delta(text, text, int), public.ah_doom(text, text, int), public.ah_draw(text, text, text), public.ah_log(text, text, text)
  to anon, authenticated;

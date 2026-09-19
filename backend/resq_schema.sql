-- =====================================================================
-- ResQ Command  ·  Gujarat SDMA  ·  PostgreSQL 16+ / PostGIS 3.4+
-- Production database schema
-- Derived strictly from the Next.js frontend in RESQ.zip:
--   app/page.tsx, app/dashboard, app/command-room, app/analytics, app/report
--   components/{tactical-map, live-feed-panel, incident-log-feed,
--               report/report-form, dashboard, command-room, analytics,
--               ai-assistant, ResQCopilot}
--   lib/mock-data.ts  (authoritative shape of every UI object)
-- =====================================================================

\set ON_ERROR_STOP on

-- ---------------------------------------------------------------------
-- 0. EXTENSIONS
-- ---------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS postgis;          -- geometry types + spatial index
CREATE EXTENSION IF NOT EXISTS btree_gist;       -- composite GiST (spatial + scalar)
CREATE EXTENSION IF NOT EXISTS pg_trgm;          -- fuzzy text match for de-duplication
CREATE EXTENSION IF NOT EXISTS citext;           -- case-insensitive email
CREATE EXTENSION IF NOT EXISTS pgcrypto;         -- gen_random_uuid(), digest()

CREATE SCHEMA IF NOT EXISTS resq;
SET search_path = resq, public;


-- ---------------------------------------------------------------------
-- 1. ENUM TYPES
--    Every enum below is a literal transcription of a TypeScript union
--    or a hard-coded array found in the frontend.
-- ---------------------------------------------------------------------

-- lib/mock-data.ts :: IncidentStatus
CREATE TYPE incident_status AS ENUM ('new', 'dispatched', 'in-progress', 'resolved');

-- lib/mock-data.ts :: Severity
CREATE TYPE severity_level AS ENUM ('low', 'moderate', 'high', 'critical');

-- lib/mock-data.ts :: ResourceUnit['status']
CREATE TYPE resource_status AS ENUM ('available', 'deployed', 'returning', 'maintenance');

-- lib/mock-data.ts :: FeedEntry['tone']  (incident-log-feed.tsx toneLabel)
CREATE TYPE log_tone AS ENUM ('ingest', 'classify', 'merge', 'dispatch', 'resolve', 'alert');

-- lib/mock-data.ts :: ChatMessage['role'] + system turns for the FastAPI layer
CREATE TYPE chat_role AS ENUM ('user', 'assistant', 'system');

-- Inferred: lifecycle of a raw signal before/after it joins an incident.
CREATE TYPE report_status AS ENUM ('received', 'classified', 'merged', 'rejected', 'spam');

-- Inferred from incident-log-feed ("Resources dispatched", "Field officer
-- acknowledged assignment", "ETA computed") + dashboard resource states.
CREATE TYPE dispatch_status AS ENUM
  ('assigned', 'acknowledged', 'en_route', 'on_scene', 'cleared', 'cancelled');

-- Inferred from ResQCopilot.jsx "NEAREST FACILITIES" (hospitals, ICU, burns unit)
CREATE TYPE facility_kind AS ENUM
  ('hospital', 'phc', 'fire_station', 'police_station', 'relief_shelter', 'ndrf_base');

CREATE TYPE actor_kind AS ENUM ('system', 'ai', 'user');

CREATE TYPE notification_channel AS ENUM ('in_app', 'sms', 'email', 'push', 'radio');


-- ---------------------------------------------------------------------
-- 2. SHARED TRIGGER FUNCTIONS
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;


-- =====================================================================
-- 3. AUTHENTICATION & AUTHORISATION  (JWT)
-- =====================================================================

-- 3.1 roles ------------------------------------------------------------
-- The UI exposes four distinct privilege surfaces: a PUBLIC report form,
-- a coordinator Dashboard (assign/dispatch), a read-only Command Room wall
-- and an Analytics page. Those map to named roles.
CREATE TABLE roles (
  id            SMALLSERIAL PRIMARY KEY,
  code          TEXT NOT NULL UNIQUE
                  CHECK (code ~ '^[a-z_]{3,40}$'),
  display_name  TEXT NOT NULL,
  description   TEXT,
  is_system     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3.2 permissions ------------------------------------------------------
CREATE TABLE permissions (
  id            SMALLSERIAL PRIMARY KEY,
  code          TEXT NOT NULL UNIQUE
                  CHECK (code ~ '^[a-z_]+:[a-z_]+$'),   -- e.g. incident:dispatch
  description   TEXT NOT NULL
);

CREATE TABLE role_permissions (
  role_id       SMALLINT NOT NULL REFERENCES roles(id)        ON DELETE CASCADE,
  permission_id SMALLINT NOT NULL REFERENCES permissions(id)  ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

-- 3.3 agencies ---------------------------------------------------------
-- Resource codes in mock-data belong to visibly different organisations
-- (Fire Tender, Ambulance/108, NDRF Team, Coast Guard, Highway Patrol).
-- Without this table, "which agency owns FT-12" is unanswerable.
CREATE TABLE agencies (
  id            SMALLSERIAL PRIMARY KEY,
  code          TEXT NOT NULL UNIQUE,
  name          TEXT NOT NULL,
  contact_phone TEXT,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE
);

-- 3.4 districts --------------------------------------------------------
-- heroStats says "Districts online · 33" -> all 33 Gujarat districts are
-- rows; `is_online` is the flag that KPI counts.
-- tactical-map.tsx districtNodes gives the stylised wall-map coordinates.
CREATE TABLE districts (
  id            SMALLSERIAL PRIMARY KEY,
  code          TEXT NOT NULL UNIQUE,
  name          TEXT NOT NULL UNIQUE,
  state         TEXT NOT NULL DEFAULT 'Gujarat',
  boundary      geometry(MultiPolygon, 4326),
  centroid      geometry(Point, 4326) NOT NULL,
  -- tactical-map.tsx renders markers at left:%/top:% on a 0-100 canvas
  map_x         NUMERIC(5,2) CHECK (map_x BETWEEN 0 AND 100),
  map_y         NUMERIC(5,2) CHECK (map_y BETWEEN 0 AND 100),
  population    INTEGER CHECK (population >= 0),
  is_online     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3.5 wards ------------------------------------------------------------
-- INC-2026-0416 description: "Evacuation ... in Sayajipura ward".
-- Sub-district granularity is already present in the product's language.
CREATE TABLE wards (
  id            SERIAL PRIMARY KEY,
  district_id   SMALLINT NOT NULL REFERENCES districts(id) ON DELETE RESTRICT,
  name          TEXT NOT NULL,
  boundary      geometry(MultiPolygon, 4326),
  UNIQUE (district_id, name)
);

-- 3.6 users ------------------------------------------------------------
CREATE TABLE users (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email               CITEXT UNIQUE
                        CHECK (email IS NULL OR email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  phone               TEXT UNIQUE
                        CHECK (phone IS NULL OR phone ~ '^\+?[0-9]{10,15}$'),
  full_name           TEXT NOT NULL CHECK (length(btrim(full_name)) > 0),
  password_hash       TEXT,                       -- argon2id / bcrypt; NULL = SSO-only
  employee_code       TEXT UNIQUE,
  agency_id           SMALLINT REFERENCES agencies(id)  ON DELETE SET NULL,
  home_district_id    SMALLINT REFERENCES districts(id) ON DELETE SET NULL,
  is_active           BOOLEAN NOT NULL DEFAULT TRUE,
  is_email_verified   BOOLEAN NOT NULL DEFAULT FALSE,
  mfa_secret          TEXT,
  mfa_enabled         BOOLEAN NOT NULL DEFAULT FALSE,
  failed_login_count  SMALLINT NOT NULL DEFAULT 0 CHECK (failed_login_count >= 0),
  locked_until        TIMESTAMPTZ,
  last_login_at       TIMESTAMPTZ,
  password_changed_at TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- a login identity must exist on at least one channel
  CONSTRAINT users_identity_present CHECK (email IS NOT NULL OR phone IS NOT NULL)
);
CREATE TRIGGER trg_users_updated BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 3.7 user_roles  (M:N, scoped per district) ---------------------------
-- A district coordinator must be scoped: they may dispatch in Surat but
-- only read Rajkot. district_id NULL = state-wide scope.
CREATE TABLE user_roles (
  id            BIGSERIAL PRIMARY KEY,
  user_id       UUID     NOT NULL REFERENCES users(id)     ON DELETE CASCADE,
  role_id       SMALLINT NOT NULL REFERENCES roles(id)     ON DELETE CASCADE,
  district_id   SMALLINT          REFERENCES districts(id) ON DELETE CASCADE,
  granted_by    UUID              REFERENCES users(id)     ON DELETE SET NULL,
  granted_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- NULLS NOT DISTINCT (PG15+) makes the state-wide grant (district_id
  -- NULL) collide with itself, so a role can be granted only once per scope.
  CONSTRAINT uq_user_role_scope
    UNIQUE NULLS NOT DISTINCT (user_id, role_id, district_id)
);

-- 3.8 refresh_tokens  (JWT rotation + revocation) ----------------------
CREATE TABLE refresh_tokens (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash    BYTEA NOT NULL UNIQUE,            -- sha256 of the opaque token, never the token
  jti           UUID  NOT NULL UNIQUE,            -- mirrors the JWT `jti` claim
  issued_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at    TIMESTAMPTZ NOT NULL,
  revoked_at    TIMESTAMPTZ,
  replaced_by   UUID REFERENCES refresh_tokens(id) ON DELETE SET NULL,
  user_agent    TEXT,
  ip_address    INET,
  CONSTRAINT refresh_token_window CHECK (expires_at > issued_at)
);

-- 3.9 access_token_denylist -------------------------------------------
-- Short-lived access JWTs are stateless; forced logout needs a denylist
-- keyed on jti until natural expiry.
CREATE TABLE access_token_denylist (
  jti           UUID PRIMARY KEY,
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expires_at    TIMESTAMPTZ NOT NULL,
  reason        TEXT,
  revoked_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3.10 password_reset_tokens ------------------------------------------
CREATE TABLE password_reset_tokens (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash    BYTEA NOT NULL UNIQUE,
  expires_at    TIMESTAMPTZ NOT NULL,
  used_at       TIMESTAMPTZ
);

-- 3.11 auth_events  (security audit) -----------------------------------
CREATE TABLE auth_events (
  id            BIGSERIAL PRIMARY KEY,
  user_id       UUID REFERENCES users(id) ON DELETE SET NULL,
  email_tried   CITEXT,
  event         TEXT NOT NULL
                  CHECK (event IN ('login_success','login_failure','logout',
                                   'token_refresh','password_reset','locked')),
  ip_address    INET,
  user_agent    TEXT,
  occurred_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3.12 audit_log  (who changed what) -----------------------------------
-- The landing page promises a "full audit trail" for merges and the
-- Dashboard performs state-changing dispatch actions.
CREATE TABLE audit_log (
  id            BIGSERIAL PRIMARY KEY,
  actor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  actor         actor_kind NOT NULL DEFAULT 'user',
  action        TEXT NOT NULL,                    -- 'incident.dispatch'
  entity_type   TEXT NOT NULL,                    -- 'incident'
  entity_id     TEXT NOT NULL,
  before        JSONB,
  after         JSONB,
  ip_address    INET,
  occurred_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- =====================================================================
-- 4. REFERENCE / CONFIGURATION TABLES
-- =====================================================================

-- 4.1 incident_types ---------------------------------------------------
-- report-form.tsx `types[]` and `typeBaseScore` are hard-coded in the
-- client. They are tuning parameters and MUST live in the database so the
-- FastAPI scorer and the UI agree without a redeploy.
CREATE TABLE incident_types (
  id            SMALLSERIAL PRIMARY KEY,
  code          TEXT NOT NULL UNIQUE,             -- 'gas_leak'
  label         TEXT NOT NULL UNIQUE,             -- 'Gas Leak'  (exact UI string)
  base_score    SMALLINT NOT NULL CHECK (base_score BETWEEN 0 AND 100),
  icon          TEXT,
  display_order SMALLINT NOT NULL DEFAULT 0,
  is_active     BOOLEAN  NOT NULL DEFAULT TRUE
);

-- 4.2 report_channels --------------------------------------------------
-- Landing page: "112 calls, SMS, social posts and field radio"; incident
-- reporterType values embed the channel: "Citizen (SMS)", "Citizen (App)".
CREATE TABLE report_channels (
  id            SMALLSERIAL PRIMARY KEY,
  code          TEXT NOT NULL UNIQUE,             -- 'sms','app','call','radio','iot','web','social'
  label         TEXT NOT NULL,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE
);

-- 4.3 reporter_types ---------------------------------------------------
-- report-form.tsx `reporterTypes[]` plus the scorer's source weighting:
--   if (reporter === 'Emergency Services' || 'Field Officer') s += 5
CREATE TABLE reporter_types (
  id            SMALLSERIAL PRIMARY KEY,
  code          TEXT NOT NULL UNIQUE,
  label         TEXT NOT NULL UNIQUE,             -- 'Field Officer'
  trust_weight  SMALLINT NOT NULL DEFAULT 0 CHECK (trust_weight BETWEEN -20 AND 20),
  is_official   BOOLEAN NOT NULL DEFAULT FALSE,
  display_order SMALLINT NOT NULL DEFAULT 0
);

-- 4.4 scoring_profiles -------------------------------------------------
-- The whole `score` useMemo in report-form.tsx, versioned. Analytics must
-- be able to say "this incident was scored 89 under profile v1".
CREATE TABLE scoring_profiles (
  id                    SMALLSERIAL PRIMARY KEY,
  version               TEXT NOT NULL UNIQUE,     -- 'v1.0-client-parity'
  keyword_weight        SMALLINT NOT NULL DEFAULT 6,   -- hits * 6
  scale_tier1_min       SMALLINT NOT NULL DEFAULT 2,   -- >=2  -> +4
  scale_tier1_bonus     SMALLINT NOT NULL DEFAULT 4,
  scale_tier2_min       SMALLINT NOT NULL DEFAULT 4,   -- >=4  -> +10
  scale_tier2_bonus     SMALLINT NOT NULL DEFAULT 10,
  scale_tier3_min       SMALLINT NOT NULL DEFAULT 10,  -- >=10 -> +18
  scale_tier3_bonus     SMALLINT NOT NULL DEFAULT 18,
  long_text_min_chars   SMALLINT NOT NULL DEFAULT 120, -- length>120 -> +3
  long_text_bonus       SMALLINT NOT NULL DEFAULT 3,
  score_floor           SMALLINT NOT NULL DEFAULT 8,
  score_ceiling         SMALLINT NOT NULL DEFAULT 100,
  band_critical_min     SMALLINT NOT NULL DEFAULT 80,  -- severityFromScore()
  band_high_min         SMALLINT NOT NULL DEFAULT 60,
  band_moderate_min     SMALLINT NOT NULL DEFAULT 35,
  is_active             BOOLEAN NOT NULL DEFAULT FALSE,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT scoring_bands_ordered
    CHECK (band_critical_min > band_high_min AND band_high_min > band_moderate_min),
  CONSTRAINT scoring_range_valid CHECK (score_ceiling > score_floor)
);
-- exactly one active profile at a time
CREATE UNIQUE INDEX uq_scoring_profile_active ON scoring_profiles((is_active)) WHERE is_active;

-- 4.5 severity_keywords ------------------------------------------------
-- report-form.tsx `escalationKeywords[]`. The UI shows "N detected" live,
-- so the list must be queryable, not compiled in.
CREATE TABLE severity_keywords (
  id                 SERIAL PRIMARY KEY,
  scoring_profile_id SMALLINT NOT NULL REFERENCES scoring_profiles(id) ON DELETE CASCADE,
  keyword            TEXT NOT NULL CHECK (keyword = lower(keyword)),
  weight             SMALLINT NOT NULL DEFAULT 6 CHECK (weight > 0),
  language           TEXT NOT NULL DEFAULT 'en',
  UNIQUE (scoring_profile_id, keyword, language)
);

-- 4.6 resource_types ---------------------------------------------------
-- mock-data resources[].type — a repeating text value on every unit row.
-- Promoting it removes the 3NF transitive dependency and gives the
-- Copilot a place to answer "which unit type handles a chlorine leak".
CREATE TABLE resource_types (
  id                 SMALLSERIAL PRIMARY KEY,
  code               TEXT NOT NULL UNIQUE,        -- 'fire_tender'
  label              TEXT NOT NULL UNIQUE,        -- 'Fire Tender'
  code_prefix        TEXT NOT NULL UNIQUE,        -- 'FT'  -> unit codes FT-12
  default_crew_size  SMALLINT CHECK (default_crew_size > 0),
  avg_speed_kmph     NUMERIC(5,2) NOT NULL DEFAULT 40.0 CHECK (avg_speed_kmph > 0),
  is_active          BOOLEAN NOT NULL DEFAULT TRUE
);

-- 4.7 incident_type_resource_matrix (M:N) ------------------------------
-- Copilot: "Dispatch a 3rd tender", "3 ambulances available within 10 km".
-- Recommending *what* to send requires an explicit capability matrix.
CREATE TABLE incident_type_resource_matrix (
  incident_type_id   SMALLINT NOT NULL REFERENCES incident_types(id) ON DELETE CASCADE,
  resource_type_id   SMALLINT NOT NULL REFERENCES resource_types(id) ON DELETE CASCADE,
  recommended_units  SMALLINT NOT NULL DEFAULT 1 CHECK (recommended_units > 0),
  priority           SMALLINT NOT NULL DEFAULT 1 CHECK (priority BETWEEN 1 AND 5),
  PRIMARY KEY (incident_type_id, resource_type_id)
);


-- =====================================================================
-- 5. CORE OPERATIONAL TABLES
-- =====================================================================

-- 5.1 incidents --------------------------------------------------------
-- The canonical, de-duplicated event. Backs the tactical map, the
-- dashboard queue + detail pane, the command-room priority board and the
-- live feed panel.
CREATE SEQUENCE incident_ref_seq;

CREATE TABLE incidents (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- 'INC-2026-0417' — the code rendered in every list, tooltip and card
  reference_code      TEXT NOT NULL UNIQUE
                        CHECK (reference_code ~ '^INC-[0-9]{4}-[0-9]{4,6}$'),

  incident_type_id    SMALLINT NOT NULL REFERENCES incident_types(id) ON DELETE RESTRICT,
  title               TEXT NOT NULL CHECK (length(btrim(title)) BETWEEN 5 AND 200),
  description         TEXT NOT NULL CHECK (length(btrim(description)) > 0),

  district_id         SMALLINT NOT NULL REFERENCES districts(id) ON DELETE RESTRICT,
  ward_id             INTEGER  REFERENCES wards(id) ON DELETE SET NULL,
  location            geometry(Point, 4326) NOT NULL,
  location_text       TEXT,                       -- "Pandesara GIDC, near gate 3"
  geocode_confidence  NUMERIC(4,3) CHECK (geocode_confidence BETWEEN 0 AND 1),

  -- '21.1702° N, 72.8311° E' is a *display* of `location`; derived, never stored twice
  coord_label         TEXT GENERATED ALWAYS AS (
                        round(abs(ST_Y(location))::numeric, 4)::text || '° ' ||
                        CASE WHEN ST_Y(location) >= 0 THEN 'N' ELSE 'S' END || ', ' ||
                        round(abs(ST_X(location))::numeric, 4)::text || '° ' ||
                        CASE WHEN ST_X(location) >= 0 THEN 'E' ELSE 'W' END
                      ) STORED,

  -- tactical-map.tsx expects x/y in 0-100 on a Gujarat bbox canvas.
  -- Projected here so the API never ships two sources of truth.
  map_x               NUMERIC(6,2) GENERATED ALWAYS AS
                        (round((((ST_X(location) - 68.10) / 6.40) * 100)::numeric, 2)) STORED,
  map_y               NUMERIC(6,2) GENERATED ALWAYS AS
                        (round((((24.80 - ST_Y(location)) / 4.70) * 100)::numeric, 2)) STORED,

  severity_score      SMALLINT NOT NULL CHECK (severity_score BETWEEN 0 AND 100),
  -- severityFromScore() reproduced as a generated column: the label can
  -- never drift from the score it is derived from.
  severity            severity_level GENERATED ALWAYS AS (
                        CASE
                          WHEN severity_score >= 80 THEN 'critical'::severity_level
                          WHEN severity_score >= 60 THEN 'high'::severity_level
                          WHEN severity_score >= 35 THEN 'moderate'::severity_level
                          ELSE 'low'::severity_level
                        END
                      ) STORED,

  status              incident_status NOT NULL DEFAULT 'new',
  people_affected     SMALLINT CHECK (people_affected BETWEEN 0 AND 100000),

  -- denormalised counter behind "Merged reports · 7 signals" (see trigger)
  merged_report_count INTEGER NOT NULL DEFAULT 0 CHECK (merged_report_count >= 0),

  primary_report_id   UUID,                       -- FK added after `reports` exists
  merged_into_id      UUID REFERENCES incidents(id) ON DELETE SET NULL,

  owner_user_id       UUID REFERENCES users(id) ON DELETE SET NULL,   -- coordinator
  lead_agency_id      SMALLINT REFERENCES agencies(id) ON DELETE SET NULL,

  reported_at         TIMESTAMPTZ NOT NULL,       -- '09:41:03' on the feed
  ingested_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  first_dispatch_at   TIMESTAMPTZ,                -- drives "Avg response 9.7 min"
  resolved_at         TIMESTAMPTZ,
  closed_at           TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT incident_not_self_merged  CHECK (merged_into_id IS DISTINCT FROM id),
  CONSTRAINT incident_resolved_consistent
    CHECK ((status = 'resolved') = (resolved_at IS NOT NULL)),
  CONSTRAINT incident_dispatch_after_report
    CHECK (first_dispatch_at IS NULL OR first_dispatch_at >= reported_at),
  CONSTRAINT incident_resolved_after_report
    CHECK (resolved_at IS NULL OR resolved_at >= reported_at),
  -- a dispatched/in-progress incident must have a dispatch timestamp
  CONSTRAINT incident_status_needs_dispatch
    CHECK (status IN ('new') OR first_dispatch_at IS NOT NULL)
);
CREATE TRIGGER trg_incidents_updated BEFORE UPDATE ON incidents
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 5.2 reports ----------------------------------------------------------
-- One row per *raw inbound signal*. This is the table the /report page
-- writes to. "7 duplicate reports merged into INC-2026-0417" means seven
-- rows here share one incident_id. Reports are never deleted — the merge
-- audit trail depends on them.
CREATE TABLE reports (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reference_code      TEXT NOT NULL UNIQUE,       -- 'RPT-2026-000431'

  incident_id         UUID REFERENCES incidents(id) ON DELETE SET NULL,
  status              report_status NOT NULL DEFAULT 'received',

  -- report-form.tsx fields ------------------------------------------
  incident_type_id    SMALLINT NOT NULL REFERENCES incident_types(id) ON DELETE RESTRICT,
  district_id         SMALLINT NOT NULL REFERENCES districts(id)      ON DELETE RESTRICT,
  ward_id             INTEGER  REFERENCES wards(id) ON DELETE SET NULL,
  reporter_type_id    SMALLINT NOT NULL REFERENCES reporter_types(id) ON DELETE RESTRICT,
  channel_id          SMALLINT NOT NULL REFERENCES report_channels(id) ON DELETE RESTRICT,
  location_text       TEXT,                       -- "Location / landmark" input
  people_affected     SMALLINT NOT NULL DEFAULT 1
                        CHECK (people_affected BETWEEN 1 AND 50),  -- slider min/max
  description         TEXT NOT NULL CHECK (length(btrim(description)) > 0),

  -- geocoding: the form collects no GPS, so this is NULLable until the
  -- pipeline resolves the landmark ("Geo-tagged:" line in the feed)
  location            geometry(Point, 4326),
  geocode_confidence  NUMERIC(4,3) CHECK (geocode_confidence BETWEEN 0 AND 1),
  geocoded_at         TIMESTAMPTZ,

  -- reporter identity: the form is public, so a user is optional
  reporter_user_id    UUID REFERENCES users(id) ON DELETE SET NULL,
  reporter_name       TEXT,
  reporter_phone      TEXT CHECK (reporter_phone IS NULL OR reporter_phone ~ '^\+?[0-9]{10,15}$'),
  reporter_ip         INET,
  is_anonymous        BOOLEAN NOT NULL DEFAULT TRUE,

  -- client-side preview score shown on the "Live AI estimate" dial
  client_score_preview SMALLINT CHECK (client_score_preview BETWEEN 0 AND 100),

  received_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  classified_at       TIMESTAMPTZ,
  merged_at           TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT report_merged_has_incident
    CHECK (status <> 'merged' OR incident_id IS NOT NULL),
  CONSTRAINT report_geocode_pair
    CHECK ((location IS NULL) = (geocoded_at IS NULL)),
  CONSTRAINT report_identity_if_named
    CHECK (is_anonymous OR reporter_user_id IS NOT NULL OR reporter_phone IS NOT NULL)
);
CREATE TRIGGER trg_reports_updated BEFORE UPDATE ON reports
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE incidents
  ADD CONSTRAINT incidents_primary_report_fk
  FOREIGN KEY (primary_report_id) REFERENCES reports(id) ON DELETE SET NULL;

-- 5.3 severity_assessments ---------------------------------------------
-- The "Live AI estimate" sidebar breaks the score into Base risk / Scale
-- factor / Signal keywords / Source weight. Storing only the final number
-- would make that panel — and any model audit — unreproducible.
CREATE TABLE severity_assessments (
  id                  BIGSERIAL PRIMARY KEY,
  report_id           UUID REFERENCES reports(id)   ON DELETE CASCADE,
  incident_id         UUID REFERENCES incidents(id) ON DELETE CASCADE,
  scoring_profile_id  SMALLINT NOT NULL REFERENCES scoring_profiles(id) ON DELETE RESTRICT,

  base_score          SMALLINT NOT NULL CHECK (base_score BETWEEN 0 AND 100),
  keyword_bonus       SMALLINT NOT NULL DEFAULT 0 CHECK (keyword_bonus >= 0),
  scale_bonus         SMALLINT NOT NULL DEFAULT 0 CHECK (scale_bonus  >= 0),
  source_bonus        SMALLINT NOT NULL DEFAULT 0,
  length_bonus        SMALLINT NOT NULL DEFAULT 0 CHECK (length_bonus >= 0),
  model_adjustment    SMALLINT NOT NULL DEFAULT 0,          -- ML delta over the rule base
  final_score         SMALLINT NOT NULL CHECK (final_score BETWEEN 0 AND 100),

  matched_keywords    TEXT[] NOT NULL DEFAULT '{}',
  confidence          NUMERIC(4,3) CHECK (confidence BETWEEN 0 AND 1),
  model_name          TEXT,
  model_version       TEXT,
  computed_at         TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT assessment_targets_one
    CHECK (num_nonnulls(report_id, incident_id) >= 1)
);

-- 5.4 incident_merges  (audit trail) -----------------------------------
-- Landing page: "Duplicate signals auto-merged with full audit trail".
-- Records both report->incident absorption and incident->incident merges.
CREATE TABLE incident_merges (
  id                  BIGSERIAL PRIMARY KEY,
  target_incident_id  UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
  source_report_id    UUID REFERENCES reports(id)   ON DELETE CASCADE,
  source_incident_id  UUID REFERENCES incidents(id) ON DELETE CASCADE,
  method              TEXT NOT NULL DEFAULT 'auto_spatiotemporal'
                        CHECK (method IN ('auto_spatiotemporal','auto_text_similarity',
                                          'manual','api')),
  similarity_score    NUMERIC(4,3) CHECK (similarity_score BETWEEN 0 AND 1),
  distance_m          NUMERIC(10,2) CHECK (distance_m >= 0),
  time_delta_seconds  INTEGER,
  decided_by_user_id  UUID REFERENCES users(id) ON DELETE SET NULL,
  decided_by          actor_kind NOT NULL DEFAULT 'ai',
  reason              TEXT,
  is_reverted         BOOLEAN NOT NULL DEFAULT FALSE,
  reverted_at         TIMESTAMPTZ,
  occurred_at         TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT merge_has_exactly_one_source
    CHECK (num_nonnulls(source_report_id, source_incident_id) = 1),
  CONSTRAINT merge_not_circular
    CHECK (source_incident_id IS NULL OR source_incident_id <> target_incident_id)
);

-- 5.5 incident_status_history ------------------------------------------
-- Needed for the analytics "Response time trend" and resolution rate;
-- the current `status` column alone cannot answer "when did it change".
CREATE TABLE incident_status_history (
  id                  BIGSERIAL PRIMARY KEY,
  incident_id         UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
  from_status         incident_status,
  to_status           incident_status NOT NULL,
  changed_by_user_id  UUID REFERENCES users(id) ON DELETE SET NULL,
  changed_by          actor_kind NOT NULL DEFAULT 'system',
  note                TEXT,
  changed_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT status_actually_changed CHECK (from_status IS DISTINCT FROM to_status)
);

-- 5.6 resources --------------------------------------------------------
-- mock-data `resources[]`: the dashboard "Resource status · 12 units" grid
-- and the command-room DEPLOYED / AVAILABLE wall counters.
CREATE TABLE resources (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code                TEXT NOT NULL UNIQUE
                        CHECK (code ~ '^[A-Z]{2,5}-[0-9]{1,3}$'),   -- 'FT-12','NDRF-2'
  resource_type_id    SMALLINT NOT NULL REFERENCES resource_types(id) ON DELETE RESTRICT,
  agency_id           SMALLINT REFERENCES agencies(id) ON DELETE SET NULL,
  home_district_id    SMALLINT NOT NULL REFERENCES districts(id) ON DELETE RESTRICT,
  station_facility_id UUID,                       -- FK added after `facilities`
  status              resource_status NOT NULL DEFAULT 'available',
  crew_size           SMALLINT NOT NULL CHECK (crew_size BETWEEN 0 AND 100),
  capacity            SMALLINT CHECK (capacity >= 0),

  -- live AVL position: the Copilot answers "within 10 km", "6 min ETA"
  current_location    geometry(Point, 4326),
  heading_deg         NUMERIC(5,2) CHECK (heading_deg >= 0 AND heading_deg < 360),
  speed_kmph          NUMERIC(6,2) CHECK (speed_kmph >= 0),
  location_updated_at TIMESTAMPTZ,

  contact_phone       TEXT,
  radio_callsign      TEXT,
  is_active           BOOLEAN NOT NULL DEFAULT TRUE,
  in_service_since    DATE,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT resource_location_pair
    CHECK ((current_location IS NULL) = (location_updated_at IS NULL))
);
CREATE TRIGGER trg_resources_updated BEFORE UPDATE ON resources
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 5.7 resource_crew  (M:N users <-> resources) -------------------------
-- `crew: 6` is only a headcount. "Field officer acknowledged assignment"
-- requires knowing *which person* is on FT-12 right now.
CREATE TABLE resource_crew (
  id                  BIGSERIAL PRIMARY KEY,
  resource_id         UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
  user_id             UUID NOT NULL REFERENCES users(id)     ON DELETE CASCADE,
  role_on_unit        TEXT NOT NULL DEFAULT 'crew'
                        CHECK (role_on_unit IN ('lead','driver','crew','medic','specialist')),
  shift_start         TIMESTAMPTZ NOT NULL DEFAULT now(),
  shift_end           TIMESTAMPTZ,
  CONSTRAINT crew_shift_window CHECK (shift_end IS NULL OR shift_end > shift_start)
);

-- 5.8 resource_status_history ------------------------------------------
-- Powers the analytics "Resources" donut (Deployed/Available/Returning/
-- Maintenance) *over a time window*, which a single status column cannot.
CREATE TABLE resource_status_history (
  id                  BIGSERIAL PRIMARY KEY,
  resource_id         UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
  from_status         resource_status,
  to_status           resource_status NOT NULL,
  dispatch_id         UUID,                        -- FK added after `dispatches`
  changed_by_user_id  UUID REFERENCES users(id) ON DELETE SET NULL,
  changed_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT resource_status_actually_changed CHECK (from_status IS DISTINCT FROM to_status)
);

-- 5.9 resource_location_pings ------------------------------------------
-- High-volume AVL breadcrumb trail. Separated from `resources` so that a
-- 1 Hz GPS feed never bloats or locks the row every dashboard read hits.
CREATE TABLE resource_location_pings (
  id                  BIGSERIAL,
  resource_id         UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
  location            geometry(Point, 4326) NOT NULL,
  speed_kmph          NUMERIC(6,2) CHECK (speed_kmph >= 0),
  heading_deg         NUMERIC(5,2) CHECK (heading_deg >= 0 AND heading_deg < 360),
  recorded_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);

CREATE TABLE resource_location_pings_2026m01 PARTITION OF resource_location_pings
  FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE resource_location_pings_2026m02 PARTITION OF resource_location_pings
  FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE resource_location_pings_default PARTITION OF resource_location_pings DEFAULT;

-- 5.10 dispatches  (M:N incidents <-> resources) -----------------------
-- Resolves `assignedResources: string[]` into a proper relation. Every
-- chip in the Dashboard detail pane is one row here.
CREATE TABLE dispatches (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id         UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
  resource_id         UUID NOT NULL REFERENCES resources(id) ON DELETE RESTRICT,
  status              dispatch_status NOT NULL DEFAULT 'assigned',

  assigned_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  assigned_by         actor_kind NOT NULL DEFAULT 'user',

  -- "ETA computed — nearest tender 4 min"
  eta_minutes         NUMERIC(6,2) CHECK (eta_minutes >= 0),
  eta_computed_at     TIMESTAMPTZ,
  distance_m          NUMERIC(10,2) CHECK (distance_m >= 0),
  route               geometry(LineString, 4326),

  assigned_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  acknowledged_at     TIMESTAMPTZ,
  en_route_at         TIMESTAMPTZ,
  on_scene_at         TIMESTAMPTZ,
  cleared_at          TIMESTAMPTZ,
  cancelled_at        TIMESTAMPTZ,
  cancel_reason       TEXT,
  notes               TEXT,

  CONSTRAINT dispatch_ack_order      CHECK (acknowledged_at IS NULL OR acknowledged_at >= assigned_at),
  CONSTRAINT dispatch_onscene_order  CHECK (on_scene_at  IS NULL OR on_scene_at  >= assigned_at),
  CONSTRAINT dispatch_cleared_order  CHECK (cleared_at   IS NULL OR cleared_at   >= assigned_at),
  CONSTRAINT dispatch_cancel_pair
    CHECK ((status = 'cancelled') = (cancelled_at IS NOT NULL))
);

ALTER TABLE resource_status_history
  ADD CONSTRAINT resource_status_history_dispatch_fk
  FOREIGN KEY (dispatch_id) REFERENCES dispatches(id) ON DELETE SET NULL;

-- 5.11 incident_log_events ---------------------------------------------
-- The `resq://ingest-pipeline` terminal in incident-log-feed.tsx and the
-- bottom strip of the Command Room. Append-only, high volume -> partitioned.
CREATE TABLE incident_log_events (
  id                  BIGSERIAL,
  incident_id         UUID REFERENCES incidents(id) ON DELETE CASCADE,
  report_id           UUID REFERENCES reports(id)   ON DELETE SET NULL,
  dispatch_id         UUID REFERENCES dispatches(id) ON DELETE SET NULL,
  tone                log_tone NOT NULL,
  message             TEXT NOT NULL CHECK (length(btrim(message)) > 0),
  actor               actor_kind NOT NULL DEFAULT 'system',
  actor_user_id       UUID REFERENCES users(id) ON DELETE SET NULL,
  payload             JSONB NOT NULL DEFAULT '{}'::jsonb,
  occurred_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (id, occurred_at)
) PARTITION BY RANGE (occurred_at);

CREATE TABLE incident_log_events_2026m01 PARTITION OF incident_log_events
  FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE incident_log_events_2026m02 PARTITION OF incident_log_events
  FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE incident_log_events_default PARTITION OF incident_log_events DEFAULT;


-- =====================================================================
-- 6. FACILITIES  (inferred from ResQCopilot "NEAREST FACILITIES")
-- =====================================================================

-- 6.1 facilities -------------------------------------------------------
-- ResQCopilot.jsx answers with "Surat Civil Hospital (2.1 km, burns unit
-- available)" and "SMIMER (4.6 km, general ICU, 3 beds free)". Those are
-- distance + capability + live-bed queries: they need a spatial table.
CREATE TABLE facilities (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code                TEXT NOT NULL UNIQUE,
  name                TEXT NOT NULL,
  kind                facility_kind NOT NULL,
  district_id         SMALLINT NOT NULL REFERENCES districts(id) ON DELETE RESTRICT,
  ward_id             INTEGER REFERENCES wards(id) ON DELETE SET NULL,
  agency_id           SMALLINT REFERENCES agencies(id) ON DELETE SET NULL,
  location            geometry(Point, 4326) NOT NULL,
  address             TEXT,
  contact_phone       TEXT,
  total_beds          INTEGER CHECK (total_beds >= 0),
  available_beds      INTEGER CHECK (available_beds >= 0),
  capacity_persons    INTEGER CHECK (capacity_persons >= 0),   -- relief shelters
  is_active           BOOLEAN NOT NULL DEFAULT TRUE,
  capacity_updated_at TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT facility_beds_sane CHECK (total_beds IS NULL OR available_beds IS NULL
                                       OR available_beds <= total_beds)
);
CREATE TRIGGER trg_facilities_updated BEFORE UPDATE ON facilities
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE resources
  ADD CONSTRAINT resources_station_fk
  FOREIGN KEY (station_facility_id) REFERENCES facilities(id) ON DELETE SET NULL;

-- 6.2 capabilities + M:N map -------------------------------------------
CREATE TABLE capabilities (
  id                  SMALLSERIAL PRIMARY KEY,
  code                TEXT NOT NULL UNIQUE,        -- 'burns_unit','icu','trauma'
  label               TEXT NOT NULL
);

CREATE TABLE facility_capabilities (
  facility_id         UUID NOT NULL REFERENCES facilities(id)    ON DELETE CASCADE,
  capability_id       SMALLINT NOT NULL REFERENCES capabilities(id) ON DELETE CASCADE,
  units_available     SMALLINT CHECK (units_available >= 0),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (facility_id, capability_id)
);

-- 6.3 incident_facility_alerts -----------------------------------------
-- Copilot action #3: "Alert Surat Civil Hospital burns unit — expect 5-8
-- admissions." That is a tracked, acknowledgeable action, not a message.
CREATE TABLE incident_facility_alerts (
  id                  BIGSERIAL PRIMARY KEY,
  incident_id         UUID NOT NULL REFERENCES incidents(id)  ON DELETE CASCADE,
  facility_id         UUID NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
  expected_casualties SMALLINT CHECK (expected_casualties >= 0),
  message             TEXT,
  raised_by_user_id   UUID REFERENCES users(id) ON DELETE SET NULL,
  raised_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  acknowledged_at     TIMESTAMPTZ,
  UNIQUE (incident_id, facility_id)
);


-- =====================================================================
-- 7. GEOFENCES / CORDONS  (inferred from Copilot + gas-leak incident)
-- =====================================================================
-- INC-2026-0413: "Immediate cordon and evacuation advised within 500m
-- radius"; Copilot: "Establish 200m cordon". A radius around a point is a
-- polygon — PostGIS stores and queries it; the API cannot fake it.
CREATE TABLE incident_zones (
  id                  BIGSERIAL PRIMARY KEY,
  incident_id         UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
  zone_kind           TEXT NOT NULL
                        CHECK (zone_kind IN ('cordon','evacuation','hazard_plume',
                                             'flood_extent','search_sector')),
  radius_m            NUMERIC(10,2) CHECK (radius_m > 0),
  area                geometry(Polygon, 4326) NOT NULL,
  population_estimate INTEGER CHECK (population_estimate >= 0),
  is_active           BOOLEAN NOT NULL DEFAULT TRUE,
  created_by_user_id  UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  lifted_at           TIMESTAMPTZ
);


-- =====================================================================
-- 8. MEDIA ATTACHMENTS
-- =====================================================================
-- Not in the current form, but "Citizen (App)" is an existing reporter
-- channel and app reports carry photos. Modelled now so adding the input
-- later is a UI change, not a migration of the reports table.
CREATE TABLE media_attachments (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id           UUID REFERENCES reports(id)   ON DELETE CASCADE,
  incident_id         UUID REFERENCES incidents(id) ON DELETE CASCADE,
  storage_key         TEXT NOT NULL UNIQUE,         -- S3/MinIO object key
  mime_type           TEXT NOT NULL,
  byte_size           BIGINT NOT NULL CHECK (byte_size > 0),
  sha256              BYTEA,
  captured_location   geometry(Point, 4326),        -- EXIF GPS
  captured_at         TIMESTAMPTZ,
  uploaded_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  uploaded_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT media_attached_to_one CHECK (num_nonnulls(report_id, incident_id) >= 1)
);


-- =====================================================================
-- 9. RESQ COPILOT  (ai-assistant.tsx + ResQCopilot.jsx)
-- =====================================================================

-- 9.1 copilot_conversations --------------------------------------------
CREATE TABLE copilot_conversations (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID REFERENCES users(id) ON DELETE SET NULL,
  incident_id         UUID REFERENCES incidents(id) ON DELETE SET NULL,  -- pinned context
  title               TEXT,
  started_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_message_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_archived         BOOLEAN NOT NULL DEFAULT FALSE
);

-- 9.2 copilot_messages -------------------------------------------------
-- `label`/`meta` maps to "Summary · confidence 94%" and
-- "CROSS-INCIDENT CHECK · 2 DISTRICTS" rendered above each bubble.
CREATE TABLE copilot_messages (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id     UUID NOT NULL REFERENCES copilot_conversations(id) ON DELETE CASCADE,
  seq                 INTEGER NOT NULL CHECK (seq > 0),
  role                chat_role NOT NULL,
  label               TEXT,                        -- the mono meta line
  content             TEXT NOT NULL CHECK (length(btrim(content)) > 0),
  confidence          NUMERIC(4,3) CHECK (confidence BETWEEN 0 AND 1),
  model_name          TEXT,
  prompt_tokens       INTEGER CHECK (prompt_tokens >= 0),
  completion_tokens   INTEGER CHECK (completion_tokens >= 0),
  latency_ms          INTEGER CHECK (latency_ms >= 0),
  is_fallback         BOOLEAN NOT NULL DEFAULT FALSE,   -- rule-based path in ResQCopilot.jsx
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (conversation_id, seq)
);

-- 9.3 copilot_message_context ------------------------------------------
-- Header literally reads "context: 4 live incidents". Grounding must be
-- recorded to explain, later, what the model was looking at.
CREATE TABLE copilot_message_context (
  id                  BIGSERIAL PRIMARY KEY,
  message_id          UUID NOT NULL REFERENCES copilot_messages(id) ON DELETE CASCADE,
  incident_id         UUID REFERENCES incidents(id)  ON DELETE CASCADE,
  resource_id         UUID REFERENCES resources(id)  ON DELETE CASCADE,
  facility_id         UUID REFERENCES facilities(id) ON DELETE CASCADE,
  relevance           NUMERIC(4,3) CHECK (relevance BETWEEN 0 AND 1),
  CONSTRAINT context_references_one
    CHECK (num_nonnulls(incident_id, resource_id, facility_id) = 1)
);

-- 9.4 copilot_recommendations ------------------------------------------
-- The seeded "Recommended actions: 1..4" list is actionable state, not
-- chat text: a coordinator accepts or dismisses each line.
CREATE TABLE copilot_recommendations (
  id                  BIGSERIAL PRIMARY KEY,
  message_id          UUID REFERENCES copilot_messages(id) ON DELETE SET NULL,
  incident_id         UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
  ordinal             SMALLINT NOT NULL CHECK (ordinal > 0),
  action_text         TEXT NOT NULL,
  action_kind         TEXT CHECK (action_kind IN ('dispatch','pre_position','alert_facility',
                                                  'cordon','utility_cutoff','evacuate','other')),
  suggested_resource_id UUID REFERENCES resources(id)  ON DELETE SET NULL,
  suggested_facility_id UUID REFERENCES facilities(id) ON DELETE SET NULL,
  state               TEXT NOT NULL DEFAULT 'proposed'
                        CHECK (state IN ('proposed','accepted','dismissed','superseded')),
  decided_by_user_id  UUID REFERENCES users(id) ON DELETE SET NULL,
  decided_at          TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (incident_id, message_id, ordinal)
);


-- =====================================================================
-- 10. NOTIFICATIONS
-- =====================================================================
-- report-form success screen: "A coordinator has been notified."
CREATE TABLE notifications (
  id                  BIGSERIAL PRIMARY KEY,
  recipient_user_id   UUID REFERENCES users(id) ON DELETE CASCADE,
  incident_id         UUID REFERENCES incidents(id) ON DELETE CASCADE,
  dispatch_id         UUID REFERENCES dispatches(id) ON DELETE CASCADE,
  channel             notification_channel NOT NULL DEFAULT 'in_app',
  severity            severity_level,
  title               TEXT NOT NULL,
  body                TEXT,
  delivery_status     TEXT NOT NULL DEFAULT 'queued'
                        CHECK (delivery_status IN ('queued','sent','delivered','failed','read')),
  sent_at             TIMESTAMPTZ,
  read_at             TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- =====================================================================
-- 11. ANALYTICS SUPPORT
-- =====================================================================
-- The Analytics page needs 7-day aggregates. Recomputing them from
-- `incidents` on every page load is the wrong default at scale; a nightly
-- rollup table keeps history even after raw rows are archived.
CREATE TABLE daily_metrics (
  metric_date         DATE NOT NULL,
  district_id         SMALLINT NOT NULL REFERENCES districts(id) ON DELETE CASCADE,
  incident_type_id    SMALLINT NOT NULL REFERENCES incident_types(id) ON DELETE CASCADE,
  total_incidents     INTEGER NOT NULL DEFAULT 0 CHECK (total_incidents >= 0),
  critical_count      INTEGER NOT NULL DEFAULT 0 CHECK (critical_count >= 0),
  high_count          INTEGER NOT NULL DEFAULT 0 CHECK (high_count     >= 0),
  moderate_count      INTEGER NOT NULL DEFAULT 0 CHECK (moderate_count >= 0),
  low_count           INTEGER NOT NULL DEFAULT 0 CHECK (low_count      >= 0),
  resolved_count      INTEGER NOT NULL DEFAULT 0 CHECK (resolved_count >= 0),
  reports_received    INTEGER NOT NULL DEFAULT 0 CHECK (reports_received >= 0),
  reports_merged      INTEGER NOT NULL DEFAULT 0 CHECK (reports_merged   >= 0),
  avg_response_min    NUMERIC(8,2) CHECK (avg_response_min >= 0),
  computed_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (metric_date, district_id, incident_type_id)
);


-- =====================================================================
-- 12. TRIGGERS: derived state kept consistent in the database
-- =====================================================================

-- 12.1 reference code generation ---------------------------------------
CREATE OR REPLACE FUNCTION gen_incident_reference() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.reference_code IS NULL THEN
    NEW.reference_code := 'INC-' || to_char(COALESCE(NEW.reported_at, now()), 'YYYY')
                          || '-' || lpad(nextval('incident_ref_seq')::text, 4, '0');
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_incident_reference BEFORE INSERT ON incidents
  FOR EACH ROW EXECUTE FUNCTION gen_incident_reference();

-- 12.2 status history + first_dispatch_at ------------------------------
CREATE OR REPLACE FUNCTION log_incident_status_change() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO incident_status_history (incident_id, from_status, to_status, changed_by)
    VALUES (NEW.id, NULL, NEW.status, 'system');
  ELSIF NEW.status IS DISTINCT FROM OLD.status THEN
    INSERT INTO incident_status_history (incident_id, from_status, to_status, changed_by)
    VALUES (NEW.id, OLD.status, NEW.status, 'system');
  END IF;
  RETURN NULL;
END $$;

CREATE TRIGGER trg_incident_status_history AFTER INSERT OR UPDATE OF status ON incidents
  FOR EACH ROW EXECUTE FUNCTION log_incident_status_change();

-- 12.3 merged_report_count maintenance ---------------------------------
-- Deliberate denormalisation: the Dashboard renders "N signals" on every
-- row of the queue. A COUNT(*) subquery per row is avoidable work.
CREATE OR REPLACE FUNCTION sync_merged_report_count() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP IN ('INSERT','UPDATE') AND NEW.incident_id IS NOT NULL THEN
    UPDATE incidents i SET merged_report_count =
      (SELECT count(*) FROM reports r WHERE r.incident_id = i.id)
    WHERE i.id = NEW.incident_id;
  END IF;
  IF TG_OP IN ('UPDATE','DELETE') AND OLD.incident_id IS NOT NULL
     AND OLD.incident_id IS DISTINCT FROM NEW.incident_id THEN
    UPDATE incidents i SET merged_report_count =
      (SELECT count(*) FROM reports r WHERE r.incident_id = i.id)
    WHERE i.id = OLD.incident_id;
  END IF;
  RETURN NULL;
END $$;

CREATE TRIGGER trg_sync_merged_count
  AFTER INSERT OR UPDATE OF incident_id OR DELETE ON reports
  FOR EACH ROW EXECUTE FUNCTION sync_merged_report_count();

-- 12.4 dispatch -> incident/resource state propagation -----------------
CREATE OR REPLACE FUNCTION apply_dispatch_effects() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE old_res_status resource_status;
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE incidents
       SET first_dispatch_at = COALESCE(first_dispatch_at, NEW.assigned_at),
           status = CASE WHEN status = 'new' THEN 'dispatched' ELSE status END
     WHERE id = NEW.incident_id;

    SELECT status INTO old_res_status FROM resources WHERE id = NEW.resource_id;
    IF old_res_status <> 'deployed' THEN
      UPDATE resources SET status = 'deployed' WHERE id = NEW.resource_id;
      INSERT INTO resource_status_history (resource_id, from_status, to_status, dispatch_id)
      VALUES (NEW.resource_id, old_res_status, 'deployed', NEW.id);
    END IF;

  ELSIF TG_OP = 'UPDATE' AND NEW.status IN ('cleared','cancelled')
        AND OLD.status NOT IN ('cleared','cancelled') THEN
    SELECT status INTO old_res_status FROM resources WHERE id = NEW.resource_id;
    UPDATE resources SET status = 'returning' WHERE id = NEW.resource_id;
    INSERT INTO resource_status_history (resource_id, from_status, to_status, dispatch_id)
    VALUES (NEW.resource_id, old_res_status, 'returning', NEW.id);
  END IF;
  RETURN NULL;
END $$;

CREATE TRIGGER trg_dispatch_effects AFTER INSERT OR UPDATE OF status ON dispatches
  FOR EACH ROW EXECUTE FUNCTION apply_dispatch_effects();


-- =====================================================================
-- 13. INDEXES
-- =====================================================================

-- ---- 13.1 SPATIAL (GiST) --------------------------------------------
CREATE INDEX idx_incidents_location_gist      ON incidents  USING GIST (location);
CREATE INDEX idx_reports_location_gist        ON reports    USING GIST (location);
CREATE INDEX idx_resources_location_gist      ON resources  USING GIST (current_location);
CREATE INDEX idx_facilities_location_gist     ON facilities USING GIST (location);
CREATE INDEX idx_districts_boundary_gist      ON districts  USING GIST (boundary);
CREATE INDEX idx_wards_boundary_gist          ON wards      USING GIST (boundary);
CREATE INDEX idx_zones_area_gist              ON incident_zones USING GIST (area);
CREATE INDEX idx_dispatch_route_gist          ON dispatches USING GIST (route);
CREATE INDEX idx_pings_location_gist          ON resource_location_pings USING GIST (location);

-- Metric-distance (`::geography`) paths: "within 10 km", "nearest tender".
CREATE INDEX idx_incidents_geog     ON incidents  USING GIST ((location::geography));
CREATE INDEX idx_resources_geog     ON resources  USING GIST ((current_location::geography));
CREATE INDEX idx_facilities_geog    ON facilities USING GIST ((location::geography));

-- Composite GiST: "free ambulances near this point" filters on status AND
-- geometry in one index scan (btree_gist makes the enum indexable in GiST).
CREATE INDEX idx_resources_status_location
  ON resources USING GIST (status, resource_type_id, current_location)
  WHERE is_active;

-- Spatio-temporal duplicate detection: candidate reports are those near
-- this point in the last N minutes.
CREATE INDEX idx_reports_dedup_window
  ON reports USING GIST (location, received_at)
  WHERE incident_id IS NULL;

-- ---- 13.2 OPERATIONAL B-TREE ----------------------------------------
-- Dashboard "active" filter + Command Room priority board sort.
CREATE INDEX idx_incidents_active_priority
  ON incidents (severity_score DESC, reported_at DESC)
  WHERE status <> 'resolved';

CREATE INDEX idx_incidents_district_status ON incidents (district_id, status, reported_at DESC);
CREATE INDEX idx_incidents_type_reported   ON incidents (incident_type_id, reported_at DESC);
CREATE INDEX idx_incidents_status          ON incidents (status) WHERE status <> 'resolved';
CREATE INDEX idx_incidents_reported_at     ON incidents (reported_at DESC);
CREATE INDEX idx_incidents_owner           ON incidents (owner_user_id) WHERE owner_user_id IS NOT NULL;
CREATE INDEX idx_incidents_merged_into     ON incidents (merged_into_id) WHERE merged_into_id IS NOT NULL;

CREATE INDEX idx_reports_incident          ON reports (incident_id);
CREATE INDEX idx_reports_status_received   ON reports (status, received_at DESC);
CREATE INDEX idx_reports_district_received ON reports (district_id, received_at DESC);
CREATE INDEX idx_reports_reporter_user     ON reports (reporter_user_id) WHERE reporter_user_id IS NOT NULL;
-- fuzzy text matching for the de-duplication engine
CREATE INDEX idx_reports_description_trgm  ON reports USING GIN (description gin_trgm_ops);
CREATE INDEX idx_incidents_title_trgm      ON incidents USING GIN (title gin_trgm_ops);

CREATE INDEX idx_dispatches_incident       ON dispatches (incident_id);
CREATE INDEX idx_dispatches_resource       ON dispatches (resource_id, assigned_at DESC);
CREATE INDEX idx_dispatches_open
  ON dispatches (incident_id, status)
  WHERE status IN ('assigned','acknowledged','en_route','on_scene');

-- Cross-district conflict check ("Any resource conflict with the Rajkot
-- gas leak?"): a unit may hold exactly one open dispatch.
CREATE UNIQUE INDEX uq_resource_single_open_dispatch
  ON dispatches (resource_id)
  WHERE status IN ('assigned','acknowledged','en_route','on_scene');

-- Prevent assigning the same unit to the same incident twice.
CREATE UNIQUE INDEX uq_dispatch_incident_resource_open
  ON dispatches (incident_id, resource_id)
  WHERE status <> 'cancelled';

CREATE INDEX idx_resources_status_district ON resources (status, home_district_id) WHERE is_active;
CREATE INDEX idx_resources_type            ON resources (resource_type_id, status);

CREATE INDEX idx_log_events_incident_time  ON incident_log_events (incident_id, occurred_at DESC);
CREATE INDEX idx_log_events_time           ON incident_log_events (occurred_at DESC);
CREATE INDEX idx_log_events_tone           ON incident_log_events (tone, occurred_at DESC);

CREATE INDEX idx_status_hist_incident      ON incident_status_history (incident_id, changed_at);
CREATE INDEX idx_status_hist_dispatched    ON incident_status_history (changed_at)
  WHERE to_status = 'dispatched';

CREATE INDEX idx_res_status_hist_resource  ON resource_status_history (resource_id, changed_at DESC);
CREATE INDEX idx_pings_resource_time       ON resource_location_pings (resource_id, recorded_at DESC);

CREATE INDEX idx_merges_target             ON incident_merges (target_incident_id, occurred_at DESC);
CREATE INDEX idx_assessments_incident      ON severity_assessments (incident_id, computed_at DESC);
CREATE INDEX idx_assessments_report        ON severity_assessments (report_id);
CREATE INDEX idx_assessments_keywords      ON severity_assessments USING GIN (matched_keywords);

CREATE INDEX idx_copilot_conv_user         ON copilot_conversations (user_id, last_message_at DESC);
CREATE INDEX idx_copilot_msg_conv          ON copilot_messages (conversation_id, seq);
CREATE INDEX idx_copilot_ctx_incident      ON copilot_message_context (incident_id);
CREATE INDEX idx_copilot_reco_incident     ON copilot_recommendations (incident_id, state);

CREATE INDEX idx_notifications_unread
  ON notifications (recipient_user_id, created_at DESC)
  WHERE read_at IS NULL;

CREATE INDEX idx_facilities_district_kind  ON facilities (district_id, kind) WHERE is_active;
CREATE INDEX idx_zones_incident_active     ON incident_zones (incident_id) WHERE is_active;

-- ---- 13.3 AUTH ------------------------------------------------------
CREATE INDEX idx_refresh_active
  ON refresh_tokens (user_id, expires_at)
  WHERE revoked_at IS NULL;
CREATE INDEX idx_denylist_expiry           ON access_token_denylist (expires_at);
CREATE INDEX idx_auth_events_user_time     ON auth_events (user_id, occurred_at DESC);
CREATE INDEX idx_audit_entity              ON audit_log (entity_type, entity_id, occurred_at DESC);
CREATE INDEX idx_user_roles_role           ON user_roles (role_id);
CREATE INDEX idx_users_active              ON users (is_active) WHERE is_active;


-- =====================================================================
-- 14. VIEWS & MATERIALIZED VIEWS  (one per Analytics chart)
-- =====================================================================

-- 14.1 API read model for the tactical map + queue ---------------------
-- Returns exactly the `Incident` TypeScript interface, so FastAPI can
-- SELECT * and serialise without joins in Python.
CREATE VIEW v_incident_api AS
SELECT
  i.reference_code                              AS id,
  it.label                                      AS type,
  i.title,
  d.name                                        AS district,
  i.coord_label                                 AS coord,
  i.map_x                                       AS x,
  i.map_y                                       AS y,
  i.severity_score                              AS "severityScore",
  i.severity,
  i.status,
  to_char(i.reported_at AT TIME ZONE 'Asia/Kolkata', 'HH24:MI:SS') AS "reportedAt",
  (extract(epoch FROM i.reported_at) * 1000)::bigint               AS "timestamp",
  rt.label                                      AS "reporterType",
  i.description,
  i.merged_report_count                         AS duplicates,
  COALESCE(
    (SELECT array_agg(rtp.label || ' ' || r.code ORDER BY dp.assigned_at)
       FROM dispatches dp
       JOIN resources r       ON r.id = dp.resource_id
       JOIN resource_types rtp ON rtp.id = r.resource_type_id
      WHERE dp.incident_id = i.id AND dp.status <> 'cancelled'),
    '{}'
  )                                             AS "assignedResources"
FROM incidents i
JOIN incident_types it ON it.id = i.incident_type_id
JOIN districts      d  ON d.id  = i.district_id
LEFT JOIN reports   pr ON pr.id = i.primary_report_id
LEFT JOIN reporter_types rt ON rt.id = pr.reporter_type_id
WHERE i.merged_into_id IS NULL;

-- 14.2 Analytics: incidents by type (donut) ----------------------------
CREATE MATERIALIZED VIEW mv_incidents_by_type AS
SELECT it.label AS name, count(*)::int AS value
FROM incidents i JOIN incident_types it ON it.id = i.incident_type_id
WHERE i.reported_at >= now() - INTERVAL '7 days' AND i.merged_into_id IS NULL
GROUP BY it.label;
CREATE UNIQUE INDEX ON mv_incidents_by_type (name);

-- 14.3 Analytics: severity by district (stacked bar) -------------------
CREATE MATERIALIZED VIEW mv_severity_by_district AS
SELECT d.name AS district,
       count(*) FILTER (WHERE i.severity = 'critical')::int AS critical,
       count(*) FILTER (WHERE i.severity = 'high')::int     AS high,
       count(*) FILTER (WHERE i.severity = 'moderate')::int AS moderate,
       count(*) FILTER (WHERE i.severity = 'low')::int      AS low
FROM districts d LEFT JOIN incidents i
  ON i.district_id = d.id
 AND i.reported_at >= now() - INTERVAL '7 days'
 AND i.merged_into_id IS NULL
GROUP BY d.name;
CREATE UNIQUE INDEX ON mv_severity_by_district (district);

-- 14.4 Analytics: incidents by 3-hour block ----------------------------
CREATE MATERIALIZED VIEW mv_incidents_by_hour AS
SELECT lpad(((extract(hour FROM i.reported_at AT TIME ZONE 'Asia/Kolkata')::int / 3) * 3)::text,
            2, '0') AS hour,
       count(*)::int AS count
FROM incidents i
WHERE i.reported_at >= now() - INTERVAL '7 days' AND i.merged_into_id IS NULL
GROUP BY 1;
CREATE UNIQUE INDEX ON mv_incidents_by_hour (hour);

-- 14.5 Analytics: response-time trend ----------------------------------
-- "Average minutes to first dispatch" — exactly first_dispatch_at - reported_at.
CREATE MATERIALIZED VIEW mv_response_time_trend AS
SELECT to_char(i.reported_at AT TIME ZONE 'Asia/Kolkata', 'Dy') AS day,
       date_trunc('day', i.reported_at AT TIME ZONE 'Asia/Kolkata')::date AS day_date,
       round(avg(extract(epoch FROM (i.first_dispatch_at - i.reported_at)) / 60.0)::numeric, 1)
         AS minutes
FROM incidents i
WHERE i.first_dispatch_at IS NOT NULL
  AND i.reported_at >= now() - INTERVAL '7 days'
GROUP BY 1, 2;
CREATE UNIQUE INDEX ON mv_response_time_trend (day_date);

-- 14.6 Analytics: resource utilisation (donut) -------------------------
CREATE MATERIALIZED VIEW mv_resource_utilization AS
SELECT initcap(status::text) AS name, count(*)::int AS value
FROM resources WHERE is_active GROUP BY status;
CREATE UNIQUE INDEX ON mv_resource_utilization (name);

-- 14.7 Hero + KPI strip ------------------------------------------------
CREATE MATERIALIZED VIEW mv_platform_kpis AS
SELECT
  (SELECT count(*) FROM incidents WHERE merged_into_id IS NULL)              AS incidents_coordinated,
  (SELECT round(avg(extract(epoch FROM (first_dispatch_at - reported_at))/60.0)::numeric, 1)
     FROM incidents WHERE first_dispatch_at IS NOT NULL
      AND reported_at >= now() - INTERVAL '7 days')                          AS avg_response_min,
  (SELECT CASE WHEN count(*) = 0 THEN 0
          ELSE round(100.0 * count(*) FILTER (WHERE status = 'merged') / count(*)) END
     FROM reports)                                                           AS pct_reports_merged,
  (SELECT count(*) FROM districts WHERE is_online)                           AS districts_online,
  (SELECT CASE WHEN count(*) = 0 THEN 0
          ELSE round(100.0 * count(*) FILTER (WHERE status = 'resolved') / count(*)) END
     FROM incidents WHERE reported_at >= now() - INTERVAL '7 days')          AS resolution_rate_pct;

CREATE OR REPLACE FUNCTION refresh_analytics() RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_incidents_by_type;
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_severity_by_district;
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_incidents_by_hour;
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_response_time_trend;
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_resource_utilization;
  REFRESH MATERIALIZED VIEW mv_platform_kpis;
END $$;


-- =====================================================================
-- 15. DOMAIN FUNCTIONS THE API WILL CALL
-- =====================================================================

-- 15.1 nearest available units ------------------------------------------
-- Backs "Pre-position AMB-11 (available, 6 min)" and the ETA feed line.
CREATE OR REPLACE FUNCTION nearest_available_units(
  p_incident_id UUID,
  p_resource_type_id SMALLINT DEFAULT NULL,
  p_limit INT DEFAULT 5,
  p_radius_m NUMERIC DEFAULT 50000
)
RETURNS TABLE (resource_id UUID, code TEXT, distance_m NUMERIC, eta_minutes NUMERIC)
LANGUAGE sql STABLE AS $$
  SELECT r.id,
         r.code,
         round(ST_Distance(r.current_location::geography, i.location::geography)::numeric, 1),
         round(((ST_Distance(r.current_location::geography, i.location::geography) / 1000.0)
                 / rt.avg_speed_kmph * 60)::numeric, 1)
  FROM resources r
  JOIN resource_types rt ON rt.id = r.resource_type_id
  CROSS JOIN LATERAL (SELECT location FROM incidents WHERE id = p_incident_id) i
  WHERE r.is_active
    AND r.status = 'available'
    AND r.current_location IS NOT NULL
    AND (p_resource_type_id IS NULL OR r.resource_type_id = p_resource_type_id)
    AND ST_DWithin(r.current_location::geography, i.location::geography, p_radius_m)
  ORDER BY r.current_location <-> i.location
  LIMIT p_limit;
$$;

-- 15.2 duplicate candidates ---------------------------------------------
-- "Duplicate reports merged — 7 signals unified into INC-2026-0417":
-- same type, within R metres, within T minutes, ranked by text similarity.
CREATE OR REPLACE FUNCTION find_duplicate_candidates(
  p_report_id UUID,
  p_radius_m NUMERIC DEFAULT 800,
  p_window INTERVAL DEFAULT INTERVAL '45 minutes'
)
RETURNS TABLE (incident_id UUID, reference_code TEXT, distance_m NUMERIC,
               text_similarity REAL, minutes_apart NUMERIC)
LANGUAGE sql STABLE AS $$
  SELECT i.id, i.reference_code,
         round(ST_Distance(i.location::geography, r.location::geography)::numeric, 1),
         similarity(i.description, r.description),
         round((extract(epoch FROM (r.received_at - i.reported_at)) / 60.0)::numeric, 1)
  FROM reports r
  JOIN incidents i
    ON i.incident_type_id = r.incident_type_id
   AND i.merged_into_id IS NULL
   AND i.status <> 'resolved'
   AND i.reported_at BETWEEN r.received_at - p_window AND r.received_at + p_window
   AND ST_DWithin(i.location::geography, r.location::geography, p_radius_m)
  WHERE r.id = p_report_id AND r.location IS NOT NULL
  ORDER BY 3 ASC, 4 DESC;
$$;

-- 15.3 cordon builder ---------------------------------------------------
-- "Establish 200m cordon" / "evacuation within 500m radius".
CREATE OR REPLACE FUNCTION create_cordon(
  p_incident_id UUID, p_radius_m NUMERIC, p_kind TEXT DEFAULT 'cordon'
) RETURNS BIGINT
LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
  INSERT INTO incident_zones (incident_id, zone_kind, radius_m, area)
  SELECT p_incident_id, p_kind, p_radius_m,
         ST_Buffer(i.location::geography, p_radius_m)::geometry
  FROM incidents i WHERE i.id = p_incident_id
  RETURNING id INTO v_id;
  RETURN v_id;
END $$;

-- 15.4 open resource conflicts -----------------------------------------
-- Direct answer to the Copilot question "Any resource conflict with the
-- Rajkot gas leak?"
CREATE OR REPLACE FUNCTION resource_conflicts(p_incident_id UUID)
RETURNS TABLE (resource_code TEXT, held_by_incident TEXT, held_district TEXT,
               distance_km NUMERIC)
LANGUAGE sql STABLE AS $$
  SELECT r.code, i2.reference_code, d.name,
         round((ST_Distance(i1.location::geography, i2.location::geography)/1000.0)::numeric, 1)
  FROM dispatches dp
  JOIN resources  r  ON r.id  = dp.resource_id
  JOIN incidents  i2 ON i2.id = dp.incident_id
  JOIN districts  d  ON d.id  = i2.district_id
  CROSS JOIN LATERAL (SELECT location FROM incidents WHERE id = p_incident_id) i1
  WHERE dp.status IN ('assigned','acknowledged','en_route','on_scene')
    AND dp.incident_id <> p_incident_id;
$$;

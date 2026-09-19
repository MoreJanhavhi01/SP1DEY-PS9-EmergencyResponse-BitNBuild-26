-- =====================================================================
-- ResQ Command · sample data for testing
-- Every operational row is transcribed from lib/mock-data.ts so the
-- seeded database renders the existing UI byte-for-byte.
-- Run AFTER resq_schema.sql.
-- =====================================================================
\set ON_ERROR_STOP on
SET search_path = resq, public;

BEGIN;

-- ---------------------------------------------------------------------
-- 1. AGENCIES
-- ---------------------------------------------------------------------
INSERT INTO agencies (code, name, contact_phone) VALUES
  ('GSDMA',  'Gujarat State Disaster Management Authority', '+919825000001'),
  ('GFES',   'Gujarat Fire & Emergency Services',           '+919825000002'),
  ('EMS108', '108 Emergency Medical Services',              '+919825000003'),
  ('NDRF',   'National Disaster Response Force',            '+919825000004'),
  ('SHP',    'State Highway Patrol',                        '+919825000005'),
  ('ICG',    'Indian Coast Guard (Gujarat)',                '+919825000006');

-- ---------------------------------------------------------------------
-- 2. DISTRICTS  (all 33 — heroStats "Districts online · 33")
--    Centroids are approximate; boundaries are generated envelopes
--    purely so the spatial joins and GiST indexes are exercisable.
-- ---------------------------------------------------------------------
INSERT INTO districts (code, name, centroid, is_online, population) VALUES
  ('AHM','Ahmedabad',        ST_SetSRID(ST_MakePoint(72.5714,23.0225),4326), TRUE, 8059441),
  ('AMR','Amreli',           ST_SetSRID(ST_MakePoint(71.2224,21.6032),4326), TRUE, 1514190),
  ('ANA','Anand',            ST_SetSRID(ST_MakePoint(72.9289,22.5645),4326), TRUE, 2092745),
  ('ARV','Aravalli',         ST_SetSRID(ST_MakePoint(73.2000,23.4000),4326), TRUE,  1051000),
  ('BAN','Banaskantha',      ST_SetSRID(ST_MakePoint(72.4300,24.1700),4326), TRUE, 3120506),
  ('BHR','Bharuch',          ST_SetSRID(ST_MakePoint(72.9951,21.7051),4326), TRUE, 1551019),
  ('BHV','Bhavnagar',        ST_SetSRID(ST_MakePoint(72.1519,21.7645),4326), TRUE, 2880365),
  ('BOT','Botad',            ST_SetSRID(ST_MakePoint(71.6660,22.1700),4326), TRUE,  656005),
  ('CHU','Chhota Udaipur',   ST_SetSRID(ST_MakePoint(74.0100,22.3100),4326), TRUE, 1071831),
  ('DAH','Dahod',            ST_SetSRID(ST_MakePoint(74.2500,22.8350),4326), TRUE, 2127086),
  ('DNG','Dang',             ST_SetSRID(ST_MakePoint(73.6800,20.7500),4326), TRUE,  228291),
  ('DDW','Devbhoomi Dwarka', ST_SetSRID(ST_MakePoint(69.0700,22.2400),4326), TRUE,  752484),
  ('GND','Gandhinagar',      ST_SetSRID(ST_MakePoint(72.6369,23.2156),4326), TRUE, 1391753),
  ('GIR','Gir Somnath',      ST_SetSRID(ST_MakePoint(70.6300,20.9000),4326), TRUE, 1217477),
  ('JAM','Jamnagar',         ST_SetSRID(ST_MakePoint(70.0577,22.4707),4326), TRUE, 1555000),
  ('JUN','Junagadh',         ST_SetSRID(ST_MakePoint(70.4579,21.5222),4326), TRUE, 1583000),
  ('KUT','Kutch',            ST_SetSRID(ST_MakePoint(69.8597,23.7337),4326), TRUE, 2092371),
  ('KHE','Kheda',            ST_SetSRID(ST_MakePoint(72.6841,22.7507),4326), TRUE, 2299885),
  ('MAH','Mahisagar',        ST_SetSRID(ST_MakePoint(73.6100,23.0400),4326), TRUE,  994624),
  ('MEH','Mehsana',          ST_SetSRID(ST_MakePoint(72.3693,23.5880),4326), TRUE, 2035064),
  ('MOR','Morbi',            ST_SetSRID(ST_MakePoint(70.8370,22.8173),4326), TRUE,  960329),
  ('NRM','Narmada',          ST_SetSRID(ST_MakePoint(73.5000,21.8700),4326), TRUE,  590297),
  ('NAV','Navsari',          ST_SetSRID(ST_MakePoint(72.9270,20.9467),4326), TRUE, 1329672),
  ('PAN','Panchmahal',       ST_SetSRID(ST_MakePoint(73.6000,22.7700),4326), TRUE, 1642268),
  ('PAT','Patan',            ST_SetSRID(ST_MakePoint(72.1266,23.8493),4326), TRUE, 1343734),
  ('POR','Porbandar',        ST_SetSRID(ST_MakePoint(69.6293,21.6417),4326), TRUE,  585449),
  ('RAJ','Rajkot',           ST_SetSRID(ST_MakePoint(70.8022,22.3039),4326), TRUE, 3804558),
  ('SAB','Sabarkantha',      ST_SetSRID(ST_MakePoint(72.9800,23.6000),4326), TRUE, 1474000),
  ('SUR','Surat',            ST_SetSRID(ST_MakePoint(72.8311,21.1702),4326), TRUE, 6081322),
  ('SRN','Surendranagar',    ST_SetSRID(ST_MakePoint(71.6369,22.7196),4326), TRUE, 1756268),
  ('TAP','Tapi',             ST_SetSRID(ST_MakePoint(73.4000,21.1200),4326), TRUE,  807022),
  ('VAD','Vadodara',         ST_SetSRID(ST_MakePoint(73.1812,22.3072),4326), TRUE, 4165626),
  ('VAL','Valsad',           ST_SetSRID(ST_MakePoint(72.9342,20.5992),4326), TRUE, 1705678);

-- derive the stylised 0-100 wall-map coordinates + a simple envelope boundary
UPDATE districts SET
  map_x    = GREATEST(0, LEAST(100, round((((ST_X(centroid) - 68.10) / 6.40) * 100)::numeric, 2))),
  map_y    = GREATEST(0, LEAST(100, round((((24.80 - ST_Y(centroid)) / 4.70) * 100)::numeric, 2))),
  boundary = ST_Multi(ST_MakeEnvelope(ST_X(centroid) - 0.35, ST_Y(centroid) - 0.30,
                                      ST_X(centroid) + 0.35, ST_Y(centroid) + 0.30, 4326));

-- wards referenced in incident descriptions
INSERT INTO wards (district_id, name)
SELECT id, w FROM districts d,
  LATERAL (VALUES ('Sayajipura'), ('Akota'), ('Karelibaug')) v(w)
WHERE d.code = 'VAD';
INSERT INTO wards (district_id, name)
SELECT id, w FROM districts d,
  LATERAL (VALUES ('Pandesara'), ('Katargam'), ('Udhna')) v(w)
WHERE d.code = 'SUR';

-- ---------------------------------------------------------------------
-- 3. REFERENCE DATA  (verbatim from report-form.tsx)
-- ---------------------------------------------------------------------
INSERT INTO incident_types (code, label, base_score, display_order) VALUES
  ('fire',              'Fire',              62, 1),
  ('flood',             'Flood',             48, 2),
  ('medical',           'Medical',           40, 3),
  ('accident',          'Accident',          38, 4),
  ('gas_leak',          'Gas Leak',          66, 5),
  ('building_collapse', 'Building Collapse', 70, 6),
  ('cyclone',           'Cyclone',           55, 7);

INSERT INTO report_channels (code, label) VALUES
  ('sms','SMS'), ('app','Mobile App'), ('call','Voice Call'),
  ('radio','Field Radio'), ('iot','IoT Sensor'), ('web','Web Form'),
  ('social','Social Media');

INSERT INTO reporter_types (code, label, trust_weight, is_official, display_order) VALUES
  ('citizen',             'Citizen',             0, FALSE, 1),
  ('field_officer',       'Field Officer',       5, TRUE,  2),
  ('operator_112',        '112 Operator',        0, TRUE,  3),
  ('emergency_services',  'Emergency Services',  5, TRUE,  4);

INSERT INTO scoring_profiles (version, is_active) VALUES ('v1.0-client-parity', TRUE);

INSERT INTO severity_keywords (scoring_profile_id, keyword, weight)
SELECT sp.id, k, 6
FROM scoring_profiles sp,
  LATERAL (VALUES ('trapped'), ('unconscious'), ('children'), ('fire spreading'),
                  ('multiple'), ('collapse'), ('leak'), ('critical'), ('blood'),
                  ('not breathing'), ('drowning')) v(k)
WHERE sp.version = 'v1.0-client-parity';

INSERT INTO resource_types (code, label, code_prefix, default_crew_size, avg_speed_kmph) VALUES
  ('fire_tender',    'Fire Tender',    'FT',    6, 45),
  ('ambulance',      'Ambulance',      'AMB',   3, 50),
  ('rescue_boat',    'Rescue Boat',    'RB',    4, 20),
  ('hazmat_unit',    'HazMat Unit',    'HZ',    5, 40),
  ('ndrf_team',      'NDRF Team',      'NDRF', 12, 35),
  ('highway_rescue', 'Highway Rescue', 'HR',    4, 60),
  ('relief_van',     'Relief Van',     'RV',    2, 40);

INSERT INTO capabilities (code, label) VALUES
  ('burns_unit','Burns Unit'), ('icu','Intensive Care Unit'),
  ('trauma','Trauma Centre'), ('dialysis','Dialysis'),
  ('decontamination','Decontamination Bay');

-- which unit type answers which emergency (Copilot recommendation engine)
INSERT INTO incident_type_resource_matrix (incident_type_id, resource_type_id, recommended_units, priority)
SELECT it.id, rt.id, m.units, m.pri
FROM (VALUES
  ('fire','fire_tender',2,1), ('fire','ambulance',1,2),
  ('flood','rescue_boat',2,1), ('flood','ndrf_team',1,2),
  ('medical','ambulance',1,1),
  ('accident','ambulance',1,1), ('accident','highway_rescue',1,2),
  ('gas_leak','hazmat_unit',1,1), ('gas_leak','fire_tender',1,2),
  ('building_collapse','ndrf_team',1,1), ('building_collapse','ambulance',2,2),
  ('cyclone','relief_van',2,1), ('cyclone','ndrf_team',1,2)
) AS m(itc, rtc, units, pri)
JOIN incident_types it ON it.code = m.itc
JOIN resource_types rt ON rt.code = m.rtc;

-- ---------------------------------------------------------------------
-- 4. AUTH  (roles, permissions, users)
-- ---------------------------------------------------------------------
INSERT INTO roles (code, display_name, description, is_system) VALUES
  ('super_admin',          'Super Admin',          'Full platform administration', TRUE),
  ('state_coordinator',    'State Coordinator',    'State-wide command authority',  TRUE),
  ('district_coordinator', 'District Coordinator', 'Dispatch within assigned district', TRUE),
  ('dispatcher',           'Dispatcher',           'Assign units, no configuration', TRUE),
  ('field_officer',        'Field Officer',        'Acknowledge and update assignments', TRUE),
  ('analyst',              'Analyst',              'Read-only analytics access', TRUE),
  ('citizen',              'Citizen',              'Submit and track own reports', TRUE);

INSERT INTO permissions (code, description) VALUES
  ('incident:read',    'View incidents'),
  ('incident:write',   'Create or edit incidents'),
  ('incident:merge',   'Merge or unmerge duplicate reports'),
  ('incident:dispatch','Assign resources to incidents'),
  ('resource:read',    'View resource roster and status'),
  ('resource:write',   'Edit resource records'),
  ('analytics:read',   'View analytics dashboards'),
  ('copilot:use',      'Query the ResQ Copilot'),
  ('report:create',    'Submit an emergency report'),
  ('admin:manage',     'Manage users, roles and configuration');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p WHERE r.code = 'super_admin';

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.code IN
  ('incident:read','incident:write','incident:merge','incident:dispatch',
   'resource:read','analytics:read','copilot:use','report:create')
WHERE r.code IN ('state_coordinator','district_coordinator');

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.code IN
  ('incident:read','incident:dispatch','resource:read','copilot:use')
WHERE r.code = 'dispatcher';

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.code IN
  ('incident:read','resource:read','report:create')
WHERE r.code = 'field_officer';

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.code IN ('analytics:read','incident:read')
WHERE r.code = 'analyst';

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.code = 'report:create'
WHERE r.code = 'citizen';

-- password_hash below is a placeholder argon2id digest — never a real secret
-- password_hash values are placeholder argon2id strings, never real secrets
INSERT INTO users (id, email, phone, full_name, password_hash, employee_code, is_email_verified)
VALUES
  ('11111111-1111-4111-8111-111111111111','admin@resq.gujarat.gov.in',
   '+919812345001','R. Mehta',   '$argon2id$v=19$m=65536,t=3,p=4$PLACEHOLDER','GSDMA-0001', TRUE),
  ('22222222-2222-4222-8222-222222222222','surat.coord@resq.gujarat.gov.in',
   '+919812345002','P. Desai',   '$argon2id$v=19$m=65536,t=3,p=4$PLACEHOLDER','GSDMA-0114', TRUE),
  ('33333333-3333-4333-8333-333333333333','vadodara.coord@resq.gujarat.gov.in',
   '+919812345003','A. Chauhan', '$argon2id$v=19$m=65536,t=3,p=4$PLACEHOLDER','GSDMA-0207', TRUE),
  ('44444444-4444-4444-8444-444444444444','ft12.lead@gfes.gujarat.gov.in',
   '+919812345004','S. Parmar',  '$argon2id$v=19$m=65536,t=3,p=4$PLACEHOLDER','GFES-1122',  TRUE),
  ('55555555-5555-4555-8555-555555555555','analyst@resq.gujarat.gov.in',
   '+919812345005','N. Joshi',   '$argon2id$v=19$m=65536,t=3,p=4$PLACEHOLDER','GSDMA-0330', TRUE);

UPDATE users SET agency_id = (SELECT id FROM agencies WHERE code='GSDMA'),
                 home_district_id = (SELECT id FROM districts WHERE code='AHM')
 WHERE employee_code IN ('GSDMA-0001','GSDMA-0330');
UPDATE users SET agency_id = (SELECT id FROM agencies WHERE code='GSDMA'),
                 home_district_id = (SELECT id FROM districts WHERE code='SUR')
 WHERE employee_code = 'GSDMA-0114';
UPDATE users SET agency_id = (SELECT id FROM agencies WHERE code='GSDMA'),
                 home_district_id = (SELECT id FROM districts WHERE code='VAD')
 WHERE employee_code = 'GSDMA-0207';
UPDATE users SET agency_id = (SELECT id FROM agencies WHERE code='GFES'),
                 home_district_id = (SELECT id FROM districts WHERE code='SUR')
 WHERE employee_code = 'GFES-1122';

INSERT INTO user_roles (user_id, role_id, district_id)
SELECT u.id, r.id, d.id
FROM (VALUES
  ('GSDMA-0001','super_admin',          NULL),
  ('GSDMA-0114','district_coordinator', 'SUR'),
  ('GSDMA-0207','district_coordinator', 'VAD'),
  ('GFES-1122', 'field_officer',        'SUR'),
  ('GSDMA-0330','analyst',              NULL)
) AS g(emp, role_code, dcode)
JOIN users u     ON u.employee_code = g.emp
JOIN roles r     ON r.code = g.role_code
LEFT JOIN districts d ON d.code = g.dcode;

-- ---------------------------------------------------------------------
-- 5. FACILITIES  (named by ResQCopilot.jsx)
-- ---------------------------------------------------------------------
INSERT INTO facilities (code, name, kind, district_id, location, total_beds,
                        available_beds, capacity_updated_at)
SELECT f.code, f.name, f.kind::facility_kind, d.id,
       ST_SetSRID(ST_MakePoint(f.lon, f.lat), 4326), f.beds, f.free, now()
FROM (VALUES
  ('HOSP-SUR-001','Surat Civil Hospital','hospital','SUR',72.8340,21.1930,1200,86),
  ('HOSP-SUR-002','SMIMER Hospital',     'hospital','SUR',72.8020,21.1580, 750, 3),
  ('HOSP-VAD-001','SSG Hospital',        'hospital','VAD',73.1890,22.3040,1500,142),
  ('HOSP-AHM-001','Civil Hospital Asarwa','hospital','AHM',72.6060,23.0530,2800,310),
  ('HOSP-RAJ-001','Rajkot Civil Hospital','hospital','RAJ',70.7960,22.3010,1100,95),
  ('FS-SUR-001',  'Pandesara Fire Station','fire_station','SUR',72.8290,21.1650,NULL,NULL),
  ('SHL-VAD-001', 'Sayajipura Relief Shelter','relief_shelter','VAD',73.2010,22.3260,NULL,NULL)
) AS f(code, name, kind, dcode, lon, lat, beds, free)
JOIN districts d ON d.code = f.dcode;

UPDATE facilities SET capacity_persons = 1200 WHERE kind = 'relief_shelter';

INSERT INTO facility_capabilities (facility_id, capability_id, units_available)
SELECT f.id, c.id, m.units
FROM (VALUES
  ('HOSP-SUR-001','burns_unit',4), ('HOSP-SUR-001','trauma',6), ('HOSP-SUR-001','icu',18),
  ('HOSP-SUR-002','icu',3),        ('HOSP-SUR-002','dialysis',5),
  ('HOSP-VAD-001','icu',22),       ('HOSP-VAD-001','trauma',8),
  ('HOSP-AHM-001','icu',40),       ('HOSP-AHM-001','burns_unit',10),
  ('HOSP-RAJ-001','icu',12),       ('HOSP-RAJ-001','decontamination',2)
) AS m(fcode, ccode, units)
JOIN facilities   f ON f.code = m.fcode
JOIN capabilities c ON c.code = m.ccode;

-- ---------------------------------------------------------------------
-- 6. RESOURCES  (all 12 units from mock-data resources[])
-- ---------------------------------------------------------------------
INSERT INTO resources (code, resource_type_id, agency_id, home_district_id, status,
                       crew_size, current_location, location_updated_at)
SELECT r.code, rt.id, a.id, d.id, r.status::resource_status, r.crew,
       ST_SetSRID(ST_MakePoint(dd.lon, dd.lat), 4326), now() - INTERVAL '30 seconds'
FROM (VALUES
  ('FT-12',  'fire_tender',   'GFES',  'SUR','deployed',    6),
  ('FT-19',  'fire_tender',   'GFES',  'SUR','deployed',    5),
  ('FT-08',  'fire_tender',   'GFES',  'RAJ','deployed',    6),
  ('AMB-04', 'ambulance',     'EMS108','SUR','deployed',    3),
  ('AMB-07', 'ambulance',     'EMS108','AHM','deployed',    3),
  ('AMB-11', 'ambulance',     'EMS108','AHM','available',   3),
  ('AMB-15', 'ambulance',     'EMS108','AHM','available',   2),
  ('RB-03',  'rescue_boat',   'NDRF',  'VAD','deployed',    4),
  ('HZ-01',  'hazmat_unit',   'GFES',  'RAJ','returning',   5),
  ('NDRF-2', 'ndrf_team',     'NDRF',  'VAD','deployed',   12),
  ('HR-02',  'highway_rescue','SHP',   'AHM','available',   4),
  ('RV-05',  'relief_van',    'GSDMA', 'RAJ','maintenance', 2)
) AS r(code, rtype, agency, dcode, status, crew)
JOIN resource_types rt ON rt.code = r.rtype
JOIN agencies       a  ON a.code  = r.agency
JOIN districts      d  ON d.code  = r.dcode
JOIN LATERAL (SELECT ST_X(d.centroid) + 0.02 AS lon, ST_Y(d.centroid) + 0.02 AS lat) dd ON TRUE;

-- one named crew member on FT-12 (the unit that "acknowledged assignment")
INSERT INTO resource_crew (resource_id, user_id, role_on_unit)
SELECT r.id, u.id, 'lead'
FROM resources r, users u
WHERE r.code = 'FT-12' AND u.employee_code = 'GFES-1122';

-- ---------------------------------------------------------------------
-- 7. INCIDENTS  (all 8 rows of mock-data incidents[], exact values)
-- ---------------------------------------------------------------------
INSERT INTO incidents (reference_code, incident_type_id, title, description,
                       district_id, location, location_text, geocode_confidence,
                       severity_score, status, people_affected,
                       reported_at, first_dispatch_at, resolved_at, owner_user_id)
SELECT m.ref, it.id, m.title, m.descr, d.id,
       ST_SetSRID(ST_MakePoint(m.lon, m.lat), 4326), m.loc_text, 0.92,
       m.score, m.status::incident_status, m.people,
       now() - (m.age_min || ' minutes')::interval,
       CASE WHEN m.status <> 'new'
            THEN now() - (m.age_min || ' minutes')::interval
                 + ((3 + (m.age_min % 11)) || ' minutes')::interval END,
       CASE WHEN m.status = 'resolved'
            THEN now() - (m.age_min || ' minutes')::interval + INTERVAL '55 minutes' END,
       NULL
FROM (VALUES
 ('INC-2026-0417','fire',             'Textile warehouse fire, Pandesara industrial zone',
  'Multiple callers report heavy smoke and flames from a two-storey textile unit. Workers reportedly trapped on upper floor. Wind spreading fire to adjacent units.',
  'SUR',72.8311,21.1702,'Pandesara industrial zone, GIDC gate 3',89,'in-progress',24,12),
 ('INC-2026-0416','flood',            'Urban flooding, Vishwamitri riverfront low-lying areas',
  'River crossing danger mark. Water entering ground floors of ~40 households. Evacuation of elderly and children required in Sayajipura ward.',
  'VAD',73.1812,22.3072,'Vishwamitri riverfront, Sayajipura ward',76,'dispatched',40,21),
 ('INC-2026-0415','medical',          'Mass heat-stroke cases at construction site',
  '11 labourers showing severe heat exhaustion symptoms at SG Highway project. Two unconscious. Nearest PHC over capacity.',
  'AHM',72.5714,23.0225,'SG Highway project site',64,'dispatched',11,33),
 ('INC-2026-0414','accident',         'Multi-vehicle collision on NH-48 near Bagodara',
  'Truck and two cars collided. Highway partially blocked. 3 injured, 1 critical. Fuel spillage reported — fire risk.',
  'AHM',72.1500,22.6890,'NH-48 near Bagodara junction',58,'in-progress',3,47),
 ('INC-2026-0413','gas_leak',         'Industrial gas leak, GIDC estate',
  'Chlorine leak detected at chemical unit. Downwind residential colony at risk. Immediate cordon and evacuation advised within 500m radius.',
  'RAJ',70.8022,22.3039,'GIDC estate, chemical unit block C',82,'dispatched',50,52),
 ('INC-2026-0412','building_collapse','Partial collapse of old residential structure',
  'A section of a 40-year-old chawl collapsed after overnight rain. Unknown number of residents feared under debris.',
  'SUR',72.8302,21.1959,'Old chawl, Katargam',71,'new',15,68),
 ('INC-2026-0411','medical',          'Cardiac emergency, no ambulance in ward',
  'Elderly patient with chest pain. Nearest ambulance rerouted. Patient stabilised and transported to SSG Hospital.',
  'VAD',73.1900,22.3200,'Karelibaug residential block',44,'resolved',1,96),
 ('INC-2026-0410','cyclone',          'Coastal wind damage, fishing hamlet',
  'Strong winds damaged temporary shelters. No casualties. Relief material and tarpaulin dispatched.',
  'RAJ',70.4000,21.9800,'Coastal fishing hamlet',51,'resolved',30,120)
) AS m(ref, itype, title, descr, dcode, lon, lat, loc_text, score, status, people, age_min)
JOIN incident_types it ON it.code = m.itype
JOIN districts      d  ON d.code  = m.dcode;

-- attach the Vadodara / Surat wards where the descriptions name them
UPDATE incidents i SET ward_id = w.id
FROM wards w JOIN districts d ON d.id = w.district_id
WHERE i.reference_code = 'INC-2026-0416' AND w.name = 'Sayajipura' AND d.code = 'VAD';
UPDATE incidents i SET ward_id = w.id
FROM wards w JOIN districts d ON d.id = w.district_id
WHERE i.reference_code = 'INC-2026-0417' AND w.name = 'Pandesara' AND d.code = 'SUR';

-- ---------------------------------------------------------------------
-- 8. REPORTS  (the duplicate signals: 7,4,2,3,5,6,1,2 per incident)
--    Generated so merged_report_count matches mock `duplicates` exactly.
-- ---------------------------------------------------------------------
INSERT INTO reports (reference_code, incident_id, status, incident_type_id, district_id,
                     reporter_type_id, channel_id, location_text, people_affected,
                     description, location, geocode_confidence, geocoded_at,
                     is_anonymous, reporter_phone, client_score_preview,
                     received_at, classified_at, merged_at)
SELECT
  'RPT-2026-' || lpad((row_number() OVER (ORDER BY i.reported_at, g.n))::text, 6, '0'),
  i.id, 'merged', i.incident_type_id, i.district_id,
  rt.id, ch.id, i.location_text,
  LEAST(50, GREATEST(1, COALESCE(i.people_affected, 1))),
  CASE WHEN g.n = 1 THEN i.description
       ELSE 'Duplicate signal ' || g.n || ' — ' || left(i.description, 90) END,
  ST_SetSRID(ST_MakePoint(ST_X(i.location) + (g.n - 1) * 0.0008,
                          ST_Y(i.location) + (g.n - 1) * 0.0006), 4326),
  0.90, i.reported_at, TRUE, '+9198765' || lpad(g.n::text, 5, '0'),
  i.severity_score,
  i.reported_at + ((g.n - 1) * INTERVAL '40 seconds'),
  i.reported_at + ((g.n - 1) * INTERVAL '41 seconds'),
  i.reported_at + ((g.n - 1) * INTERVAL '45 seconds')
FROM incidents i
JOIN LATERAL (
  SELECT generate_series(1, CASE i.reference_code
      WHEN 'INC-2026-0417' THEN 7 WHEN 'INC-2026-0416' THEN 4
      WHEN 'INC-2026-0415' THEN 2 WHEN 'INC-2026-0414' THEN 3
      WHEN 'INC-2026-0413' THEN 5 WHEN 'INC-2026-0412' THEN 6
      WHEN 'INC-2026-0411' THEN 1 ELSE 2 END) AS n
) g ON TRUE
JOIN LATERAL (
  SELECT id FROM reporter_types WHERE label = CASE i.reference_code
      WHEN 'INC-2026-0417' THEN 'Citizen'
      WHEN 'INC-2026-0416' THEN 'Field Officer'
      WHEN 'INC-2026-0415' THEN 'Citizen'
      WHEN 'INC-2026-0414' THEN 'Emergency Services'
      WHEN 'INC-2026-0413' THEN 'Emergency Services'
      WHEN 'INC-2026-0412' THEN 'Citizen'
      WHEN 'INC-2026-0411' THEN 'Citizen'
      ELSE 'Emergency Services' END
) rt ON TRUE
JOIN LATERAL (
  SELECT id FROM report_channels WHERE code = CASE i.reference_code
      WHEN 'INC-2026-0417' THEN 'sms'
      WHEN 'INC-2026-0412' THEN 'app'
      WHEN 'INC-2026-0416' THEN 'radio'
      ELSE 'call' END
) ch ON TRUE;

-- the first report of each incident is the primary/originating signal
UPDATE incidents i SET primary_report_id = r.id
FROM (SELECT DISTINCT ON (incident_id) incident_id, id
        FROM reports ORDER BY incident_id, received_at) r
WHERE r.incident_id = i.id;

-- ---------------------------------------------------------------------
-- 9. SEVERITY ASSESSMENTS  (the "Live AI estimate" breakdown)
-- ---------------------------------------------------------------------
INSERT INTO severity_assessments (incident_id, report_id, scoring_profile_id, base_score,
                                  keyword_bonus, scale_bonus, source_bonus, length_bonus,
                                  final_score, matched_keywords, confidence,
                                  model_name, model_version)
SELECT i.id, i.primary_report_id, sp.id, it.base_score,
       kw.hits * sp.keyword_weight,
       CASE WHEN i.people_affected >= sp.scale_tier3_min THEN sp.scale_tier3_bonus
            WHEN i.people_affected >= sp.scale_tier2_min THEN sp.scale_tier2_bonus
            WHEN i.people_affected >= sp.scale_tier1_min THEN sp.scale_tier1_bonus
            ELSE 0 END,
       rt.trust_weight,
       CASE WHEN length(i.description) > sp.long_text_min_chars THEN sp.long_text_bonus ELSE 0 END,
       i.severity_score, kw.matched, 0.940, 'resq-severity', 'v1.0'
FROM incidents i
JOIN incident_types it ON it.id = i.incident_type_id
JOIN scoring_profiles sp ON sp.is_active
LEFT JOIN reports pr ON pr.id = i.primary_report_id
LEFT JOIN reporter_types rt ON rt.id = pr.reporter_type_id
JOIN LATERAL (
  SELECT count(*)::int AS hits, COALESCE(array_agg(k.keyword), '{}') AS matched
  FROM severity_keywords k
  WHERE k.scoring_profile_id = sp.id AND lower(i.description) LIKE '%' || k.keyword || '%'
) kw ON TRUE;

-- ---------------------------------------------------------------------
-- 10. MERGE AUDIT TRAIL
-- ---------------------------------------------------------------------
INSERT INTO incident_merges (target_incident_id, source_report_id, method,
                             similarity_score, distance_m, time_delta_seconds,
                             decided_by, occurred_at)
SELECT r.incident_id, r.id, 'auto_spatiotemporal', 0.87,
       round(ST_Distance(r.location::geography, i.location::geography)::numeric, 2),
       extract(epoch FROM (r.received_at - i.reported_at))::int,
       'ai', r.merged_at
FROM reports r
JOIN incidents i ON i.id = r.incident_id
WHERE r.id <> i.primary_report_id;

-- ---------------------------------------------------------------------
-- 11. DISPATCHES  (mock assignedResources[] -> proper relation)
--     The trigger flips resources to 'deployed' and stamps first_dispatch_at.
-- ---------------------------------------------------------------------
INSERT INTO dispatches (incident_id, resource_id, status, eta_minutes, eta_computed_at,
                        distance_m, assigned_at, acknowledged_at, on_scene_at, cleared_at,
                        assigned_by)
SELECT i.id, r.id, m.dstatus::dispatch_status, m.eta, i.reported_at + INTERVAL '9 seconds',
       round(ST_Distance(r.current_location::geography, i.location::geography)::numeric, 1),
       i.first_dispatch_at,
       i.first_dispatch_at + INTERVAL '17 seconds',
       CASE WHEN m.dstatus IN ('on_scene','cleared') THEN i.reported_at + INTERVAL '14 minutes' END,
       CASE WHEN m.dstatus = 'cleared' THEN i.reported_at + INTERVAL '52 minutes' END,
       'ai'
FROM (VALUES
  ('INC-2026-0417','FT-12', 'on_scene', 4.0),
  ('INC-2026-0417','FT-19', 'on_scene', 7.5),
  ('INC-2026-0417','AMB-04','on_scene', 9.0),
  ('INC-2026-0416','RB-03', 'en_route',11.0),
  ('INC-2026-0416','NDRF-2','en_route',18.0),
  ('INC-2026-0415','AMB-11','assigned', 6.0),
  ('INC-2026-0415','AMB-15','assigned', 8.0),
  ('INC-2026-0414','AMB-07','on_scene',12.0),
  ('INC-2026-0414','HR-02', 'on_scene',15.0),
  ('INC-2026-0413','HZ-01', 'en_route', 9.0),
  ('INC-2026-0413','FT-08', 'en_route',10.5),
  ('INC-2026-0411','AMB-09','cleared',  7.0),
  ('INC-2026-0410','RV-05', 'cleared', 25.0)
) AS m(ref, rcode, dstatus, eta)
JOIN incidents i ON i.reference_code = m.ref
JOIN resources r ON r.code = m.rcode;
-- FRONTEND DATA BUGS FOUND WHILE SEEDING — recorded, not papered over:
--  (a) mock-data assigns AMB-09 to INC-2026-0411, but AMB-09 does not exist
--      in resources[]. The JOIN above drops that row. A FK makes this
--      class of dangling reference impossible in production.
--  (b) AMB-11, AMB-15 and HR-02 are listed with status 'available' while
--      simultaneously appearing in an active incident's assignedResources[],
--      and RV-05 is 'maintenance' while assigned to INC-2026-0410. Those two
--      facts cannot both be true. This schema resolves the contradiction by
--      storing assignment once, in `dispatches`, and deriving unit status
--      from it via trg_dispatch_effects.
-- The statement below force-sets the roster back to the literal mock values
-- so a seeded database renders the existing UI unchanged. Production code
-- should delete it and let the trigger be the single source of truth.
UPDATE resources r SET status = v.s::resource_status
FROM (VALUES
  ('FT-12','deployed'),   ('FT-19','deployed'),   ('FT-08','deployed'),
  ('AMB-04','deployed'),  ('AMB-07','deployed'),  ('AMB-11','available'),
  ('AMB-15','available'), ('RB-03','deployed'),   ('HZ-01','returning'),
  ('NDRF-2','deployed'),  ('HR-02','available'),  ('RV-05','maintenance')
) AS v(code, s)
WHERE r.code = v.code AND r.status::text <> v.s;

-- ---------------------------------------------------------------------
-- 12. PIPELINE LOG  (incidentLog[] in mock-data, bound to INC-2026-0417)
-- ---------------------------------------------------------------------
INSERT INTO incident_log_events (incident_id, tone, message, actor, occurred_at)
SELECT i.id, l.tone::log_tone, l.msg, l.who::actor_kind,
       i.reported_at + (l.offs || ' seconds')::interval
FROM incidents i,
  LATERAL (VALUES
    ('ingest',   'Incident ingested — source: Citizen SMS, Surat',                       'system', 0),
    ('classify', 'Classified: Fire · Severity 89/100 · CRITICAL',                        'ai',     1),
    ('ingest',   'Geo-tagged: Pandesara industrial zone (21.170°N, 72.831°E)',           'system', 2),
    ('merge',    'Duplicate reports merged — 7 signals unified into INC-2026-0417',      'ai',     3),
    ('alert',    'Trapped-persons flag raised — priority escalated',                     'ai',     4),
    ('dispatch', 'Resources dispatched: FT-12, FT-19, AMB-04',                           'user',   6),
    ('dispatch', 'ETA computed — nearest tender 4 min',                                  'system', 9),
    ('resolve',  'Field officer acknowledged assignment',                                'user',  17)
  ) AS l(tone, msg, who, offs)
WHERE i.reference_code = 'INC-2026-0417';

-- ---------------------------------------------------------------------
-- 13. CORDON ZONES  (500 m gas-leak evacuation, 200 m fire cordon)
-- ---------------------------------------------------------------------
SELECT create_cordon(id, 500, 'evacuation') FROM incidents WHERE reference_code = 'INC-2026-0413';
SELECT create_cordon(id, 200, 'cordon')     FROM incidents WHERE reference_code = 'INC-2026-0417';

-- ---------------------------------------------------------------------
-- 14. COPILOT  (assistantConversation[] + ResQCopilot seed message)
-- ---------------------------------------------------------------------
INSERT INTO copilot_conversations (id, user_id, incident_id, title)
SELECT '99999999-9999-4999-8999-999999999999', u.id, i.id, 'INC-2026-0417 triage'
FROM users u, incidents i
WHERE u.employee_code = 'GSDMA-0114' AND i.reference_code = 'INC-2026-0417';

INSERT INTO copilot_messages (conversation_id, seq, role, label, content, confidence, model_name)
VALUES
  ('99999999-9999-4999-8999-999999999999', 1, 'user', NULL,
   'Summarise INC-2026-0417 and recommend next actions.', NULL, NULL),
  ('99999999-9999-4999-8999-999999999999', 2, 'assistant', 'Summary · confidence 94%',
   'INC-2026-0417 — Textile warehouse fire in Pandesara, Surat. Severity 89/100 (CRITICAL). 7 duplicate reports merged; consistent signal of workers trapped on the upper floor. Wind is pushing fire toward adjacent units.',
   0.940, 'resq-copilot-v1'),
  ('99999999-9999-4999-8999-999999999999', 3, 'assistant', 'Recommendation · based on live resource map',
   E'Recommended actions:\n1. Dispatch a 3rd tender — spread risk to units B-4/B-5 is rising.\n2. Pre-position AMB-11 (available, 6 min) for casualty overflow.\n3. Alert Surat Civil Hospital burns unit — expect 5-8 admissions.\n4. Establish 200m cordon; notify GEB to cut grid power to the block.',
   0.910, 'resq-copilot-v1'),
  ('99999999-9999-4999-8999-999999999999', 4, 'user', NULL,
   'Any resource conflict with the Rajkot gas leak?', NULL, NULL),
  ('99999999-9999-4999-8999-999999999999', 5, 'assistant', 'Cross-incident check · 2 districts',
   'No direct conflict. HazMat HZ-01 is committed to INC-2026-0413 (Rajkot) and is 210 km away. Surat has 2 idle tenders within 8 km — reallocating them will not affect Rajkot coverage.',
   0.880, 'resq-copilot-v1');

-- grounding: which live incidents the model actually read
INSERT INTO copilot_message_context (message_id, incident_id, relevance)
SELECT m.id, i.id, CASE WHEN i.reference_code = 'INC-2026-0417' THEN 1.000 ELSE 0.600 END
FROM copilot_messages m, incidents i
WHERE m.conversation_id = '99999999-9999-4999-8999-999999999999'
  AND m.role = 'assistant'
  AND i.reference_code IN ('INC-2026-0417','INC-2026-0413');

-- the four recommendation lines as actionable rows
INSERT INTO copilot_recommendations (message_id, incident_id, ordinal, action_text, action_kind,
                                     suggested_resource_id, suggested_facility_id)
SELECT m.id, i.id, v.ord, v.txt, v.kind,
       (SELECT id FROM resources  WHERE code = v.rcode),
       (SELECT id FROM facilities WHERE code = v.fcode)
FROM copilot_messages m
JOIN incidents i ON i.reference_code = 'INC-2026-0417',
LATERAL (VALUES
  (1,'Dispatch a 3rd tender — spread risk to units B-4/B-5 is rising.','dispatch',NULL,NULL),
  (2,'Pre-position AMB-11 (available, 6 min) for casualty overflow.','pre_position','AMB-11',NULL),
  (3,'Alert Surat Civil Hospital burns unit — expect 5-8 admissions.','alert_facility',NULL,'HOSP-SUR-001'),
  (4,'Establish 200m cordon; notify GEB to cut grid power to the block.','cordon',NULL,NULL)
) AS v(ord, txt, kind, rcode, fcode)
WHERE m.conversation_id = '99999999-9999-4999-8999-999999999999' AND m.seq = 3;

INSERT INTO incident_facility_alerts (incident_id, facility_id, expected_casualties, message)
SELECT i.id, f.id, 8, 'Burns unit standby — textile warehouse fire, trapped workers.'
FROM incidents i, facilities f
WHERE i.reference_code = 'INC-2026-0417' AND f.code = 'HOSP-SUR-001';

-- ---------------------------------------------------------------------
-- 15. NOTIFICATIONS  ("A coordinator has been notified.")
-- ---------------------------------------------------------------------
INSERT INTO notifications (recipient_user_id, incident_id, channel, severity, title, body,
                           delivery_status, sent_at)
SELECT u.id, i.id, 'in_app', i.severity,
       i.severity::text || ' incident in ' || d.name,
       i.title, 'delivered', i.reported_at + INTERVAL '3 seconds'
FROM incidents i
JOIN districts d ON d.id = i.district_id
JOIN users u ON u.home_district_id = i.district_id
WHERE i.status <> 'resolved';

-- ---------------------------------------------------------------------
-- 16. AUTH SESSION SAMPLE  (a live refresh token)
-- ---------------------------------------------------------------------
INSERT INTO refresh_tokens (user_id, token_hash, jti, expires_at, user_agent, ip_address)
SELECT id, digest('sample-refresh-token-do-not-use', 'sha256'),
       gen_random_uuid(), now() + INTERVAL '30 days',
       'Mozilla/5.0 (Macintosh) Chrome/140', '203.0.113.41'::inet
FROM users WHERE employee_code = 'GSDMA-0114';

INSERT INTO auth_events (user_id, event, ip_address)
SELECT id, 'login_success', '203.0.113.41'::inet FROM users WHERE employee_code = 'GSDMA-0114';

-- ---------------------------------------------------------------------
-- 17. DAILY ROLLUP (last 7 days, from the live rows)
-- ---------------------------------------------------------------------
INSERT INTO daily_metrics (metric_date, district_id, incident_type_id, total_incidents,
                           critical_count, high_count, moderate_count, low_count,
                           resolved_count, avg_response_min)
SELECT (i.reported_at AT TIME ZONE 'Asia/Kolkata')::date, i.district_id, i.incident_type_id,
       count(*),
       count(*) FILTER (WHERE i.severity = 'critical'),
       count(*) FILTER (WHERE i.severity = 'high'),
       count(*) FILTER (WHERE i.severity = 'moderate'),
       count(*) FILTER (WHERE i.severity = 'low'),
       count(*) FILTER (WHERE i.status   = 'resolved'),
       round(avg(extract(epoch FROM (i.first_dispatch_at - i.reported_at))/60.0)::numeric, 2)
FROM incidents i
GROUP BY 1, 2, 3;

COMMIT;

SELECT refresh_analytics();
ANALYZE;

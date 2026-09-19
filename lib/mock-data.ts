export type IncidentType =
  | 'Fire'
  | 'Flood'
  | 'Medical'
  | 'Accident'
  | 'Gas Leak'
  | 'Building Collapse'
  | 'Cyclone'

export type IncidentStatus = 'new' | 'dispatched' | 'in-progress' | 'resolved'

export type Severity = 'critical' | 'high' | 'moderate' | 'low'

export interface Incident {
  id: string
  type: IncidentType
  title: string
  district: string
  coord: string
  /** normalized position on the stylized tactical map, 0-100 */
  x: number
  y: number
  severityScore: number
  severity: Severity
  status: IncidentStatus
  reportedAt: string
  timestamp: number
  reporterType: string
  description: string
  duplicates: number
  assignedResources: string[]
}

export function severityFromScore(score: number): Severity {
  if (score >= 80) return 'critical'
  if (score >= 60) return 'high'
  if (score >= 35) return 'moderate'
  return 'low'
}

export const severityColor: Record<Severity, string> = {
  critical: 'var(--critical)',
  high: 'var(--warning)',
  moderate: 'var(--info)',
  low: 'var(--success)',
}

export const severityLabel: Record<Severity, string> = {
  critical: 'CRITICAL',
  high: 'HIGH',
  moderate: 'MODERATE',
  low: 'LOW',
}

export const statusLabel: Record<IncidentStatus, string> = {
  new: 'NEW',
  dispatched: 'DISPATCHED',
  'in-progress': 'IN PROGRESS',
  resolved: 'RESOLVED',
}

export const incidents: Incident[] = [
  {
    id: 'INC-2026-0417',
    type: 'Fire',
    title: 'Textile warehouse fire, Pandesara industrial zone',
    district: 'Surat',
    coord: '21.1702° N, 72.8311° E',
    x: 34,
    y: 62,
    severityScore: 89,
    severity: 'critical',
    status: 'in-progress',
    reportedAt: '09:41:03',
    timestamp: Date.now() - 1000 * 60 * 12,
    reporterType: 'Citizen (SMS)',
    description:
      'Multiple callers report heavy smoke and flames from a two-storey textile unit. Workers reportedly trapped on upper floor. Wind spreading fire to adjacent units.',
    duplicates: 7,
    assignedResources: ['Fire Tender FT-12', 'Fire Tender FT-19', 'Ambulance AMB-04'],
  },
  {
    id: 'INC-2026-0416',
    type: 'Flood',
    title: 'Urban flooding, Vishwamitri riverfront low-lying areas',
    district: 'Vadodara',
    coord: '22.3072° N, 73.1812° E',
    x: 46,
    y: 46,
    severityScore: 76,
    severity: 'high',
    status: 'dispatched',
    reportedAt: '09:38:55',
    timestamp: Date.now() - 1000 * 60 * 21,
    reporterType: 'Field Officer',
    description:
      'River crossing danger mark. Water entering ground floors of ~40 households. Evacuation of elderly and children required in Sayajipura ward.',
    duplicates: 4,
    assignedResources: ['Rescue Boat RB-03', 'NDRF Team NDRF-2'],
  },
  {
    id: 'INC-2026-0415',
    type: 'Medical',
    title: 'Mass heat-stroke cases at construction site',
    district: 'Ahmedabad',
    coord: '23.0225° N, 72.5714° E',
    x: 40,
    y: 33,
    severityScore: 64,
    severity: 'high',
    status: 'dispatched',
    reportedAt: '09:36:12',
    timestamp: Date.now() - 1000 * 60 * 33,
    reporterType: 'Site Supervisor (Call)',
    description:
      '11 labourers showing severe heat exhaustion symptoms at SG Highway project. Two unconscious. Nearest PHC over capacity.',
    duplicates: 2,
    assignedResources: ['Ambulance AMB-11', 'Ambulance AMB-15'],
  },
  {
    id: 'INC-2026-0414',
    type: 'Accident',
    title: 'Multi-vehicle collision on NH-48 near Bagodara',
    district: 'Ahmedabad',
    coord: '22.6890° N, 72.1500° E',
    x: 35,
    y: 40,
    severityScore: 58,
    severity: 'moderate',
    status: 'in-progress',
    reportedAt: '09:29:47',
    timestamp: Date.now() - 1000 * 60 * 47,
    reporterType: 'Highway Patrol',
    description:
      'Truck and two cars collided. Highway partially blocked. 3 injured, 1 critical. Fuel spillage reported — fire risk.',
    duplicates: 3,
    assignedResources: ['Ambulance AMB-07', 'Highway Rescue HR-02'],
  },
  {
    id: 'INC-2026-0413',
    type: 'Gas Leak',
    title: 'Industrial gas leak, GIDC estate',
    district: 'Rajkot',
    coord: '22.3039° N, 70.8022° E',
    x: 22,
    y: 44,
    severityScore: 82,
    severity: 'critical',
    status: 'dispatched',
    reportedAt: '09:24:30',
    timestamp: Date.now() - 1000 * 60 * 52,
    reporterType: 'Plant Safety Officer',
    description:
      'Chlorine leak detected at chemical unit. Downwind residential colony at risk. Immediate cordon and evacuation advised within 500m radius.',
    duplicates: 5,
    assignedResources: ['HazMat Unit HZ-01', 'Fire Tender FT-08'],
  },
  {
    id: 'INC-2026-0412',
    type: 'Building Collapse',
    title: 'Partial collapse of old residential structure',
    district: 'Surat',
    coord: '21.1959° N, 72.8302° E',
    x: 33,
    y: 60,
    severityScore: 71,
    severity: 'high',
    status: 'new',
    reportedAt: '09:19:08',
    timestamp: Date.now() - 1000 * 60 * 68,
    reporterType: 'Citizen (App)',
    description:
      'A section of a 40-year-old chawl collapsed after overnight rain. Unknown number of residents feared under debris.',
    duplicates: 6,
    assignedResources: [],
  },
  {
    id: 'INC-2026-0411',
    type: 'Medical',
    title: 'Cardiac emergency, no ambulance in ward',
    district: 'Vadodara',
    coord: '22.3200° N, 73.1900° E',
    x: 47,
    y: 45,
    severityScore: 44,
    severity: 'moderate',
    status: 'resolved',
    reportedAt: '09:02:41',
    timestamp: Date.now() - 1000 * 60 * 96,
    reporterType: 'Family Member (Call)',
    description:
      'Elderly patient with chest pain. Nearest ambulance rerouted. Patient stabilised and transported to SSG Hospital.',
    duplicates: 1,
    assignedResources: ['Ambulance AMB-09'],
  },
  {
    id: 'INC-2026-0410',
    type: 'Cyclone',
    title: 'Coastal wind damage, fishing hamlet',
    district: 'Rajkot',
    coord: '21.9800° N, 70.4000° E',
    x: 18,
    y: 52,
    severityScore: 51,
    severity: 'moderate',
    status: 'resolved',
    reportedAt: '08:47:19',
    timestamp: Date.now() - 1000 * 60 * 120,
    reporterType: 'Coast Guard',
    description:
      'Strong winds damaged temporary shelters. No casualties. Relief material and tarpaulin dispatched.',
    duplicates: 2,
    assignedResources: ['Relief Van RV-05'],
  },
]

export interface ResourceUnit {
  id: string
  type: string
  district: string
  status: 'available' | 'deployed' | 'returning' | 'maintenance'
  crew: number
}

export const resources: ResourceUnit[] = [
  { id: 'FT-12', type: 'Fire Tender', district: 'Surat', status: 'deployed', crew: 6 },
  { id: 'FT-19', type: 'Fire Tender', district: 'Surat', status: 'deployed', crew: 5 },
  { id: 'FT-08', type: 'Fire Tender', district: 'Rajkot', status: 'deployed', crew: 6 },
  { id: 'AMB-04', type: 'Ambulance', district: 'Surat', status: 'deployed', crew: 3 },
  { id: 'AMB-07', type: 'Ambulance', district: 'Ahmedabad', status: 'deployed', crew: 3 },
  { id: 'AMB-11', type: 'Ambulance', district: 'Ahmedabad', status: 'available', crew: 3 },
  { id: 'AMB-15', type: 'Ambulance', district: 'Ahmedabad', status: 'available', crew: 2 },
  { id: 'RB-03', type: 'Rescue Boat', district: 'Vadodara', status: 'deployed', crew: 4 },
  { id: 'HZ-01', type: 'HazMat Unit', district: 'Rajkot', status: 'returning', crew: 5 },
  { id: 'NDRF-2', type: 'NDRF Team', district: 'Vadodara', status: 'deployed', crew: 12 },
  { id: 'HR-02', type: 'Highway Rescue', district: 'Ahmedabad', status: 'available', crew: 4 },
  { id: 'RV-05', type: 'Relief Van', district: 'Rajkot', status: 'maintenance', crew: 2 },
]

export const districts = ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot']

export interface FeedEntry {
  time: string
  text: string
  tone: 'ingest' | 'classify' | 'merge' | 'dispatch' | 'resolve' | 'alert'
}

export const incidentLog: FeedEntry[] = [
  { time: '09:41:03', text: 'Incident ingested — source: Citizen SMS, Surat', tone: 'ingest' },
  { time: '09:41:04', text: 'Classified: Fire · Severity 89/100 · CRITICAL', tone: 'classify' },
  { time: '09:41:05', text: 'Geo-tagged: Pandesara industrial zone (21.170°N, 72.831°E)', tone: 'ingest' },
  { time: '09:41:06', text: 'Duplicate reports merged — 7 signals unified into INC-2026-0417', tone: 'merge' },
  { time: '09:41:07', text: 'Trapped-persons flag raised — priority escalated', tone: 'alert' },
  { time: '09:41:09', text: 'Resources dispatched: FT-12, FT-19, AMB-04', tone: 'dispatch' },
  { time: '09:41:12', text: 'ETA computed — nearest tender 4 min', tone: 'dispatch' },
  { time: '09:41:20', text: 'Field officer acknowledged assignment', tone: 'resolve' },
]

export interface ChatMessage {
  role: 'user' | 'assistant'
  content: string
  meta?: string
}

export const assistantConversation: ChatMessage[] = [
  {
    role: 'user',
    content: 'Summarise INC-2026-0417 and recommend next actions.',
  },
  {
    role: 'assistant',
    content:
      'INC-2026-0417 — Textile warehouse fire in Pandesara, Surat. Severity 89/100 (CRITICAL). 7 duplicate reports merged; consistent signal of workers trapped on the upper floor. Wind is pushing fire toward adjacent units.',
    meta: 'Summary · confidence 94%',
  },
  {
    role: 'assistant',
    content:
      'Recommended actions:\n1. Dispatch a 3rd tender — spread risk to units B-4/B-5 is rising.\n2. Pre-position AMB-11 (available, 6 min) for casualty overflow.\n3. Alert Surat Civil Hospital burns unit — expect 5-8 admissions.\n4. Establish 200m cordon; notify GEB to cut grid power to the block.',
    meta: 'Recommendation · based on live resource map',
  },
  {
    role: 'user',
    content: 'Any resource conflict with the Rajkot gas leak?',
  },
  {
    role: 'assistant',
    content:
      'No direct conflict. HazMat HZ-01 is committed to INC-2026-0413 (Rajkot) and is 210 km away. Surat has 2 idle tenders within 8 km — reallocating them will not affect Rajkot coverage.',
    meta: 'Cross-incident check · 2 districts',
  },
]

// analytics
export const incidentsByType = [
  { name: 'Fire', value: 34 },
  { name: 'Flood', value: 41 },
  { name: 'Medical', value: 58 },
  { name: 'Accident', value: 47 },
  { name: 'Gas Leak', value: 12 },
  { name: 'Collapse', value: 9 },
]

export const incidentsByDistrict = [
  { district: 'Ahmedabad', critical: 8, high: 14, moderate: 22 },
  { district: 'Surat', critical: 11, high: 12, moderate: 15 },
  { district: 'Vadodara', critical: 5, high: 9, moderate: 18 },
  { district: 'Rajkot', critical: 6, high: 7, moderate: 11 },
]

export const incidentsByHour = [
  { hour: '00', count: 4 },
  { hour: '03', count: 2 },
  { hour: '06', count: 7 },
  { hour: '09', count: 21 },
  { hour: '12', count: 28 },
  { hour: '15', count: 24 },
  { hour: '18', count: 33 },
  { hour: '21', count: 17 },
]

export const responseTimeTrend = [
  { day: 'Mon', minutes: 14.2 },
  { day: 'Tue', minutes: 12.8 },
  { day: 'Wed', minutes: 13.5 },
  { day: 'Thu', minutes: 11.1 },
  { day: 'Fri', minutes: 9.7 },
  { day: 'Sat', minutes: 10.3 },
  { day: 'Sun', minutes: 8.9 },
]

export const resourceUtilization = [
  { name: 'Deployed', value: 58 },
  { name: 'Available', value: 27 },
  { name: 'Returning', value: 9 },
  { name: 'Maintenance', value: 6 },
]

export const heroStats = [
  { label: 'Incidents coordinated', value: 12483, suffix: '' },
  { label: 'Avg. response time', value: 9.7, suffix: ' min' },
  { label: 'Duplicate reports merged', value: 38, suffix: '%' },
  { label: 'Districts online', value: 33, suffix: '' },
]

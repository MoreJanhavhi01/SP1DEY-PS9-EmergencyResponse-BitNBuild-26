'use client'

import { useMemo, useState } from 'react'
import Link from 'next/link'
import { CheckCircle2, MapPin, Send, ShieldCheck } from 'lucide-react'
import { cn } from '@/lib/utils'
import { buttonVariants } from '@/components/ui/button'
import {
  districts,
  severityFromScore,
  severityColor,
  severityLabel,
  type IncidentType,
} from '@/lib/mock-data'

const types: IncidentType[] = [
  'Fire',
  'Flood',
  'Medical',
  'Accident',
  'Gas Leak',
  'Building Collapse',
  'Cyclone',
]

const typeBaseScore: Record<IncidentType, number> = {
  Fire: 62,
  Flood: 48,
  Medical: 40,
  Accident: 38,
  'Gas Leak': 66,
  'Building Collapse': 70,
  Cyclone: 55,
}

const reporterTypes = [
  'Citizen',
  'Field Officer',
  '112 Operator',
  'Emergency Services',
]

const escalationKeywords = [
  'trapped',
  'unconscious',
  'children',
  'fire spreading',
  'multiple',
  'collapse',
  'leak',
  'critical',
  'blood',
  'not breathing',
  'drowning',
]

export function ReportForm() {
  const [type, setType] = useState<IncidentType>('Fire')
  const [district, setDistrict] = useState(districts[0])
  const [reporter, setReporter] = useState(reporterTypes[0])
  const [peopleAffected, setPeopleAffected] = useState(1)
  const [description, setDescription] = useState('')
  const [location, setLocation] = useState('')
  const [submitted, setSubmitted] = useState(false)

  const score = useMemo(() => {
    let s = typeBaseScore[type]
    const text = description.toLowerCase()
    const hits = escalationKeywords.filter((k) => text.includes(k)).length
    s += hits * 6
    if (peopleAffected >= 10) s += 18
    else if (peopleAffected >= 4) s += 10
    else if (peopleAffected >= 2) s += 4
    if (reporter === 'Emergency Services' || reporter === 'Field Officer') s += 5
    if (description.length > 120) s += 3
    return Math.max(8, Math.min(100, Math.round(s)))
  }, [type, description, peopleAffected, reporter])

  const severity = severityFromScore(score)
  const color = severityColor[severity]

  if (submitted) {
    return (
      <div className="rounded-lg border border-success/30 bg-success/[0.05] p-8 text-center">
        <span className="mx-auto flex size-14 items-center justify-center rounded-full bg-success/15 text-success">
          <CheckCircle2 className="size-7" />
        </span>
        <h2 className="mt-4 text-xl font-semibold">Report received</h2>
        <p className="mx-auto mt-2 max-w-md text-sm text-muted-foreground">
          Your report has been ingested, classified and placed in the live
          queue. A coordinator has been notified.
        </p>
        <div className="mx-auto mt-5 flex max-w-xs flex-col gap-2 rounded-md border border-border bg-card p-4 text-left font-mono text-xs">
          <Row label="Reference" value={`INC-2026-${Math.floor(1000 + Math.random() * 8999)}`} />
          <Row label="Type" value={type} />
          <Row label="District" value={district} />
          <Row label="Severity" value={`${severityLabel[severity]} · ${score}/100`} />
          <Row label="Status" value="QUEUED FOR DISPATCH" />
        </div>
        <div className="mt-6 flex items-center justify-center gap-3">
          <button
            type="button"
            onClick={() => {
              setSubmitted(false)
              setDescription('')
              setLocation('')
              setPeopleAffected(1)
            }}
            className={cn(buttonVariants({ variant: 'outline' }), 'h-9 px-4')}
          >
            Report another
          </button>
          <Link href="/dashboard" className={cn(buttonVariants(), 'h-9 px-4')}>
            View dashboard
          </Link>
        </div>
      </div>
    )
  }

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault()
        setSubmitted(true)
      }}
      className="grid gap-6 lg:grid-cols-[1fr_320px] lg:items-start"
    >
      <div className="space-y-5 rounded-lg border border-border bg-card p-6">
        <Field label="Emergency type">
          <div className="flex flex-wrap gap-2">
            {types.map((t) => (
              <button
                key={t}
                type="button"
                onClick={() => setType(t)}
                className={cn(
                  'rounded-md border px-3 py-1.5 text-sm transition-colors',
                  type === t
                    ? 'border-primary bg-primary/10 text-foreground'
                    : 'border-border text-muted-foreground hover:text-foreground',
                )}
              >
                {t}
              </button>
            ))}
          </div>
        </Field>

        <div className="grid gap-5 sm:grid-cols-2">
          <Field label="District">
            <Select value={district} onChange={setDistrict} options={districts} />
          </Field>
          <Field label="Reporting as">
            <Select value={reporter} onChange={setReporter} options={reporterTypes} />
          </Field>
        </div>

        <Field label="Location / landmark">
          <div className="flex items-center gap-2 rounded-md border border-input bg-background px-3">
            <MapPin className="size-4 text-muted-foreground" />
            <input
              value={location}
              onChange={(e) => setLocation(e.target.value)}
              placeholder="e.g. Pandesara GIDC, near gate 3"
              className="h-10 flex-1 bg-transparent text-sm outline-none placeholder:text-muted-foreground/60"
            />
          </div>
        </Field>

        <Field label={`People affected (approx.) · ${peopleAffected}`}>
          <input
            type="range"
            min={1}
            max={50}
            value={peopleAffected}
            onChange={(e) => setPeopleAffected(Number(e.target.value))}
            className="w-full accent-[var(--primary)]"
          />
          <div className="flex justify-between font-mono text-[10px] text-muted-foreground">
            <span>1</span>
            <span>25</span>
            <span>50+</span>
          </div>
        </Field>

        <Field label="What is happening?">
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            rows={4}
            placeholder="Describe the situation. Mention if anyone is trapped, injured or in immediate danger."
            className="w-full resize-none rounded-md border border-input bg-background px-3 py-2.5 text-sm outline-none placeholder:text-muted-foreground/60 focus:border-ring"
          />
        </Field>

        <button
          type="submit"
          className={cn(buttonVariants(), 'h-10 w-full gap-2 text-sm font-semibold')}
        >
          <Send className="size-4" />
          Submit emergency report
        </button>
        <p className="flex items-center justify-center gap-1.5 text-center text-[11px] text-muted-foreground">
          <ShieldCheck className="size-3.5" />
          For life-threatening emergencies always call 112 directly.
        </p>
      </div>

      {/* live estimate */}
      <div className="space-y-4 rounded-lg border border-border bg-card p-6 lg:sticky lg:top-24">
        <span className="font-mono text-[11px] uppercase tracking-widest text-muted-foreground">
          Live AI estimate
        </span>

        <div className="relative flex flex-col items-center py-2">
          <svg viewBox="0 0 120 120" className="size-40 -rotate-90">
            <circle cx="60" cy="60" r="52" fill="none" stroke="var(--border)" strokeWidth="8" />
            <circle
              cx="60"
              cy="60"
              r="52"
              fill="none"
              stroke={color}
              strokeWidth="8"
              strokeLinecap="round"
              strokeDasharray={2 * Math.PI * 52}
              strokeDashoffset={2 * Math.PI * 52 * (1 - score / 100)}
              style={{
                transition: 'stroke-dashoffset 0.5s ease, stroke 0.4s ease',
                filter: `drop-shadow(0 0 6px ${color})`,
              }}
            />
          </svg>
          <div className="absolute inset-0 flex flex-col items-center justify-center">
            <span className="font-mono text-4xl font-bold" style={{ color }}>
              {score}
            </span>
            <span className="font-mono text-[10px] tracking-widest text-muted-foreground">
              / 100
            </span>
          </div>
        </div>

        <div
          className="rounded-md border px-3 py-2 text-center font-mono text-xs font-medium tracking-widest"
          style={{ borderColor: color, color }}
        >
          {severityLabel[severity]} PRIORITY
        </div>

        <ul className="space-y-2 text-xs text-muted-foreground">
          <EstimateRow label="Base risk" value={type} />
          <EstimateRow
            label="Scale factor"
            value={peopleAffected >= 10 ? 'High' : peopleAffected >= 4 ? 'Medium' : 'Low'}
          />
          <EstimateRow
            label="Signal keywords"
            value={`${escalationKeywords.filter((k) => description.toLowerCase().includes(k)).length} detected`}
          />
          <EstimateRow label="Source weight" value={reporter} />
        </ul>

        <p className="text-[11px] leading-relaxed text-muted-foreground">
          The queue re-ranks automatically as you type. Coordinators see this
          score the instant you submit.
        </p>
      </div>
    </form>
  )
}

function Field({
  label,
  children,
}: {
  label: string
  children: React.ReactNode
}) {
  return (
    <div className="space-y-2">
      <label className="block text-sm font-medium text-foreground/90">
        {label}
      </label>
      {children}
    </div>
  )
}

function Select({
  value,
  onChange,
  options,
}: {
  value: string
  onChange: (v: string) => void
  options: string[]
}) {
  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value)}
      className="h-10 w-full rounded-md border border-input bg-background px-3 text-sm outline-none focus:border-ring"
    >
      {options.map((o) => (
        <option key={o} value={o} className="bg-background">
          {o}
        </option>
      ))}
    </select>
  )
}

function EstimateRow({ label, value }: { label: string; value: string }) {
  return (
    <li className="flex items-center justify-between gap-2 border-b border-border/60 pb-2">
      <span>{label}</span>
      <span className="font-mono text-[11px] text-foreground/80">{value}</span>
    </li>
  )
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-2">
      <span className="text-muted-foreground">{label}</span>
      <span className="text-foreground">{value}</span>
    </div>
  )
}

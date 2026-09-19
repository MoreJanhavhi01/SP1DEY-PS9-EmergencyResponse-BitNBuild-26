'use client'

import { useState } from 'react'
import { Clock, MapPin, Radio, Users } from 'lucide-react'
import { cn } from '@/lib/utils'
import {
  incidents,
  resources,
  type ResourceUnit,
} from '@/lib/mock-data'
import { TacticalMap } from '@/components/tactical-map'
import { SeverityTag, StatusTag } from '@/components/status-tags'
import { CountUp } from '@/components/count-up'

const resourceStatusColor: Record<ResourceUnit['status'], string> = {
  available: 'text-success',
  deployed: 'text-critical',
  returning: 'text-info',
  maintenance: 'text-muted-foreground',
}

export function DashboardView() {
  const [selectedId, setSelectedId] = useState<string>(incidents[0].id)
  const [filter, setFilter] = useState<'all' | 'active'>('active')

  const filtered =
    filter === 'active'
      ? incidents.filter((i) => i.status !== 'resolved')
      : incidents

  const selected = incidents.find((i) => i.id === selectedId) ?? incidents[0]

  const activeCount = incidents.filter((i) => i.status !== 'resolved').length
  const criticalCount = incidents.filter((i) => i.severity === 'critical' && i.status !== 'resolved').length
  const availableUnits = resources.filter((r) => r.status === 'available').length

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
      <div className="flex flex-col gap-1 border-b border-border pb-6">
        <h1 className="text-2xl font-semibold tracking-tight">
          Operations Dashboard
        </h1>
        <p className="text-sm text-muted-foreground">
          Live view of every incident, resource and dispatch across Gujarat.
        </p>
      </div>

      {/* stat strip */}
      <div className="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-4">
        <StatCard label="Active incidents" value={activeCount} tone="warning" />
        <StatCard label="Critical now" value={criticalCount} tone="critical" />
        <StatCard label="Units available" value={availableUnits} tone="success" />
        <StatCard label="Avg response" value={9.7} suffix=" min" decimals={1} tone="info" />
      </div>

      <div className="mt-6 grid gap-4 lg:grid-cols-[1.4fr_1fr]">
        {/* map + resources */}
        <div className="flex flex-col gap-4">
          <div className="relative h-[26rem]">
            <TacticalMap
              incidents={incidents}
              selectedId={selectedId}
              onSelect={setSelectedId}
              fine
            />
            <div className="pointer-events-none absolute left-4 top-4 flex items-center gap-2 rounded-md border border-border bg-background/80 px-3 py-1.5 font-mono text-[11px] tracking-wider text-muted-foreground backdrop-blur">
              <Radio className="size-3.5 text-primary" />
              TAP A MARKER TO INSPECT
            </div>
          </div>

          <div className="rounded-lg border border-border bg-card">
            <div className="border-b border-border px-4 py-3">
              <h2 className="font-mono text-[11px] uppercase tracking-widest text-muted-foreground">
                Resource status · {resources.length} units
              </h2>
            </div>
            <div className="grid grid-cols-2 gap-px bg-border sm:grid-cols-3">
              {resources.map((r) => (
                <div key={r.id} className="bg-card px-3 py-2.5">
                  <div className="flex items-center justify-between">
                    <span className="font-mono text-xs font-medium">{r.id}</span>
                    <span
                      className={cn(
                        'size-1.5 rounded-full bg-current',
                        resourceStatusColor[r.status],
                      )}
                    />
                  </div>
                  <div className="mt-0.5 truncate text-[11px] text-muted-foreground">
                    {r.type} · {r.district}
                  </div>
                  <div
                    className={cn(
                      'mt-0.5 font-mono text-[10px] uppercase tracking-wider',
                      resourceStatusColor[r.status],
                    )}
                  >
                    {r.status}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* right column: queue + detail */}
        <div className="flex flex-col gap-4">
          <div className="rounded-lg border border-border bg-card">
            <div className="flex items-center justify-between border-b border-border px-4 py-3">
              <h2 className="font-mono text-[11px] uppercase tracking-widest text-muted-foreground">
                Incident queue
              </h2>
              <div className="flex items-center gap-1 rounded-md border border-border p-0.5">
                {(['active', 'all'] as const).map((f) => (
                  <button
                    key={f}
                    type="button"
                    onClick={() => setFilter(f)}
                    className={cn(
                      'rounded px-2 py-0.5 font-mono text-[10px] uppercase tracking-wider transition-colors',
                      filter === f
                        ? 'bg-accent text-foreground'
                        : 'text-muted-foreground hover:text-foreground',
                    )}
                  >
                    {f}
                  </button>
                ))}
              </div>
            </div>
            <div className="max-h-96 divide-y divide-border overflow-y-auto" style={{ scrollbarWidth: 'thin' }}>
              {filtered.map((inc) => (
                <button
                  key={inc.id}
                  type="button"
                  onClick={() => setSelectedId(inc.id)}
                  className={cn(
                    'flex w-full flex-col gap-1.5 px-4 py-3 text-left transition-colors hover:bg-accent/50',
                    selectedId === inc.id && 'bg-accent/60',
                  )}
                >
                  <div className="flex items-center justify-between gap-2">
                    <span className="font-mono text-[11px] text-muted-foreground">
                      {inc.id}
                    </span>
                    <StatusTag status={inc.status} />
                  </div>
                  <div className="flex items-center justify-between gap-2">
                    <span className="text-sm font-medium leading-tight">
                      {inc.type} · {inc.district}
                    </span>
                    <SeverityTag severity={inc.severity} score={inc.severityScore} />
                  </div>
                  <span className="line-clamp-1 text-xs text-muted-foreground">
                    {inc.title}
                  </span>
                </button>
              ))}
            </div>
          </div>

          <IncidentDetail incident={selected} />
        </div>
      </div>
    </div>
  )
}

function StatCard({
  label,
  value,
  suffix = '',
  decimals = 0,
  tone,
}: {
  label: string
  value: number
  suffix?: string
  decimals?: number
  tone: 'critical' | 'warning' | 'success' | 'info'
}) {
  const toneColor = {
    critical: 'text-critical',
    warning: 'text-warning',
    success: 'text-success',
    info: 'text-info',
  }[tone]
  return (
    <div className="rounded-lg border border-border bg-card px-4 py-3">
      <div className={cn('font-mono text-2xl font-semibold', toneColor)}>
        <CountUp value={value} suffix={suffix} decimals={decimals} />
      </div>
      <div className="mt-0.5 text-xs text-muted-foreground">{label}</div>
    </div>
  )
}

function IncidentDetail({ incident }: { incident: (typeof incidents)[number] }) {
  return (
    <div className="rounded-lg border border-border bg-card">
      <div className="flex items-start justify-between gap-3 border-b border-border px-4 py-3">
        <div>
          <div className="flex items-center gap-2">
            <span className="font-mono text-[11px] text-muted-foreground">
              {incident.id}
            </span>
            <StatusTag status={incident.status} />
          </div>
          <h3 className="mt-1 text-sm font-semibold leading-tight">
            {incident.title}
          </h3>
        </div>
        <SeverityTag severity={incident.severity} score={incident.severityScore} />
      </div>
      <div className="space-y-3 px-4 py-4">
        <p className="text-sm leading-relaxed text-muted-foreground">
          {incident.description}
        </p>
        <dl className="grid grid-cols-2 gap-3 text-xs">
          <Meta icon={MapPin} label="Location" value={`${incident.district}`} sub={incident.coord} />
          <Meta icon={Clock} label="Reported" value={incident.reportedAt} sub={incident.reporterType} />
          <Meta icon={Radio} label="Merged reports" value={`${incident.duplicates} signals`} />
          <Meta icon={Users} label="Assigned" value={`${incident.assignedResources.length} units`} />
        </dl>
        {incident.assignedResources.length > 0 && (
          <div className="flex flex-wrap gap-1.5 pt-1">
            {incident.assignedResources.map((r) => (
              <span
                key={r}
                className="rounded-sm border border-border bg-surface px-2 py-0.5 font-mono text-[10px] tracking-wider text-foreground/80"
              >
                {r}
              </span>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

function Meta({
  icon: Icon,
  label,
  value,
  sub,
}: {
  icon: React.ComponentType<{ className?: string }>
  label: string
  value: string
  sub?: string
}) {
  return (
    <div className="flex gap-2">
      <Icon className="mt-0.5 size-3.5 shrink-0 text-primary" />
      <div className="min-w-0">
        <dt className="font-mono text-[10px] uppercase tracking-wider text-muted-foreground">
          {label}
        </dt>
        <dd className="truncate text-foreground">{value}</dd>
        {sub && <dd className="truncate text-[11px] text-muted-foreground">{sub}</dd>}
      </div>
    </div>
  )
}

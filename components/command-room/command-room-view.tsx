'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { ArrowLeft, Maximize2 } from 'lucide-react'
import { cn } from '@/lib/utils'
import { incidents, resources } from '@/lib/mock-data'
import { TacticalMap } from '@/components/tactical-map'
import { IncidentLogFeed } from '@/components/incident-log-feed'
import { SeverityTag, StatusTag } from '@/components/status-tags'
import { LiveBadge } from '@/components/brand'

function useClock() {
  const [now, setNow] = useState<Date | null>(null)
  useEffect(() => {
    setNow(new Date())
    const t = setInterval(() => setNow(new Date()), 1000)
    return () => clearInterval(t)
  }, [])
  return now
}

export function CommandRoomView() {
  const now = useClock()
  const active = incidents.filter((i) => i.status !== 'resolved')
  const critical = active.filter((i) => i.severity === 'critical')
  const deployed = resources.filter((r) => r.status === 'deployed').length
  const available = resources.filter((r) => r.status === 'available').length

  const clock = now
    ? now.toLocaleTimeString('en-GB', { hour12: false })
    : '--:--:--'
  const date = now
    ? now.toLocaleDateString('en-IN', {
        weekday: 'short',
        day: '2-digit',
        month: 'short',
        year: 'numeric',
      })
    : ''

  return (
    <div className="flex min-h-dvh flex-col bg-background bg-scanlines">
      {/* command bar */}
      <header className="flex items-center justify-between gap-4 border-b border-border px-5 py-3">
        <div className="flex items-center gap-4">
          <Link
            href="/"
            className="inline-flex size-8 items-center justify-center rounded-md border border-border text-muted-foreground transition-colors hover:text-foreground"
            aria-label="Exit command room"
          >
            <ArrowLeft className="size-4" />
          </Link>
          <div className="flex items-center gap-2.5">
            <span className="font-mono text-sm font-semibold tracking-widest text-primary">
              RESQ COMMAND ROOM
            </span>
            <LiveBadge label="ACTIVE EVENT" />
          </div>
        </div>
        <div className="flex items-center gap-5">
          <div className="text-right">
            <div className="font-mono text-lg font-semibold leading-none tabular-nums">
              {clock}
            </div>
            <div className="font-mono text-[10px] uppercase tracking-widest text-muted-foreground">
              {date} · IST
            </div>
          </div>
          <Maximize2 className="hidden size-4 text-muted-foreground sm:block" />
        </div>
      </header>

      {/* wall grid */}
      <div className="grid flex-1 gap-3 p-3 lg:grid-cols-[280px_1fr_320px]">
        {/* left rail: big counters */}
        <div className="flex flex-col gap-3">
          <WallCounter label="ACTIVE" value={active.length} tone="warning" />
          <WallCounter label="CRITICAL" value={critical.length} tone="critical" pulse />
          <WallCounter label="DEPLOYED" value={deployed} tone="info" />
          <WallCounter label="AVAILABLE" value={available} tone="success" />
        </div>

        {/* center: giant map */}
        <div className="relative min-h-[24rem]">
          <TacticalMap incidents={incidents} showSweep fine />
          <div className="pointer-events-none absolute left-4 top-4 rounded-md border border-border bg-background/80 px-3 py-1.5 font-mono text-[11px] tracking-widest text-muted-foreground backdrop-blur">
            GUJARAT · STATE OPERATIONS PICTURE
          </div>
        </div>

        {/* right rail: priority list */}
        <div className="flex flex-col gap-3">
          <div className="flex-1 overflow-hidden rounded-lg border border-border bg-card">
            <div className="border-b border-border px-4 py-2.5">
              <h2 className="font-mono text-[11px] uppercase tracking-widest text-muted-foreground">
                Priority board
              </h2>
            </div>
            <div className="divide-y divide-border overflow-y-auto" style={{ scrollbarWidth: 'thin' }}>
              {[...active]
                .sort((a, b) => b.severityScore - a.severityScore)
                .map((inc) => (
                  <div key={inc.id} className="flex flex-col gap-1 px-4 py-2.5">
                    <div className="flex items-center justify-between gap-2">
                      <span className="font-mono text-[11px] text-muted-foreground">
                        {inc.id}
                      </span>
                      <StatusTag status={inc.status} />
                    </div>
                    <div className="flex items-center justify-between gap-2">
                      <span className="text-xs font-medium">
                        {inc.type} · {inc.district}
                      </span>
                      <SeverityTag severity={inc.severity} score={inc.severityScore} />
                    </div>
                  </div>
                ))}
            </div>
          </div>
        </div>
      </div>

      {/* bottom: live pipeline */}
      <div className="border-t border-border p-3 pt-0">
        <IncidentLogFeed className="border-t-0" intervalMs={750} />
      </div>
    </div>
  )
}

function WallCounter({
  label,
  value,
  tone,
  pulse = false,
}: {
  label: string
  value: number
  tone: 'critical' | 'warning' | 'success' | 'info'
  pulse?: boolean
}) {
  const toneColor = {
    critical: 'text-critical',
    warning: 'text-warning',
    success: 'text-success',
    info: 'text-info',
  }[tone]
  const glow = {
    critical: '0 0 30px oklch(0.62 0.21 25 / 0.35)',
    warning: '0 0 30px oklch(0.78 0.15 66 / 0.3)',
    success: '0 0 30px oklch(0.68 0.15 155 / 0.25)',
    info: '0 0 30px oklch(0.7 0.12 230 / 0.25)',
  }[tone]

  return (
    <div className="flex flex-1 flex-col justify-center rounded-lg border border-border bg-card px-5 py-4">
      <span className="font-mono text-[11px] uppercase tracking-widest text-muted-foreground">
        {label}
      </span>
      <span
        className={cn(
          'mt-1 font-mono text-5xl font-bold tabular-nums lg:text-6xl',
          toneColor,
          pulse && 'animate-live-blink',
        )}
        style={{ textShadow: glow }}
      >
        {String(value).padStart(2, '0')}
      </span>
    </div>
  )
}

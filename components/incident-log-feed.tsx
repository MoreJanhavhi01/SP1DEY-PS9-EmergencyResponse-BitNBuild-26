'use client'

import { useEffect, useRef, useState } from 'react'
import { cn } from '@/lib/utils'
import { incidentLog, type FeedEntry } from '@/lib/mock-data'

const toneColor: Record<FeedEntry['tone'], string> = {
  ingest: 'text-muted-foreground',
  classify: 'text-info',
  merge: 'text-primary',
  dispatch: 'text-success',
  resolve: 'text-foreground',
  alert: 'text-critical',
}

const toneLabel: Record<FeedEntry['tone'], string> = {
  ingest: 'INGEST',
  classify: 'CLASSIFY',
  merge: 'MERGE',
  dispatch: 'DISPATCH',
  resolve: 'ACK',
  alert: 'ALERT',
}

export function IncidentLogFeed({
  entries = incidentLog,
  loop = true,
  className,
  intervalMs = 900,
}: {
  entries?: FeedEntry[]
  loop?: boolean
  className?: string
  intervalMs?: number
}) {
  const [count, setCount] = useState(0)
  const containerRef = useRef<HTMLDivElement>(null)
  const [started, setStarted] = useState(false)

  useEffect(() => {
    const el = containerRef.current
    if (!el) return
    const obs = new IntersectionObserver(
      ([e]) => {
        if (e.isIntersecting) setStarted(true)
      },
      { threshold: 0.35 },
    )
    obs.observe(el)
    return () => obs.disconnect()
  }, [])

  useEffect(() => {
    if (!started) return
    const timer = setInterval(() => {
      setCount((c) => {
        if (c >= entries.length) {
          return loop ? 0 : c
        }
        return c + 1
      })
    }, intervalMs)
    return () => clearInterval(timer)
  }, [started, entries.length, loop, intervalMs])

  const visible = entries.slice(0, count)

  return (
    <div
      ref={containerRef}
      className={cn(
        'relative overflow-hidden rounded-lg border border-border bg-[oklch(0.14_0.006_60)] font-mono text-xs',
        className,
      )}
    >
      <div className="flex items-center justify-between border-b border-border bg-surface/60 px-4 py-2">
        <div className="flex items-center gap-2">
          <span className="size-2 rounded-full bg-critical/70" />
          <span className="size-2 rounded-full bg-warning/70" />
          <span className="size-2 rounded-full bg-success/70" />
        </div>
        <span className="text-[10px] tracking-widest text-muted-foreground">
          resq://ingest-pipeline
        </span>
      </div>
      <div className="min-h-64 space-y-1.5 p-4">
        {visible.map((entry, i) => (
          <div
            key={`${entry.time}-${i}`}
            className="animate-feed-in flex items-start gap-3 leading-relaxed"
          >
            <span className="shrink-0 text-muted-foreground/70">
              {entry.time}
            </span>
            <span
              className={cn(
                'shrink-0 w-16 text-[10px] tracking-wider opacity-90',
                toneColor[entry.tone],
              )}
            >
              [{toneLabel[entry.tone]}]
            </span>
            <span className={cn('flex-1', toneColor[entry.tone])}>
              {entry.text}
            </span>
          </div>
        ))}
        {count < entries.length && (
          <div className="flex items-center gap-2 pt-0.5 text-primary">
            <span className="text-muted-foreground/70">
              {entries[count]?.time ?? '········'}
            </span>
            <span className="inline-block h-3.5 w-2 animate-pulse bg-primary" />
          </div>
        )}
      </div>
    </div>
  )
}

'use client'

import { useEffect, useState } from 'react'
import { cn } from '@/lib/utils'
import { incidents } from '@/lib/mock-data'
import { SeverityTag } from '@/components/status-tags'
import { LiveBadge } from '@/components/brand'

export function LiveFeedPanel({ className }: { className?: string }) {
  // rotate a "just in" highlight for a live feel
  const [highlight, setHighlight] = useState(0)

  useEffect(() => {
    const t = setInterval(() => {
      setHighlight((h) => (h + 1) % incidents.length)
    }, 2600)
    return () => clearInterval(t)
  }, [])

  return (
    <div
      className={cn(
        'flex flex-col overflow-hidden rounded-lg border border-border bg-card/90 backdrop-blur-sm',
        className,
      )}
    >
      <div className="flex items-center justify-between border-b border-border px-4 py-3">
        <span className="font-mono text-[11px] uppercase tracking-widest text-muted-foreground">
          Live incident feed
        </span>
        <LiveBadge />
      </div>
      <div
        className="flex-1 divide-y divide-border overflow-y-auto"
        style={{ scrollbarWidth: 'thin' }}
      >
        {incidents.map((inc, i) => (
          <div
            key={inc.id}
            className={cn(
              'flex flex-col gap-1.5 px-4 py-3 transition-colors',
              i === highlight ? 'bg-primary/5' : 'bg-transparent',
            )}
          >
            <div className="flex items-center justify-between gap-2">
              <span className="font-mono text-[11px] text-muted-foreground">
                {inc.id}
              </span>
              <span className="font-mono text-[11px] text-muted-foreground">
                {inc.reportedAt}
              </span>
            </div>
            <div className="flex items-center justify-between gap-2">
              <span className="text-sm font-medium leading-tight">
                {inc.type}
              </span>
              <SeverityTag severity={inc.severity} score={inc.severityScore} />
            </div>
            <span className="truncate text-xs text-muted-foreground">
              {inc.district} · {inc.title}
            </span>
          </div>
        ))}
      </div>
    </div>
  )
}

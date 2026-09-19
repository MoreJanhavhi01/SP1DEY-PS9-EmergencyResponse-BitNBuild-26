'use client'

import { cn } from '@/lib/utils'
import {
  type Incident,
  type Severity,
  severityColor,
} from '@/lib/mock-data'

const districtNodes: Record<string, { x: number; y: number }> = {
  Bhuj: { x: 10, y: 31 },
  Jamnagar: { x: 18, y: 48 },
  Rajkot: { x: 27, y: 54 },
  Ahmedabad: { x: 48, y: 48 },
  Gandhinagar: { x: 49, y: 43 },
  Vadodara: { x: 60, y: 61 },
  Bhavnagar: { x: 67, y: 58 },
  Surat: { x: 66, y: 78 },
}

function markerSize(severity: Severity) {
  switch (severity) {
    case 'critical':
      return 16
    case 'high':
      return 13
    case 'moderate':
      return 11
    default:
      return 9
  }
}

export function TacticalMap({
  incidents,
  selectedId,
  onSelect,
  showSweep = true,
  className,
  fine = false,
}: {
  incidents: Incident[]
  selectedId?: string | null
  onSelect?: (id: string) => void
  showSweep?: boolean
  className?: string
  fine?: boolean
}) {
  return (
    <div
      className={cn(
        'relative isolate size-full overflow-hidden rounded-lg border border-border bg-surface',
        fine ? 'bg-radar-grid-fine' : 'bg-radar-grid',
        className,
      )}
    >
      {/* stylized region silhouette */}
      <svg
        viewBox="0 0 100 100"
        preserveAspectRatio="none"
        className="absolute inset-0 size-full opacity-[0.5]"
        aria-hidden="true"
      >
        <path
          d="M7 25 L15 18 L26 20 L36 14 L48 18 L57 14 L65 20 L76 17 L86 25 L82 34 L91 41 L84 49 L88 58 L78 63 L76 72 L69 80 L62 77 L57 87 L49 82 L43 88 L37 80 L30 78 L25 70 L18 68 L20 59 L12 53 L16 45 L9 39 L13 32 Z"
          fill="oklch(0.24 0.01 66 / 0.5)"
          stroke="oklch(0.78 0.15 66 / 0.35)"
          strokeWidth="0.4"
        />
      </svg>

      {/* radar sweep */}
      {showSweep && (
        <div className="pointer-events-none absolute left-1/2 top-1/2 aspect-square w-[130%] -translate-x-1/2 -translate-y-1/2">
          <div
            className="animate-radar-sweep size-full rounded-full"
            style={{
              background:
                'conic-gradient(from 0deg, transparent 0deg, oklch(0.78 0.15 66 / 0.12) 40deg, transparent 60deg)',
            }}
          />
        </div>
      )}

      {/* crosshair lines */}
      <div className="pointer-events-none absolute inset-0">
        <div className="absolute left-1/2 top-0 h-full w-px bg-primary/10" />
        <div className="absolute left-0 top-1/2 h-px w-full bg-primary/10" />
      </div>

      {/* major Gujarat city labels */}
      {Object.keys(districtNodes).map((d) => {
        const node = districtNodes[d]
        return (
          <div
            key={d}
            className="pointer-events-none absolute -translate-x-1/2 -translate-y-1/2"
            style={{ left: `${node.x}%`, top: `${node.y}%` }}
          >
            <div className="flex flex-col items-center gap-1">
              <span className="size-1 rounded-full bg-muted-foreground/60 ring-2 ring-muted-foreground/10" />
              <span className="font-mono text-[9px] uppercase tracking-widest text-muted-foreground/70">
                {d}
              </span>
            </div>
          </div>
        )
      })}

      {/* incident markers */}
      {incidents.map((inc) => {
        const size = markerSize(inc.severity)
        const color = severityColor[inc.severity]
        const selected = selectedId === inc.id
        return (
          <button
            key={inc.id}
            type="button"
            onClick={() => onSelect?.(inc.id)}
            className={cn(
              'group absolute -translate-x-1/2 -translate-y-1/2 rounded-full outline-none transition-transform focus-visible:ring-2 focus-visible:ring-primary',
              onSelect ? 'cursor-pointer hover:scale-125' : 'cursor-default',
            )}
            style={{ left: `${inc.x}%`, top: `${inc.y}%` }}
            aria-label={`${inc.type} in ${inc.district}, severity ${inc.severityScore}`}
            tabIndex={onSelect ? 0 : -1}
          >
            {inc.status !== 'resolved' && (
              <span
                className="animate-marker-pulse absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 rounded-full"
                style={{
                  width: size,
                  height: size,
                  backgroundColor: color,
                }}
              />
            )}
            <span
              className={cn(
                'relative block rounded-full ring-2',
                selected ? 'ring-white' : 'ring-black/40',
              )}
              style={{
                width: size,
                height: size,
                backgroundColor: color,
                boxShadow: `0 0 12px ${color}`,
              }}
            />
            <span className="pointer-events-none absolute left-1/2 top-full mt-1.5 -translate-x-1/2 whitespace-nowrap rounded-sm border border-border bg-background/95 px-1.5 py-0.5 font-mono text-[9px] text-foreground opacity-0 transition-opacity group-hover:opacity-100">
              {inc.id}
            </span>
          </button>
        )
      })}
    </div>
  )
}

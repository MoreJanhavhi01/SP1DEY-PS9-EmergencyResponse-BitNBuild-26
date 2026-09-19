'use client'

import Link from 'next/link'
import { ArrowRight } from 'lucide-react'
import { cn } from '@/lib/utils'
import { buttonVariants } from '@/components/ui/button'
import { TacticalMap } from '@/components/tactical-map'
import { LiveFeedPanel } from '@/components/live-feed-panel'
import { CountUp } from '@/components/count-up'
import { incidents, heroStats } from '@/lib/mock-data'
import { SiteNavContent } from '@/components/site-nav'

export function Hero() {
  return (
    <section className="relative overflow-hidden border-b border-border bg-scanlines">
      <div className="pointer-events-none absolute inset-0 bg-radar-grid opacity-40" />
      <div className="pointer-events-none absolute -top-40 left-1/2 h-80 w-[80%] -translate-x-1/2 rounded-full bg-primary/10 blur-3xl" />

      <SiteNavContent />

      <div className="relative mx-auto max-w-7xl px-4 pb-8 pt-10 sm:px-6 lg:pt-14">
        <div className="mb-6" />

        <div className="grid items-end gap-6 lg:grid-cols-[1.4fr_1fr]">
          <h1 className="text-balance font-sans text-4xl font-semibold leading-[1.05] tracking-tight text-[#ebe6dd] sm:text-5xl lg:text-6xl">
            Your Neighborhood’s Web of Help.
          </h1>
          <p className="text-pretty text-base leading-relaxed text-muted-foreground lg:pb-2">
            ResQ Command ingests fragmented reports from citizens, field
            officers and sensors, then classifies, de-duplicates and triages
            them in seconds, so responders reach the right place first.
          </p>
        </div>

        {/* map centerpiece */}
        <div className="mt-8 grid gap-4 lg:grid-cols-[1fr_360px]">
          <div className="relative h-[52vh] min-h-96 lg:h-[62vh]">
            <TacticalMap incidents={incidents} showSweep />
            <div className="pointer-events-none absolute left-4 top-4 flex items-center gap-2 rounded-md border border-border bg-background/80 px-3 py-1.5 font-mono text-[11px] tracking-wider text-muted-foreground backdrop-blur">
              <span className="size-2 animate-live-blink rounded-full bg-critical" />
              TACTICAL MAP · {incidents.filter((i) => i.status !== 'resolved').length}{' '}
              ACTIVE
            </div>
            <div className="pointer-events-none absolute bottom-4 left-4 flex flex-wrap gap-3 rounded-md border border-border bg-background/80 px-3 py-2 font-mono text-[10px] tracking-wider text-muted-foreground backdrop-blur">
              <LegendDot color="var(--critical)" label="CRITICAL" />
              <LegendDot color="var(--warning)" label="HIGH" />
              <LegendDot color="var(--info)" label="MODERATE" />
              <LegendDot color="var(--success)" label="RESOLVED" />
            </div>
          </div>
          <LiveFeedPanel className="h-[52vh] min-h-96 lg:h-[62vh]" />
        </div>

        <div className="mt-6 flex flex-wrap items-center gap-3">
          <Link
            href="/command-room"
            className={cn(
              buttonVariants(),
              'h-10 gap-2 px-5 text-sm font-semibold',
            )}
          >
            Open Command Room
            <ArrowRight className="size-4" />
          </Link>
          <Link
            href="/dashboard"
            className={cn(
              buttonVariants({ variant: 'outline' }),
              'h-10 bg-[rgba(172,150,110,0.49)] px-5 text-sm font-medium',
            )}
          >
            View Dashboard
          </Link>
          <Link
            href="/report"
            className={cn(
              buttonVariants({ variant: 'ghost' }),
              'h-10 bg-[rgba(172,150,110,0.49)] px-4 text-sm font-medium',
            )}
          >
            Report an incident
          </Link>
        </div>

        {/* stats */}
        <dl className="mt-10 grid grid-cols-2 gap-px overflow-hidden rounded-lg border border-border bg-border sm:grid-cols-4">
          {heroStats.map((stat) => (
            <div key={stat.label} className="bg-card px-5 py-5">
              <dd className="font-mono text-2xl font-semibold tracking-tight text-foreground sm:text-3xl">
                <CountUp
                  value={stat.value}
                  suffix={stat.suffix}
                  decimals={stat.value % 1 !== 0 ? 1 : 0}
                />
              </dd>
              <dt className="mt-1 text-xs text-muted-foreground">
                {stat.label}
              </dt>
            </div>
          ))}
        </dl>
      </div>
    </section>
  )
}

function LegendDot({ color, label }: { color: string; label: string }) {
  return (
    <span className="flex items-center gap-1.5">
      <span
        className="size-2 rounded-full"
        style={{ backgroundColor: color, boxShadow: `0 0 8px ${color}` }}
      />
      {label}
    </span>
  )
}

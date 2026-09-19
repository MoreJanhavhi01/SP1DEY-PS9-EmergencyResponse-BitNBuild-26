'use client'

import Link from 'next/link'
import {
  Layers,
  Gauge,
  GitMerge,
  MapPinned,
  Radio,
  Brain,
  ShieldAlert,
  ArrowRight,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { buttonVariants } from '@/components/ui/button'
import { IncidentLogFeed } from '@/components/incident-log-feed'
import { AiAssistant } from '@/components/ai-assistant'
import { MiniSeverityGauge, MiniMapThumb, MiniMergeAnim } from '@/components/home/mini-viz'

export function SectionHeading({
  kicker,
  title,
  description,
  className,
}: {
  kicker: string
  title: React.ReactNode
  description?: string
  className?: string
}) {
  return (
    <div className={cn('max-w-2xl', className)}>
      <span className="font-mono text-[11px] uppercase tracking-widest text-primary">
        {kicker}
      </span>
      <h2 className="mt-3 text-balance text-3xl font-semibold tracking-tight sm:text-4xl">
        {title}
      </h2>
      {description && (
        <p className="mt-3 text-pretty text-muted-foreground">{description}</p>
      )}
    </div>
  )
}

export function ChallengeSection() {
  return (
    <section className="border-b border-border">
      <div className="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:py-20">
        <SectionHeading
          kicker="The challenge"
          title="Fragmented reports, one chaotic picture."
          description="During a disaster, information floods in from everywhere at once — and no two channels agree. Coordinators lose critical minutes reconciling noise instead of directing help."
        />
        <div className="mt-10 grid gap-4 lg:grid-cols-[1fr_auto_1fr] lg:items-stretch">
          <div className="rounded-lg border border-critical/25 bg-critical/[0.04] p-6">
            <span className="font-mono text-[11px] uppercase tracking-widest text-critical">
              Before · fragmented
            </span>
            <ul className="mt-4 space-y-3 text-sm text-muted-foreground">
              {[
                '112 calls, SMS, social posts and field radio — all in separate silos',
                'The same fire reported 7 times as 7 different incidents',
                'No shared severity ranking; the loudest caller wins, not the most critical',
                'Resources double-dispatched to one site while another waits',
              ].map((t) => (
                <li key={t} className="flex gap-2.5">
                  <span className="mt-1.5 size-1.5 shrink-0 rounded-full bg-critical" />
                  {t}
                </li>
              ))}
            </ul>
          </div>

          <div className="flex items-center justify-center lg:px-2">
            <div className="flex items-center gap-2 rounded-full border border-primary/30 bg-primary/10 px-3 py-2 font-mono text-[11px] tracking-widest text-primary">
              ResQ
              <ArrowRight className="size-4" />
            </div>
          </div>

          <div className="rounded-lg border border-success/25 bg-success/[0.04] p-6">
            <span className="font-mono text-[11px] uppercase tracking-widest text-success">
              After · unified
            </span>
            <ul className="mt-4 space-y-3 text-sm text-muted-foreground">
              {[
                'Every channel normalised into one live incident stream',
                'Duplicate signals auto-merged with full audit trail',
                'AI severity score triages the queue objectively, 0–100',
                'Resource map shows exactly what is free, deployed or en route',
              ].map((t) => (
                <li key={t} className="flex gap-2.5">
                  <span className="mt-1.5 size-1.5 shrink-0 rounded-full bg-success" />
                  {t}
                </li>
              ))}
            </ul>
          </div>
        </div>
      </div>
    </section>
  )
}

interface Feature {
  icon: React.ComponentType<{ className?: string }>
  title: string
  body: string
  span: string
  viz?: 'gauge' | 'map' | 'merge'
}

const features: Feature[] = [
  {
    icon: Gauge,
    title: 'AI severity scoring',
    body: 'Every report is scored 0–100 from text, location and reporter type — so triage is objective, not first-come-first-served.',
    span: 'lg:col-span-2',
    viz: 'gauge',
  },
  {
    icon: Radio,
    title: 'Omni-channel ingest',
    body: 'Citizens (SMS/app), 112, field radio and IoT sensors feed one normalised stream.',
    span: '',
  },
  {
    icon: GitMerge,
    title: 'Duplicate merge',
    body: 'Reports about the same event collapse into a single incident with a merge history you can audit.',
    span: 'lg:col-span-2',
    viz: 'merge',
  },
  {
    icon: MapPinned,
    title: 'Live tactical map',
    body: 'Severity-colored, pulsing markers across every district in real time.',
    span: '',
    viz: 'map',
  },
  {
    icon: Brain,
    title: 'Response copilot',
    body: 'Plain-language summaries and next-best-action recommendations grounded in the live resource map.',
    span: '',
  },
  {
    icon: ShieldAlert,
    title: 'Resource coordination',
    body: 'Assign tenders, ambulances and NDRF teams with conflict checks across districts.',
    span: '',
  },
  {
    icon: Layers,
    title: 'Command Room mode',
    body: 'A projector-ready wall view for the situation room during an active event.',
    span: '',
  },
]

export function FeatureShowcase() {
  return (
    <section className="border-b border-border bg-surface/30">
      <div className="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:py-20">
        <SectionHeading
          kicker="Capabilities"
          title="Built for the situation room, not a slide deck."
        />
        <div className="mt-10 grid auto-rows-[minmax(0,1fr)] grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {features.map((f) => (
            <article
              key={f.title}
              className={cn(
                'group flex flex-col rounded-lg border border-border bg-card p-5 transition-colors hover:border-primary/40',
                f.span,
              )}
            >
              <div className="mb-4 flex items-center justify-between">
                <span className="flex size-9 items-center justify-center rounded-md border border-border bg-surface text-primary">
                  <f.icon className="size-4.5" />
                </span>
                {f.viz === 'gauge' && <MiniSeverityGauge />}
              </div>
              {f.viz === 'map' && (
                <div className="mb-4">
                  <MiniMapThumb />
                </div>
              )}
              {f.viz === 'merge' && (
                <div className="mb-4">
                  <MiniMergeAnim />
                </div>
              )}
              <h3 className="text-base font-semibold">{f.title}</h3>
              <p className="mt-1.5 text-sm leading-relaxed text-muted-foreground">
                {f.body}
              </p>
            </article>
          ))}
        </div>
      </div>
    </section>
  )
}

export function HowItWorks() {
  return (
    <section className="border-b border-border">
      <div className="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:py-20">
        <div className="grid gap-10 lg:grid-cols-[1fr_1.2fr] lg:items-center">
          <div>
            <SectionHeading
              kicker="How it works"
              title="From raw signal to dispatch in seconds."
              description="No numbered diagrams — this is what the pipeline actually does, line by line, the moment a report lands."
            />
            <dl className="mt-8 space-y-5">
              {[
                ['Ingest', 'Normalise the report from any channel and geo-tag it.'],
                ['Classify', 'Score type and severity with an AI model.'],
                ['De-duplicate', 'Merge matching signals into one incident.'],
                ['Dispatch', 'Recommend and assign the nearest free resources.'],
              ].map(([term, desc]) => (
                <div key={term} className="flex gap-4">
                  <dt className="w-24 shrink-0 font-mono text-xs uppercase tracking-widest text-primary">
                    {term}
                  </dt>
                  <dd className="text-sm text-muted-foreground">{desc}</dd>
                </div>
              ))}
            </dl>
          </div>
          <IncidentLogFeed />
        </div>
      </div>
    </section>
  )
}

export function AssistantPreview() {
  return (
    <section className="border-b border-border bg-surface/30">
      <div className="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:py-20">
        <div className="grid gap-10 lg:grid-cols-[1fr_1fr] lg:items-center">
          <SectionHeading
            kicker="Response copilot"
            title="Ask the incident. Get the plan."
            description="The copilot reads the live picture and answers in plain language — summaries, recommended actions and cross-incident resource checks — so a coordinator can decide in seconds."
          />
          <AiAssistant className="h-[30rem]" />
        </div>
      </div>
    </section>
  )
}

export function CtaSection() {
  return (
    <section className="relative overflow-hidden">
      <div className="pointer-events-none absolute inset-0 bg-radar-grid opacity-40" />
      <div className="pointer-events-none absolute left-1/2 top-1/2 h-64 w-[70%] -translate-x-1/2 -translate-y-1/2 rounded-full bg-primary/10 blur-3xl" />
      <div className="relative mx-auto max-w-4xl px-4 py-20 text-center sm:px-6">
        <h2 className="text-balance text-3xl font-semibold tracking-tight sm:text-4xl">
          When minutes decide outcomes, coordination can&apos;t wait.
        </h2>
        <p className="mx-auto mt-4 max-w-xl text-pretty text-muted-foreground">
          Step into the command view and see how a unified picture changes
          disaster response across Gujarat.
        </p>
        <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
          <Link
            href="/command-room"
            className={cn(buttonVariants(), 'h-11 gap-2 px-6 text-sm font-semibold')}
          >
            Enter Command Room
            <ArrowRight className="size-4" />
          </Link>
          <Link
            href="/dashboard"
            className={cn(
              buttonVariants({ variant: 'outline' }),
              'h-11 px-6 text-sm font-medium',
            )}
          >
            Explore the Dashboard
          </Link>
        </div>
      </div>
    </section>
  )
}

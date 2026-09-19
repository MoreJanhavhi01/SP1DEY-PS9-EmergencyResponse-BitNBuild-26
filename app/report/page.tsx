import type { Metadata } from 'next'
import { SiteNav, SiteFooter } from '@/components/site-nav'
import { ReportForm } from '@/components/report/report-form'

export const metadata: Metadata = {
  title: 'Report an Emergency · ResQ Command',
  description:
    'Submit an emergency report. AI classifies and prioritises it in real time.',
}

export default function ReportPage() {
  return (
    <div className="flex min-h-dvh flex-col">
      <SiteNav />
      <main className="flex-1">
        <div className="mx-auto max-w-5xl px-4 py-8 sm:px-6">
          <div className="border-b border-border pb-6">
            <h1 className="text-2xl font-semibold tracking-tight">
              Report an Emergency
            </h1>
            <p className="mt-1 text-sm text-muted-foreground">
              Every report is normalised, geo-tagged and scored the moment you
              submit — then merged with related signals and routed to the right
              district.
            </p>
          </div>
          <div className="mt-6">
            <ReportForm />
          </div>
        </div>
      </main>
      <SiteFooter />
    </div>
  )
}

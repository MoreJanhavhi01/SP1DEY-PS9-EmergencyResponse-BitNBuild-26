import type { Metadata } from 'next'
import { SiteNav, SiteFooter } from '@/components/site-nav'
import { AnalyticsView } from '@/components/analytics/analytics-view'

export const metadata: Metadata = {
  title: 'Analytics · ResQ Command',
  description:
    'Trends across incidents, response performance and resource utilisation.',
}

export default function AnalyticsPage() {
  return (
    <div className="flex min-h-dvh flex-col">
      <SiteNav />
      <main className="flex-1">
        <AnalyticsView />
      </main>
      <SiteFooter />
    </div>
  )
}

import type { Metadata } from 'next'
import { SiteNav, SiteFooter } from '@/components/site-nav'
import { DashboardView } from '@/components/dashboard/dashboard-view'

export const metadata: Metadata = {
  title: 'Operations Dashboard · ResQ Command',
  description:
    'Live operational view of every incident, resource and dispatch across Gujarat.',
}

export default function DashboardPage() {
  return (
    <div className="flex min-h-dvh flex-col">
      <SiteNav />
      <main className="flex-1">
        <DashboardView />
      </main>
      <SiteFooter />
    </div>
  )
}

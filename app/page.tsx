import { SiteNav, SiteFooter } from '@/components/site-nav'
import { Hero } from '@/components/home/hero'
import {
  ChallengeSection,
  FeatureShowcase,
  HowItWorks,
  AssistantPreview,
  CtaSection,
} from '@/components/home/sections'

export default function HomePage() {
  return (
    <div className="flex min-h-dvh flex-col">
      <SiteNav />
      <main className="flex-1">
        <Hero />
        <ChallengeSection />
        <FeatureShowcase />
        <HowItWorks />
        <AssistantPreview />
        <CtaSection />
      </main>
      <SiteFooter />
    </div>
  )
}

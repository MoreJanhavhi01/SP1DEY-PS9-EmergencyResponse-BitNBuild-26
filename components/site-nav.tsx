'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useState } from 'react'
import { Menu, X } from 'lucide-react'
import { cn } from '@/lib/utils'
import { Logo, LiveBadge } from '@/components/brand'
import { buttonVariants } from '@/components/ui/button'

const links = [
  { href: '/dashboard', label: 'Dashboard' },
  { href: '/command-room', label: 'Command Room' },
  { href: '/analytics', label: 'Analytics' },
  { href: '/report', label: 'Report' },
]

export function SiteNav() {
  return <header className="sticky top-0 z-50 border-b border-border bg-background/80 backdrop-blur-md" />
}

export function SiteNavContent() {
  const pathname = usePathname()
  const [open, setOpen] = useState(false)

  return (
    <>
      <div className="mx-auto flex h-[70px] max-w-7xl items-center justify-between gap-4 px-4 sm:px-6">
        <div className="flex items-center gap-4">
          <Logo />
          <span className="hidden h-6 w-px bg-border sm:block" />
          <LiveBadge className="hidden sm:inline-flex" label="ALL SYSTEMS LIVE" />
        </div>

        <nav className="hidden items-center gap-1 md:flex">
          {links.map((link) => {
            const active = pathname === link.href
            return (
              <Link
                key={link.href}
                href={link.href}
                className={cn(
                  'rounded-md px-3 py-2 text-sm font-medium transition-colors',
                  active
                    ? 'bg-accent text-foreground'
                    : 'text-muted-foreground hover:text-foreground',
                )}
              >
                {link.label}
              </Link>
            )
          })}
          <Link
            href="/report"
            className={cn(buttonVariants({ size: 'sm' }), 'ml-2 font-medium')}
          >
            Report Incident
          </Link>
        </nav>

        <button
          type="button"
          className="inline-flex size-9 items-center justify-center rounded-md border border-border text-foreground md:hidden"
          onClick={() => setOpen((v) => !v)}
          aria-label="Toggle menu"
        >
          {open ? <X className="size-4" /> : <Menu className="size-4" />}
        </button>
      </div>

      {open && (
        <div className="border-t border-border bg-background md:hidden">
          <nav className="mx-auto flex max-w-7xl flex-col gap-1 px-4 py-3">
            {links.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                onClick={() => setOpen(false)}
                className={cn(
                  'rounded-md px-3 py-2.5 text-sm font-medium',
                  pathname === link.href
                    ? 'bg-accent text-foreground'
                    : 'text-muted-foreground',
                )}
              >
                {link.label}
              </Link>
            ))}
          </nav>
        </div>
      )}
    </>
  )
}

export function SiteFooter() {
  return (
    <footer className="border-t border-border bg-background">
      <div className="mx-auto max-w-7xl px-4 py-10 sm:px-6">
        <div className="flex flex-col gap-8 md:flex-row md:items-start md:justify-between">
          <div className="max-w-xs">
            <Logo />
            <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
              AI-powered emergency response &amp; resource coordination for
              Gujarat disaster management authorities.
            </p>
          </div>
          <div className="grid grid-cols-2 gap-8 sm:grid-cols-3">
            <FooterCol
              title="Platform"
              items={[
                { label: 'Dashboard', href: '/dashboard' },
                { label: 'Command Room', href: '/command-room' },
                { label: 'Analytics', href: '/analytics' },
              ]}
            />
            <FooterCol
              title="Public"
              items={[
                { label: 'Report Incident', href: '/report' },
                { label: 'Home', href: '/' },
              ]}
            />
            <FooterCol
              title="Project"
              items={[
                { label: 'Bit N Build 26', href: '/' },
                { label: 'PS-9', href: '/' },
              ]}
            />
          </div>
        </div>
        <div className="mt-10 flex flex-col gap-2 border-t border-border pt-6 font-mono text-[11px] tracking-wide text-muted-foreground sm:flex-row sm:items-center sm:justify-between">
          <span>RESQ COMMAND · GUJARAT SDMA · DEMO BUILD</span>
          <span>© 2026 · Hackathon prototype · Mock data</span>
        </div>
      </div>
    </footer>
  )
}

function FooterCol({
  title,
  items,
}: {
  title: string
  items: { label: string; href: string }[]
}) {
  return (
    <div>
      <h3 className="font-mono text-[11px] uppercase tracking-widest text-foreground/60">
        {title}
      </h3>
      <ul className="mt-3 space-y-2">
        {items.map((item) => (
          <li key={item.label}>
            <Link
              href={item.href}
              className="text-sm text-muted-foreground transition-colors hover:text-foreground"
            >
              {item.label}
            </Link>
          </li>
        ))}
      </ul>
    </div>
  )
}

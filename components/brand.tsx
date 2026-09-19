import Link from 'next/link'
import { cn } from '@/lib/utils'

export function Logo({
  className,
  href = '/',
}: {
  className?: string
  href?: string
}) {
  return (
    <Link
      href={href}
      className={cn('group flex items-center gap-2.5', className)}
      aria-label="ResQ Command home"
    >
      <span className="relative flex size-8 items-center justify-center rounded-md border border-primary/40 bg-primary/10">
        <span className="absolute inset-0 rounded-md ring-1 ring-inset ring-primary/20" />
        <svg
          viewBox="0 0 24 24"
          className="size-5 text-primary"
          fill="none"
          aria-hidden="true"
        >
          <path
            d="M12 2.5 3.5 6v6c0 5.2 3.6 8.4 8.5 9.5 4.9-1.1 8.5-4.3 8.5-9.5V6L12 2.5Z"
            stroke="currentColor"
            strokeWidth="1.4"
          />
          <path
            d="M12 8.5v7M8.5 12h7"
            stroke="currentColor"
            strokeWidth="1.6"
            strokeLinecap="round"
          />
        </svg>
      </span>
      <span className="flex flex-col leading-none">
        <span className="font-mono text-sm font-semibold tracking-widest text-foreground">
          RESQ
        </span>
        <span className="font-mono text-[10px] tracking-[0.32em] text-muted-foreground">
          COMMAND
        </span>
      </span>
    </Link>
  )
}

export function LiveBadge({
  className,
  label = 'LIVE',
}: {
  className?: string
  label?: string
}) {
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1.5 rounded-sm border border-critical/40 bg-critical/10 px-2 py-0.5 font-mono text-[10px] font-medium tracking-widest text-critical',
        className,
      )}
    >
      <span className="relative flex size-1.5">
        <span className="absolute inline-flex size-full animate-ping rounded-full bg-critical opacity-75" />
        <span className="relative inline-flex size-1.5 rounded-full bg-critical" />
      </span>
      {label}
    </span>
  )
}

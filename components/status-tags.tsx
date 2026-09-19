import { cn } from '@/lib/utils'
import {
  type Severity,
  type IncidentStatus,
  severityLabel,
  statusLabel,
} from '@/lib/mock-data'

const severityClasses: Record<Severity, string> = {
  critical: 'border-critical/40 bg-critical/12 text-critical',
  high: 'border-warning/40 bg-warning/12 text-warning',
  moderate: 'border-info/40 bg-info/12 text-info',
  low: 'border-success/40 bg-success/12 text-success',
}

export function SeverityTag({
  severity,
  score,
  className,
}: {
  severity: Severity
  score?: number
  className?: string
}) {
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1.5 rounded-sm border px-1.5 py-0.5 font-mono text-[10px] font-medium tracking-wider',
        severityClasses[severity],
        className,
      )}
    >
      <span className="size-1.5 rounded-full bg-current" />
      {severityLabel[severity]}
      {score !== undefined && <span className="opacity-70">· {score}</span>}
    </span>
  )
}

const statusClasses: Record<IncidentStatus, string> = {
  new: 'border-critical/40 text-critical',
  dispatched: 'border-warning/40 text-warning',
  'in-progress': 'border-info/40 text-info',
  resolved: 'border-success/40 text-success',
}

export function StatusTag({
  status,
  className,
}: {
  status: IncidentStatus
  className?: string
}) {
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1.5 rounded-sm border bg-background/40 px-1.5 py-0.5 font-mono text-[10px] font-medium tracking-wider',
        statusClasses[status],
        className,
      )}
    >
      {statusLabel[status]}
    </span>
  )
}

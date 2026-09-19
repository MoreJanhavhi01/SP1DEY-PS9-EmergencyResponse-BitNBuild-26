'use client'

import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import {
  incidentsByType,
  incidentsByDistrict,
  incidentsByHour,
  responseTimeTrend,
  resourceUtilization,
} from '@/lib/mock-data'
import { CountUp } from '@/components/count-up'

const AMBER = 'oklch(0.78 0.15 66)'
const RED = 'oklch(0.62 0.21 25)'
const INFO = 'oklch(0.7 0.12 230)'
const GREEN = 'oklch(0.68 0.15 155)'
const MUTED = 'oklch(0.55 0.01 60)'
const GRID = 'oklch(0.3 0.008 60)'

const axisProps = {
  stroke: MUTED,
  tick: { fill: MUTED, fontSize: 11, fontFamily: 'var(--font-mono)' },
  tickLine: false,
}

function ChartTooltip({ active, payload, label }: any) {
  if (!active || !payload?.length) return null
  return (
    <div className="rounded-md border border-border bg-popover px-3 py-2 font-mono text-[11px] shadow-lg">
      {label !== undefined && (
        <div className="mb-1 uppercase tracking-wider text-muted-foreground">
          {label}
        </div>
      )}
      {payload.map((p: any) => (
        <div key={p.name} className="flex items-center gap-2">
          <span
            className="size-2 rounded-full"
            style={{ backgroundColor: p.color || p.fill }}
          />
          <span className="text-foreground">
            {p.name}: {p.value}
          </span>
        </div>
      ))}
    </div>
  )
}

export function AnalyticsView() {
  const utilColors = [RED, GREEN, INFO, MUTED]
  const typeColors = [RED, INFO, GREEN, AMBER, RED, MUTED]

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
      <div className="flex flex-col gap-1 border-b border-border pb-6">
        <h1 className="text-2xl font-semibold tracking-tight">
          Analytics &amp; Insights
        </h1>
        <p className="text-sm text-muted-foreground">
          Trends across incidents, response performance and resource use — last
          7 days.
        </p>
      </div>

      {/* kpi row */}
      <div className="mt-6 grid grid-cols-2 gap-3 lg:grid-cols-4">
        <Kpi label="Total incidents" value={201} accent={AMBER} />
        <Kpi label="Avg response" value={9.7} suffix=" min" decimals={1} accent={GREEN} delta="-31%" />
        <Kpi label="Reports merged" value={38} suffix="%" accent={INFO} />
        <Kpi label="Resolution rate" value={94} suffix="%" accent={GREEN} delta="+6%" />
      </div>

      <div className="mt-6 grid gap-4 lg:grid-cols-2">
        {/* response time trend */}
        <ChartCard
          title="Response time trend"
          subtitle="Average minutes to first dispatch"
        >
          <ResponsiveContainer width="100%" height={260}>
            <AreaChart data={responseTimeTrend} margin={{ left: -18, right: 8, top: 8 }}>
              <defs>
                <linearGradient id="respFill" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor={AMBER} stopOpacity={0.5} />
                  <stop offset="100%" stopColor={AMBER} stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid stroke={GRID} vertical={false} />
              <XAxis dataKey="day" {...axisProps} />
              <YAxis {...axisProps} />
              <Tooltip content={<ChartTooltip />} cursor={{ stroke: GRID }} />
              <Area
                type="monotone"
                dataKey="minutes"
                name="Minutes"
                stroke={AMBER}
                strokeWidth={2}
                fill="url(#respFill)"
                dot={{ r: 3, fill: AMBER, strokeWidth: 0 }}
                activeDot={{ r: 5 }}
              />
            </AreaChart>
          </ResponsiveContainer>
        </ChartCard>

        {/* incidents by hour */}
        <ChartCard title="Incidents by hour" subtitle="Reports ingested per 3-hour block">
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={incidentsByHour} margin={{ left: -18, right: 8, top: 8 }}>
              <CartesianGrid stroke={GRID} vertical={false} />
              <XAxis dataKey="hour" {...axisProps} />
              <YAxis {...axisProps} />
              <Tooltip content={<ChartTooltip />} cursor={{ fill: 'oklch(0.3 0.008 60 / 0.3)' }} />
              <Bar dataKey="count" name="Incidents" radius={[3, 3, 0, 0]}>
                {incidentsByHour.map((entry, i) => (
                  <Cell
                    key={i}
                    fill={entry.count >= 28 ? RED : entry.count >= 18 ? AMBER : INFO}
                  />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </ChartCard>

        {/* by district stacked */}
        <ChartCard title="Severity by district" subtitle="Incident counts split by severity">
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={incidentsByDistrict} margin={{ left: -18, right: 8, top: 8 }}>
              <CartesianGrid stroke={GRID} vertical={false} />
              <XAxis dataKey="district" {...axisProps} />
              <YAxis {...axisProps} />
              <Tooltip content={<ChartTooltip />} cursor={{ fill: 'oklch(0.3 0.008 60 / 0.3)' }} />
              <Bar dataKey="critical" name="Critical" stackId="a" fill={RED} radius={[0, 0, 0, 0]} />
              <Bar dataKey="high" name="High" stackId="a" fill={AMBER} />
              <Bar dataKey="moderate" name="Moderate" stackId="a" fill={INFO} radius={[3, 3, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </ChartCard>

        {/* two donuts side by side inside one card row */}
        <ChartCard title="Distribution" subtitle="Incident type & resource utilisation">
          <div className="grid grid-cols-2 gap-2">
            <DonutBlock
              data={incidentsByType}
              colors={typeColors}
              label="By type"
            />
            <DonutBlock
              data={resourceUtilization}
              colors={utilColors}
              label="Resources"
            />
          </div>
        </ChartCard>
      </div>
    </div>
  )
}

function DonutBlock({
  data,
  colors,
  label,
}: {
  data: { name: string; value: number }[]
  colors: string[]
  label: string
}) {
  return (
    <div className="flex flex-col items-center">
      <ResponsiveContainer width="100%" height={170}>
        <PieChart>
          <Pie
            data={data}
            dataKey="value"
            nameKey="name"
            innerRadius={38}
            outerRadius={62}
            paddingAngle={2}
            stroke="none"
          >
            {data.map((_, i) => (
              <Cell key={i} fill={colors[i % colors.length]} />
            ))}
          </Pie>
          <Tooltip content={<ChartTooltip />} />
        </PieChart>
      </ResponsiveContainer>
      <span className="font-mono text-[10px] uppercase tracking-widest text-muted-foreground">
        {label}
      </span>
      <div className="mt-2 flex flex-wrap justify-center gap-x-3 gap-y-1">
        {data.map((d, i) => (
          <span key={d.name} className="flex items-center gap-1 text-[10px] text-muted-foreground">
            <span className="size-2 rounded-full" style={{ backgroundColor: colors[i % colors.length] }} />
            {d.name}
          </span>
        ))}
      </div>
    </div>
  )
}

function ChartCard({
  title,
  subtitle,
  children,
}: {
  title: string
  subtitle?: string
  children: React.ReactNode
}) {
  return (
    <div className="rounded-lg border border-border bg-card p-5">
      <div className="mb-4">
        <h2 className="text-sm font-semibold">{title}</h2>
        {subtitle && <p className="text-xs text-muted-foreground">{subtitle}</p>}
      </div>
      {children}
    </div>
  )
}

function Kpi({
  label,
  value,
  suffix = '',
  decimals = 0,
  accent,
  delta,
}: {
  label: string
  value: number
  suffix?: string
  decimals?: number
  accent: string
  delta?: string
}) {
  return (
    <div className="rounded-lg border border-border bg-card px-4 py-4">
      <div className="flex items-center justify-between">
        <span className="text-xs text-muted-foreground">{label}</span>
        {delta && (
          <span className="font-mono text-[10px] text-success">{delta}</span>
        )}
      </div>
      <div className="mt-1 font-mono text-3xl font-semibold" style={{ color: accent }}>
        <CountUp value={value} suffix={suffix} decimals={decimals} />
      </div>
    </div>
  )
}

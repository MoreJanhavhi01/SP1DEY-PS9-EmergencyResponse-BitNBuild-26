'use client'

import { useEffect, useState } from 'react'

export function MiniSeverityGauge() {
  const [score, setScore] = useState(0)
  useEffect(() => {
    const values = [89, 76, 64, 82, 58]
    let i = 0
    const t = setInterval(() => {
      i = (i + 1) % values.length
      setScore(values[i])
    }, 2200)
    setScore(89)
    return () => clearInterval(t)
  }, [])

  const radius = 34
  const circ = Math.PI * radius // half circle
  const pct = score / 100
  const color =
    score >= 80 ? 'var(--critical)' : score >= 60 ? 'var(--warning)' : 'var(--info)'

  return (
    <div className="flex items-center gap-4">
      <svg viewBox="0 0 80 48" className="h-14 w-24">
        <path
          d="M6 44 A34 34 0 0 1 74 44"
          fill="none"
          stroke="var(--border)"
          strokeWidth="6"
          strokeLinecap="round"
        />
        <path
          d="M6 44 A34 34 0 0 1 74 44"
          fill="none"
          stroke={color}
          strokeWidth="6"
          strokeLinecap="round"
          strokeDasharray={circ}
          strokeDashoffset={circ * (1 - pct)}
          style={{ transition: 'stroke-dashoffset 1s ease, stroke 0.6s ease' }}
        />
      </svg>
      <div className="flex flex-col">
        <span
          className="font-mono text-2xl font-semibold leading-none"
          style={{ color }}
        >
          {score}
        </span>
        <span className="font-mono text-[10px] tracking-wider text-muted-foreground">
          / 100 SEVERITY
        </span>
      </div>
    </div>
  )
}

export function MiniMapThumb() {
  const dots = [
    { x: 30, y: 38, c: 'var(--critical)' },
    { x: 58, y: 30, c: 'var(--warning)' },
    { x: 46, y: 62, c: 'var(--info)' },
    { x: 70, y: 58, c: 'var(--success)' },
  ]
  return (
    <div className="relative h-20 w-full overflow-hidden rounded-md border border-border bg-radar-grid-fine bg-surface">
      <svg
        viewBox="0 0 100 80"
        preserveAspectRatio="none"
        className="absolute inset-0 size-full opacity-60"
      >
        <path
          d="M18 24 L40 16 L58 22 L70 34 L64 52 L46 64 L28 58 L20 42 Z"
          fill="oklch(0.24 0.01 66 / 0.6)"
          stroke="oklch(0.78 0.15 66 / 0.4)"
          strokeWidth="0.6"
        />
      </svg>
      {dots.map((d, i) => (
        <span
          key={i}
          className="absolute -translate-x-1/2 -translate-y-1/2"
          style={{ left: `${d.x}%`, top: `${d.y}%` }}
        >
          <span
            className="animate-marker-pulse absolute left-1/2 top-1/2 size-2 -translate-x-1/2 -translate-y-1/2 rounded-full"
            style={{ backgroundColor: d.c, animationDelay: `${i * 0.4}s` }}
          />
          <span
            className="relative block size-2 rounded-full"
            style={{ backgroundColor: d.c, boxShadow: `0 0 8px ${d.c}` }}
          />
        </span>
      ))}
    </div>
  )
}

export function MiniMergeAnim() {
  const [merged, setMerged] = useState(false)
  useEffect(() => {
    const t = setInterval(() => setMerged((m) => !m), 2000)
    return () => clearInterval(t)
  }, [])

  const sources = ['SMS', 'CALL', 'APP', '112', 'FIELD']
  return (
    <div className="relative flex h-20 items-center justify-between font-mono text-[10px]">
      <div className="flex flex-col gap-1">
        {sources.map((s, i) => (
          <span
            key={s}
            className="rounded-sm border border-border bg-surface px-1.5 py-0.5 tracking-wider text-muted-foreground transition-all duration-500"
            style={{
              opacity: merged ? 0.4 : 1,
              transform: merged ? 'translateX(6px)' : 'translateX(0)',
              transitionDelay: `${i * 60}ms`,
            }}
          >
            {s}
          </span>
        ))}
      </div>
      <svg className="h-16 flex-1" viewBox="0 0 80 60" preserveAspectRatio="none">
        {[10, 22, 30, 38, 50].map((y, i) => (
          <path
            key={i}
            d={`M4 ${y} C40 ${y}, 40 30, 76 30`}
            fill="none"
            stroke={merged ? 'var(--primary)' : 'var(--border)'}
            strokeWidth="1"
            style={{ transition: 'stroke 0.5s ease' }}
          />
        ))}
      </svg>
      <div
        className="flex items-center gap-1.5 rounded-sm border px-2 py-1 tracking-wider transition-all duration-500"
        style={{
          borderColor: merged ? 'var(--primary)' : 'var(--border)',
          color: merged ? 'var(--primary)' : 'var(--muted-foreground)',
          boxShadow: merged ? '0 0 14px oklch(0.78 0.15 66 / 0.3)' : 'none',
        }}
      >
        <span className="size-1.5 rounded-full bg-current" />
        1 INCIDENT
      </div>
    </div>
  )
}

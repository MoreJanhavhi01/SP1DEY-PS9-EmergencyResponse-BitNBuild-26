'use client'

import { useInView, useCountUp } from '@/lib/hooks'

export function CountUp({
  value,
  suffix = '',
  decimals = 0,
  className,
}: {
  value: number
  suffix?: string
  decimals?: number
  className?: string
}) {
  const { ref, inView } = useInView<HTMLSpanElement>(0.5)
  const current = useCountUp(value, inView)
  const formatted =
    decimals > 0
      ? current.toFixed(decimals)
      : Math.round(current).toLocaleString('en-IN')

  return (
    <span ref={ref} className={className}>
      {formatted}
      {suffix}
    </span>
  )
}

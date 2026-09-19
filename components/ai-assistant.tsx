'use client'

import { useEffect, useRef, useState } from 'react'
import { Sparkles } from 'lucide-react'
import { cn } from '@/lib/utils'
import { assistantConversation, type ChatMessage } from '@/lib/mock-data'

export function AiAssistant({
  className,
  autoPlay = true,
}: {
  className?: string
  autoPlay?: boolean
}) {
  const [visibleCount, setVisibleCount] = useState(autoPlay ? 0 : assistantConversation.length)
  const [typing, setTyping] = useState(false)
  const containerRef = useRef<HTMLDivElement>(null)
  const scrollRef = useRef<HTMLDivElement>(null)
  const [started, setStarted] = useState(!autoPlay)

  useEffect(() => {
    if (!autoPlay) return
    const el = containerRef.current
    if (!el) return
    const obs = new IntersectionObserver(
      ([e]) => {
        if (e.isIntersecting) setStarted(true)
      },
      { threshold: 0.3 },
    )
    obs.observe(el)
    return () => obs.disconnect()
  }, [autoPlay])

  useEffect(() => {
    if (!started || !autoPlay) return
    if (visibleCount >= assistantConversation.length) return
    const next = assistantConversation[visibleCount]
    const delay = next.role === 'user' ? 700 : 1400
    if (next.role === 'assistant') {
      setTyping(true)
    }
    const timer = setTimeout(() => {
      setTyping(false)
      setVisibleCount((c) => c + 1)
    }, delay)
    return () => clearTimeout(timer)
  }, [started, visibleCount, autoPlay])

  useEffect(() => {
    scrollRef.current?.scrollTo({
      top: scrollRef.current.scrollHeight,
      behavior: 'smooth',
    })
  }, [visibleCount, typing])

  const messages = assistantConversation.slice(0, visibleCount)

  return (
    <div
      ref={containerRef}
      className={cn(
        'flex flex-col overflow-hidden rounded-lg border border-border bg-card',
        className,
      )}
    >
      <div className="flex items-center gap-2.5 border-b border-border bg-surface/60 px-4 py-3">
        <span className="flex size-7 items-center justify-center rounded-md bg-primary/15 text-primary">
          <Sparkles className="size-4" />
        </span>
        <div className="flex flex-col leading-tight">
          <span className="text-sm font-medium">ResQ Copilot</span>
          <span className="font-mono text-[10px] tracking-wider text-success">
            ● online · context: 4 live incidents
          </span>
        </div>
      </div>

      <div
        ref={scrollRef}
        className="flex-1 space-y-3 overflow-y-auto p-4"
        style={{ scrollbarWidth: 'thin' }}
      >
        {messages.map((msg, i) => (
          <MessageBubble key={i} message={msg} />
        ))}
        {typing && (
          <div className="flex justify-start">
            <div className="flex items-center gap-1 rounded-lg rounded-tl-sm border border-border bg-surface px-3 py-2.5">
              <Dot delay={0} />
              <Dot delay={0.15} />
              <Dot delay={0.3} />
            </div>
          </div>
        )}
      </div>

      <div className="border-t border-border p-3">
        <div className="flex items-center gap-2 rounded-md border border-input bg-background px-3 py-2 text-sm text-muted-foreground">
          <span className="flex-1 truncate">Ask about any live incident…</span>
          <span className="font-mono text-[10px] tracking-wider text-muted-foreground/60">
            ENTER
          </span>
        </div>
      </div>
    </div>
  )
}

function MessageBubble({ message }: { message: ChatMessage }) {
  const isUser = message.role === 'user'
  return (
    <div className={cn('flex', isUser ? 'justify-end' : 'justify-start')}>
      <div
        className={cn(
          'max-w-[85%] rounded-lg px-3.5 py-2.5 text-sm leading-relaxed',
          isUser
            ? 'rounded-tr-sm bg-primary/15 text-foreground'
            : 'rounded-tl-sm border border-border bg-surface text-foreground/90',
        )}
      >
        {message.meta && (
          <div className="mb-1.5 font-mono text-[10px] uppercase tracking-wider text-primary/80">
            {message.meta}
          </div>
        )}
        <p className="whitespace-pre-line">{message.content}</p>
      </div>
    </div>
  )
}

function Dot({ delay }: { delay: number }) {
  return (
    <span
      className="size-1.5 animate-bounce rounded-full bg-muted-foreground"
      style={{ animationDelay: `${delay}s`, animationDuration: '1s' }}
    />
  )
}

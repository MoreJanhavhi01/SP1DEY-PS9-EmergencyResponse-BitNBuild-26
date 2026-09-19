import { useState, useRef, useEffect } from "react";

/**
 * ResQ Copilot — functional chat panel.
 *
 * Drop this in wherever the static mockup currently lives, e.g.:
 *   <ResQCopilot />
 *
 * Wire up a real backend by replacing `getResponse()` below with a call
 * to your FastAPI endpoint (see the fetch example in the comment at the
 * bottom of this file). Until then, it runs on a rule-based fallback so
 * it's fully demoable offline.
 */

const INITIAL_MESSAGES = [
  {
    id: "seed-1",
    role: "assistant",
    kind: "recommendation",
    label: "RECOMMENDATION · BASED ON LIVE RESOURCE MAP",
    content: [
      "Recommended actions:",
      "1. Dispatch a 3rd tender — spread risk to units B-4/B-5 is rising.",
      "2. Pre-position AMB-11 (available, 6 min) for casualty overflow.",
      "3. Alert Surat Civil Hospital burns unit — expect 5-8 admissions.",
      "4. Establish 200m cordon; notify GEB to cut grid power to the block.",
    ].join("\n"),
  },
];

// Very small rule-based fallback so the panel works with zero backend.
// Swap this out for a real API call when ready (see bottom of file).
function getFallbackResponse(question) {
  const q = question.toLowerCase();

  if (q.includes("rajkot") && q.includes("conflict")) {
    return {
      label: "CROSS-INCIDENT CHECK · 2 DISTRICTS",
      content:
        "No direct conflict. HazMat HZ-01 is committed to INC-2026-0413 (Rajkot) and is 210 km away. Surat has 2 idle tenders within 8 km — reallocating them will not affect Rajkot coverage.",
    };
  }

  if (q.includes("ambulance") || q.includes("amb")) {
    return {
      label: "RESOURCE STATUS",
      content:
        "3 ambulances currently available within 10 km: AMB-11 (6 min ETA), AMB-04 (9 min ETA), AMB-07 (12 min ETA, currently refueling).",
    };
  }

  if (q.includes("hospital")) {
    return {
      label: "NEAREST FACILITIES",
      content:
        "Surat Civil Hospital (2.1 km, burns unit available) and SMIMER Hospital (4.6 km, general ICU, 3 beds free) are the closest matches for this incident type.",
    };
  }

  return {
    label: "RESPONSE",
    content:
      "I don't have live data on that yet — try asking about a specific incident ID, resource type (ambulance, tender, hazmat), or a district name.",
  };
}

export default function ResQCopilot() {
  const [messages, setMessages] = useState(INITIAL_MESSAGES);
  const [input, setInput] = useState("");
  const [isThinking, setIsThinking] = useState(false);
  const scrollRef = useRef(null);
  const inputRef = useRef(null);

  useEffect(() => {
    scrollRef.current?.scrollTo({
      top: scrollRef.current.scrollHeight,
      behavior: "smooth",
    });
  }, [messages, isThinking]);

  function handleSend() {
    const trimmed = input.trim();
    if (!trimmed || isThinking) return;

    const userMessage = {
      id: crypto.randomUUID(),
      role: "user",
      content: trimmed,
    };

    setMessages((prev) => [...prev, userMessage]);
    setInput("");
    setIsThinking(true);

    // Replace this block with a real API call — see bottom of file.
    setTimeout(() => {
      const { label, content } = getFallbackResponse(trimmed);
      setMessages((prev) => [
        ...prev,
        {
          id: crypto.randomUUID(),
          role: "assistant",
          kind: "text",
          label,
          content,
        },
      ]);
      setIsThinking(false);
    }, 700);
  }

  function handleKeyDown(e) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  }

  return (
    <div className="flex h-full flex-col rounded-xl border border-white/10 bg-[#0c0c0d]">
      {/* Header */}
      <div className="flex items-center gap-3 border-b border-white/10 px-5 py-4">
        <div className="flex h-9 w-9 items-center justify-center rounded-lg border border-amber-500/30 bg-amber-500/10">
          <SparkleIcon className="h-4 w-4 text-amber-400" />
        </div>
        <div>
          <div className="text-sm font-semibold text-white">ResQ Copilot</div>
          <div className="flex items-center gap-1.5 font-mono text-xs text-emerald-400">
            <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
            online · context: 4 live incidents
          </div>
        </div>
      </div>

      {/* Messages */}
      <div ref={scrollRef} className="flex-1 space-y-4 overflow-y-auto px-5 py-4">
        {messages.map((m) =>
          m.role === "user" ? (
            <div key={m.id} className="flex justify-end">
              <div className="max-w-[80%] rounded-lg bg-[#1a1a1c] px-4 py-3 text-sm text-white">
                {m.content}
              </div>
            </div>
          ) : (
            <div
              key={m.id}
              className="rounded-lg border border-white/10 bg-[#111112] px-4 py-3"
            >
              {m.label && (
                <div className="mb-2 font-mono text-[11px] tracking-wide text-amber-400">
                  {m.label}
                </div>
              )}
              <div className="whitespace-pre-line text-sm leading-relaxed text-neutral-200">
                {m.content}
              </div>
            </div>
          )
        )}

        {isThinking && (
          <div className="rounded-lg border border-white/10 bg-[#111112] px-4 py-3">
            <div className="flex gap-1.5">
              <Dot delay="0ms" />
              <Dot delay="150ms" />
              <Dot delay="300ms" />
            </div>
          </div>
        )}
      </div>

      {/* Input */}
      <div className="flex items-center gap-3 border-t border-white/10 px-5 py-4">
        <input
          ref={inputRef}
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="Ask about any live incident…"
          className="flex-1 bg-transparent text-sm text-white placeholder:text-neutral-500 focus:outline-none"
          autoComplete="off"
        />
        <button
          onClick={handleSend}
          disabled={!input.trim() || isThinking}
          className="font-mono text-xs tracking-wide text-neutral-500 transition-colors hover:text-amber-400 disabled:cursor-not-allowed disabled:opacity-40"
        >
          ENTER
        </button>
      </div>
    </div>
  );
}

function Dot({ delay }) {
  return (
    <span
      className="h-1.5 w-1.5 animate-bounce rounded-full bg-neutral-500"
      style={{ animationDelay: delay }}
    />
  );
}

function SparkleIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" {...props}>
      <path
        d="M12 3l1.9 5.1L19 10l-5.1 1.9L12 17l-1.9-5.1L5 10l5.1-1.9L12 3z"
        fill="currentColor"
      />
    </svg>
  );
}

/*
 * TO CONNECT TO A REAL BACKEND:
 *
 * Replace the setTimeout block inside handleSend with something like:
 *
 *   const res = await fetch("/api/copilot/ask", {
 *     method: "POST",
 *     headers: { "Content-Type": "application/json" },
 *     body: JSON.stringify({ question: trimmed }),
 *   });
 *   const data = await res.json();
 *   setMessages((prev) => [...prev, {
 *     id: crypto.randomUUID(),
 *     role: "assistant",
 *     label: data.label,
 *     content: data.content,
 *   }]);
 *   setIsThinking(false);
 *
 * On the FastAPI side, /api/copilot/ask would take the live incident
 * list + the question, and either call an LLM API or run the same
 * rule-based fallback logic server-side.
 */

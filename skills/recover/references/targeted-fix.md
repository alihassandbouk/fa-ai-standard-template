# Targeted fix (Failure Mode 1)

Redact every secret in anything you show as `<REDACTED>`.

## Phase 1 — Build a feedback loop (this is the skill)

Before any theory, get **one command** that goes red on this bug and green
when it is fixed: a failing test at the seam that reaches the bug, a curl
against the dev server, a CLI run diffed against a known-good output, a
headless-browser script, a replayed captured payload, a throwaway harness, a
fuzz loop, a bisection harness. Run it once and show the invocation and
output. It must be red-capable on the **user's exact symptom**, deterministic,
seconds not minutes, and runnable unattended. Flaky bug: raise the
reproduction rate until it is debuggable. Cannot build one: stop, list what
you tried, ask for an environment, a redacted artifact, or permission to
instrument. Phase 2 starts when the red-capable command exists and not
before: reading code to form a theory first is the failure this step prevents.

## Phase 2 — Reproduce and minimise

Run the loop, watch it go red, confirm it is the user's failure and not a
nearby one. Then cut inputs, callers, config and steps one at a time,
re-running after each cut, until every remaining element is load-bearing.

## Phase 3 — Hypothesise

Write three to five ranked hypotheses before testing any. Each must predict:
"If X is the cause, then changing Y makes the bug disappear." No prediction,
no hypothesis. Show the list to the developer; they often re-rank it
instantly.

## Phase 4 — Instrument

One variable per probe, each probe mapped to a prediction. Debugger over
logs; targeted logs over "log everything". Tag every debug log
`[DEBUG-xxxx]` so cleanup is one grep. Performance bug: measure a baseline
and bisect instead of logging.

## Phase 5 — Fix with a regression test

If a correct seam exists, turn the minimised repro into a failing test there,
watch it fail, fix, watch it pass, then re-run the original Phase 1 loop. If
no correct seam exists, that is a finding: record it.

## Phase 6 — Cleanup

Original repro green, regression test in, every `[DEBUG-` line removed,
throwaway harnesses deleted, the confirmed hypothesis stated in the commit
message.

If two hypothesis rounds have both been wrong, this may be Failure Mode 2
or 3. Re-evaluate.

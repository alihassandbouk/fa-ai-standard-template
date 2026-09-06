# Specs

**Function:** The authoritative, future-tense source of what's being built.
Specs generate tickets — not the other way around. Each spec is reviewed at
Gate A before any building starts. Generated with `/spec-generate`,
critiqued with `/spec-review`.

One file per feature/area, e.g. `payment-feedback.md`.

---

## Template for a new spec

```
# <Feature Name>

## Requirements

### <REQ-ID> (keyed to HLR-XXX)
**Requirement (EARS-worded):** _..._
**Priority:** Must / Should / Could
**Done criteria (Given/When/Then):**
- Given ..., When ..., Then ...

(repeat per requirement)
```

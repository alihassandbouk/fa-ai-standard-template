# Architecture Decision Records (ADR)

The append-only history of the decisions that shaped this project.

A decision is **ADR-worthy** when all three hold: hard to reverse, surprising
without context, and the result of a real trade-off. Everything else is a
plan detail and stays in the plan, the ticket or the diary.

Every ADR-worthy decision gets a file here before the affected code is
written. `/fa:grill-with-docs` writes it as the decision lands; `/fa:sync`
and `/fa:remember save` flag any that slipped through.

Writing one: copy `0000-template.md` to the next number (`0003-title.md`
after `0002`) and fill it in. The status is Accepted from the start, because
the developer's confirmation is the acceptance. An ADR is append-only once
written: a change of mind is a new ADR, and the only edit the old one ever
receives is its status line, `Superseded by ADR-XXXX`.

# Hard reset (Failure Mode 2)

## Acknowledge the situation honestly

```
This session has gone too far in the wrong direction
to recover by patching. The right move is a clean start.

This is not a failure — it is the correct response
to a polluted context. A fresh session with clear intent
will be faster than continuing here.
```

## Save what is worth keeping

Before the session ends, extract anything valuable from the current state:

- What was the original feature supposed to do?
- What parts of the current implementation, if any, are actually correct?
- What has been learned about what does not work?
- What should the next session avoid?

Write this as a brief reset note:

```
## Reset Note — [Feature Name]

### What we were building
[Original feature description]

### What went wrong
[Honest summary of how the session went off track]

### What to avoid next time
[Specific approaches or patterns that did not work]

### Starting point for next session
[Where to begin fresh — what to keep, what to discard]
```

## Instruct the developer

```
Next steps:

1. Save this reset note somewhere accessible
2. End this session completely
3. Start a fresh session
4. Begin with /fa:remember restore if memory exists
5. Approach [feature name] again with the reset note as context
```

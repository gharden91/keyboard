# ADR-0002: KeyLayout holds its mode; everything takes bounds; modules are KB-prefixed

- **Status:** Accepted
- **Date:** 2026-11-06
- **Scope:** `Shared/` architecture (`SPEC.md` §4)
- **Shipped in:** spec change only, from [#4](https://github.com/gharden91/keyboard/issues/4)

## The question

The v1.3 `KeyLayout` was inconsistent. `keys(in:mode:)` took a mode but
`hitTest` didn't, and `keyCenters` was a stored property with neither bounds
nor mode, though centers depend on both. M1 needed one shape before any
geometry code exists. Separately, a target named `Layout` collides with
SwiftUI's `Layout` protocol.

## What we chose

```swift
protocol KeyLayout {
    var mode: KeyboardMode { get }
    func keys(in bounds: CGSize) -> [KeyRect]
    func hitTest(_ point: CGPoint, in bounds: CGSize) -> Key?
    func keyCenters(in bounds: CGSize) -> [Key: CGPoint]
}
```

A layout value *is* a configured layout: mode now, and split ratio and gap
later. Switching modes means swapping the layout value, which matches §4's
"swap layout models; never rebuild the view tree". Bounds come in on every
call because the keyboard's width changes with rotation and multitasking.
The half-aware API Split mode needs (`keyCenters(in:half:)` or `clusters(in:)`)
is deferred to M2, but must stay addable.

SwiftPM targets are `KBLayout`, `KBLexicon`, `KBAutocorrect`, `KBSwipe` and
`KBPersistence`, mapped onto the spec's folders with `path:`.

## What we turned down

| Option | Why not |
|---|---|
| Stateless layout, mode passed to every method | Every caller would thread mode, split ratio and gap through every call. That's easy to get out of step between `keys` and `hitTest`, and it grows with each Split setting. |
| Keep `keyCenters` as a property | A property can't reflect bounds, so it'd be stale after a rotation. |
| Plain module names (`Layout`, `Swipe`, …) | `Layout` shadows SwiftUI's `Layout` in any file importing both, which forces module-qualified names everywhere. |

## What would change our mind

If one layout instance genuinely needs to serve several modes at once (for
example, animating between Split and Full in a single pass), revisit passing
the mode per call.

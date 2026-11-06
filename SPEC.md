# Split Keyboard — Build Spec v1.3

*Supersedes v1.2. Tracked in [#2](https://github.com/gharden91/keyboard/issues/2); road map in [#1](https://github.com/gharden91/keyboard/issues/1).*

**Product:** a split-layout software keyboard for iPhone and iPad with swipe typing and on-device English autocorrect. No network. No analytics.
**Implementer:** Claude Code, supervised. **Owner:** you.
**Target:** unlisted App Store release, MIT open source, $2.99 one-time unlock.
**Status:** hexagon deferred to a gated future phase (§16).

## 1. Positioning

> *The only iPhone + iPad keyboard with split layouts **and** real autocorrect.*

Every incumbent misses one half of that sentence:

| Product | Split | Autocorrect | Devices | Price |
|---|---|---|---|---|
| KeyboardKit | Yes | Yes | iPhone + iPad | $1.99/mo, $19.99/yr |
| SplitKeyboard | Yes | **No** | iPhone + iPad + Duo | £4.99 once |
| ReachType | On wide screens only | **No** | iPhone + iPad + Duo | Free + $4.99 |
| Split Keyboard (Nunnari) | Yes | Yes | **iPad only** | $3.99 |
| SplitBoard / Banana Split | Yes | **No** | iPad only | Free |
| **This app** | **Yes, adjustable** | **Yes** | **iPhone + iPad** | **$2.99 once** |

**Definition of success:** you type on it daily for a month and reach for Apple's keyboard only for passwords and dictation.

## 2. Scope

| v1 (ship) | v1.1 | Future / maybe (§16) | Never (platform) |
|---|---|---|---|
| Split / Compact / Full modes | Next-word prediction | Hexagon Full-mode layout | Draggable floating keyboard |
| English swipe typing | Cursor mode on space | Two-thumb simultaneous swipe | Transparent/blurred backdrop |
| Autocorrect on space + 3-slot strip | Optional FUTO decoder | Additional input languages | System width override |
| iPad + Duo open-landscape split | Squircle key theme | | IAP / links inside extension |
| Host app: onboarding, settings, paywall | | | Apple emoji artwork |
| StoreKit 2 one-time unlock | | | Hinge sensor data |
| MIT source publication | | | |

**Explicitly not built in v1:** hexagon layouts, custom emoji keyboard, subscriptions, ads, analytics, accounts, sync.

## 3. Platform constraints (verified 6 Nov 2026)

These drive the architecture. Do not attempt workarounds.

| Constraint | Consequence |
|---|---|
| Extension width is always system-set to screen width; only **height** is yours | Split = center gap in a full-width view; "floating" = inset rounded card in the same strip |
| No access to pixels behind the keyboard | Simulate the floating card with your own opaque rounded panel; no live blur |
| ~60 MB `phys_footprint` ceiling, enforced by silent jetsam kill with **no crash log** | Hard budget; instrument on device |
| iPads vary: ~80 MB on iPad Pro, less on smaller devices | Never tune to one device |
| `UIViewController` dealloc order is fragile; a leaked keyboard view hierarchy costs ~3 MB per host app cycle, ×100 apps | Empty the view in `dealloc`; rebuild deferred by one main-queue turn |
| App Group writes fail **silently** without Full Access | Mirror writes into local defaults with timestamps |
| Must offer a way to reach the next keyboard | Globe key always present [^ba5aac#328] |
| Extensions may not include marketing, ads, or IAP | Paywall lives in the host app only [^ba5aac#318] [^ba5aac#206] |
| Must not launch other apps besides Settings | No keyboard→paywall deep link, ever [^ba5aac#334] |
| Must function without network **and** without Full Access | No network entitlement at all [^ba5aac#329] |
| No Apple emoji; no confusingly similar Apple UI | Own visual identity; emoji key hands off to system [^ba5aac#451] |
| Must not repurpose buttons for unrelated behaviors | Long-press-space cursor mode is fine; gimmicks are not [^ba5aac#335] |
| Duo hinge state is unavailable to extensions | Manual split toggle, not automatic split-on-open [^504418#55] |

## 4. Architecture

```
SplitKB/            # host app: onboarding, settings, paywall, licenses
KeyboardExt/        # UIInputViewController + keyboard UI
Shared/             # pure Swift package — ZERO UIKit imports
  Layout/           # KeyLayout protocol + RectLayout; geometry, hit testing
  Lexicon/          # word list, frequency, bigrams
  Autocorrect/      # UITextChecker + UILexicon + ranking
  Swipe/            # SwipeDecoder protocol + ShapeDecoder
  Persistence/      # App Group + local-defaults mirror
```

**Hard rules:**
- `Shared` must pass `swift test` on the Mac with no simulator. This is what keeps the agent's feedback loop fast.
- All cross-target state goes through the App Group **with** the local-defaults mirror.
- One controller, one root view. Swap layout models; never rebuild the view tree.
- `KeyLayout` is a protocol, not a struct. Every geometry-specific concern lives behind it — this is what makes the hexagon (§16) and any future layout cheap.

```swift
protocol KeyLayout {
    func keys(in bounds: CGSize, mode: KeyboardMode) -> [KeyRect]
    func hitTest(_ point: CGPoint, in bounds: CGSize) -> Key?
    var keyCenters: [Key: CGPoint] { get }   // consumed by SwipeDecoder
}
```

## 5. Layout engine

Three modes, one key model, `KeyboardMode` persisted per device class and orientation.

| Mode | Geometry | Availability |
|---|---|---|
| **Split** | Two self-contained clusters, 8–14% center gap, split ratio `r ∈ [0.35, 0.65]` persisted, per-half shift. **Render using the portrait key design even in landscape** — matches shipped behavior and keeps keys thumb-sized [^504418#50] | iPad both orientations; Duo open landscape |
| **Compact** | Centered inset rounded card, 24 pt margins, 16 pt corner radius, 70–80% width, collapsible to one row | iPhone all orientations; narrow iPad portrait |
| **Full** | Standard docked full width | Everything |

**Rules:**
- Keys defined in normalized 0–1 space, resolved to points at layout time.
- Minimum hit target **42 × 54 pt**. Assert in unit tests across all device classes.
- Gap is a spacer, not a key. Split ratio and gap width are user-adjustable in settings — this is the specific gap in KeyboardKit that its own reviewers complain about.
- Split on a non-Duo iPhone is **not offered in v1** but must not be architecturally excluded: SplitKeyboard ships it in portrait, so treat it as a v1.1 mode, not a forbidden one.
- Space-bar (and dismiss button) context menu toggles Split — the sanctioned pattern for a device whose hinge state you cannot read [^504418#57].

## 6. Swipe typing

No public API exists. Implement trajectory tracking, resampling, and decoding.

| Option | Accuracy | Effort | License |
|---|---|---|---|
| **A. Pure-Swift shape decoder** (SHARK2-style: resample to 64 points, DTW against ideal per-word paths, rank by unigram frequency) | Modest — good on common words, weaker on rare/short | 2–3 weeks of evenings | MIT, clean |
| **B. FUTO decoder** — 2.49M params, optional English context LM | Strong, competitive with majors | 4–6 weeks incl. inference wrapper | **Two blockers:** what looked like a permissive model license is contradicted by its own header — see note below. Reference library also unverified |
| **C. KeyboardKit Pro** | — | — | Its Pro list covers layout, themes, localisation, app-specific settings, autocomplete, AI — **not gesture typing** |

**Ship A. Keep the decoder swappable.** Don't plan on B until the licensing is resolved — the header on the weights I checked is Copyleft-style, which is incompatible with App Store distribution, and I could not verify the reference implementation's license at all. Treat FUTO as "maybe" alongside the hexagon.

```swift
protocol SwipeDecoder {
    func recognize(points: [SwipePoint],
                   layout: any KeyLayout,
                   context: [String]) async -> [SwipeCandidate]
}
```

**Behavior:**
- Begin tracking after 3+ points and 8 pt of travel; classify swipe vs. tap at touch-up using total distance and duration.
- Resample into the **active half's** coordinate space in Split mode. Passing whole-screen coordinates is the classic bug here.
- Decode **< 60 ms** at touch-up, off the main thread. Top candidate via `setMarkedText`; alternatives in the strip.
- Tapping a candidate replaces the marked text. Swipe-up-to-accept is v1.1.
- **Layout-agnostic requirement:** the decoder must consume `layout.keyCenters` and assume nothing about a rectangular grid. This keeps hexagon, staggered rows, and any future geometry free.

## 7. Autocorrect & suggestions

English only, on device, no network, no third-party SDK.

| Source | Role | Caveat |
|---|---|---|
| `UITextChecker` | Misspelling detection, guesses, partial-word completions | Guesses are **not consistently ranked** and can differ by device; completions come back alphabetically — this is why the frequency list exists |
| `UILexicon` | User's contacts, Settings → Keyboard → Shortcuts, common words | Instant personalization, zero training; callable from keyboard extensions |
| Bundled frequency list | Rank all candidates; top ~50k words + ~100k bigrams, target **< 4 MB on disk** | Memory-map it, don't parse into literals |

**Rules:**
- Correct on space/return only in v1. Use `setMarkedText` for the in-progress word; commit at the delimiter. Never `deleteBackward()×n + insertText()` — it breaks undo and races fast typing.
- Skip autocorrect entirely for `.emailAddress`, `.URL`, `.webSearch`, `.phonePad`, `.numberPad`, and any secure field.
- **Backspace immediately after a correction restores the original** and learns the user's spelling into the App Group store. This is not polish — see §14.
- Never modify tokens containing digits, embedded capitals, or a trailing apostrophe.
- `UILexicon` entries rank above dictionary entries for that user.

## 8. Behaviour checklist

- Globe key: 44 pt minimum, always visible, advances to next input mode.
- Shift: tap latches one character; double-tap caps lock; auto-unlatch after one character; distinct visual state in light and dark.
- Backspace: repeat after 500 ms at 100 ms intervals, accelerate after 2 s, haptic per delete.
- Key popups must render **inside** the extension view — you cannot draw above its top edge. Reserve vertical space or shrink popup height on the top row.
- Haptics via `UIFeedbackGenerator`; audio click via `AudioServicesPlaySystemSound`, not `AVAudioPlayer` (different bus, no audio session needed).
- All colors via asset catalog with light/dark variants. No hardcoded colors.
- Layout from the controller's own bounds. No `UIScreen.main`. Handle rotation and Stage Manager resize.
- Space bar shows "English (US)" on press-and-hold.

## 9. Host app & monetization

Screens: **Onboarding → Enable keyboard → Add keyboard → Unlock → Settings.**

- Onboarding one-liner: *"A split keyboard for iPhone and iPad. Types from both thumbs. English only. Nothing leaves your device."*
- Enable flow may deep-link to Settings; the extension may not.
- **Free tier:** Full mode, no swipe, no strip. **Unlock $2.99 non-consumable:** Split + Compact modes, swipe typing, suggestion strip. The free tier must be genuinely usable so the trial means something.
- Settings: split ratio, gap width, key height, sound, haptics, autocorrect on/off, swipe on/off, appearance, licences.
- Licences screen: MIT notice, plus any future FUTO attribution.
- **StoreKit 2 only.** `Transaction.currentEntitlements` + explicit Restore button. Test locally with a StoreKit configuration file. No receipt server.
- Pricing rationale: at the 15% Small Business rate, net ≈ **$2.54/copy**, so **~39 sales a year covers the $99 membership**. Undercut KeyboardKit's subscription and both $3.99–£4.99 one-time rivals. **No subscription** — it would require ongoing value the project won't deliver.

## 10. Performance & memory rules

- **Instrument memory at M0, before features.** Debug-only overlay showing `phys_footprint` and a host-app-cycle counter, compiled out of release builds.
- Memory-map the word list rather than loading literals; this is a measured 52 MB → 27 MB difference in a comparable implementation.
- Assert **p95 per-keystroke latency < 16.7 ms**, not total time.
- Unified logging (`os_log`) survives the jetsam kill; App Group file logging does not [^e51f55#91].
- Profile on device. The Simulator hides both latency cliffs and jetsam behavior [^e51f55#364].

## 11. Privacy & review posture

- Privacy policy URL, required in App Store metadata **and** linked in-app.
- App Privacy: **Data Not Collected.** No analytics, no crash reporting that transmits, no third-party SDKs.
- Keep the no-network-entitlement property auditable in the repo — it's the trust argument, and open source makes it checkable.
- Own visual identity. Do not replicate Apple's split-keyboard chrome, and **do not replicate Typewise's grid proportions or directional gesture map** (see §16).
- Ship **unlisted** first: same App Review, discoverable only by direct link. Flip to public after a month of personal use.

## 12. Milestones

| # | Milestone | Estimate | Done when |
|---|---|---|---|
| M0 | Toolchain: Xcode, paid account, both bundle IDs, agent build/run/screenshot loop, memory overlay | 2–4 h | Stub keyboard types "a" on device |
| M1 | `KeyLayout` protocol + `RectLayout` + Full mode, `swift test` | 1 weekend | Key rects correct across 5 device classes × 2 orientations |
| M2 | Split + Compact, ratio/gap persistence, mode switching | 3–5 evenings | You prefer typing in Split |
| M2b | Duo open-landscape split + space-menu toggle | 2–3 evenings | Split usable on Duo with no hinge access |
| M3 | Feel: shift/caps, delete repeat, popups, haptics, audio, dark mode | 1–2 weeks evenings | No perceptible latency; clean on rotation |
| M4 | Autocorrect v1 + 3-slot strip + learning store | 1 week evenings | < 5% false corrections on your own typing |
| M5 | `ShapeDecoder` swipe | 2–3 weeks evenings | Top-1 ≥ 70% on your 100-word test set |
| M6 | Host app: onboarding, settings, StoreKit, licences | 1 week evenings | Purchase + restore both work from clean install |
| M7 | Memory/stability hardening on device | 3–5 evenings | 48 h daily use, zero jetsam kills, footprint < 45 MB |
| M8 | Screenshots, metadata, unlisted submission | 1–2 weeks elapsed | Live |

**Total: ~10–13 weeks of evenings.**

## 13. Acceptance tests

Write these before the features.

| ID | Test | Pass |
|---|---|---|
| T1 | Split ratio + gap persist across app switches and reboot | Restored to ±0.02 |
| T2 | 200 words typed with Full Access off and airplane mode on | No dropped characters, no failed writes |
| T3 | 60 host-app switches in 10 minutes | `phys_footprint` stable, no upward trend |
| T4 | Type "teh" + space | Becomes "the"; one backspace restores "teh" |
| T5 | Swipe "keyboard" 20× | ≥ 14/20 top-1 correct |
| T6 | Email, URL, password fields | Autocorrect and swipe both disabled |
| T7 | Rotate mid-composition | No crash; marked text preserved or cleanly committed |
| T8 | Every key reachable; globe exactly 2 taps away | Verified in all 3 modes |
| T9 | p95 keystroke latency, 500 keystrokes | < 16.7 ms |
| T10 | Split → Full → Split 50× | No view-hierarchy growth, no lag |

## 14. Competitor notes (checked 6 Nov 2026)

Worth reading before building, not after:

- **KeyboardKit** — the only incumbent with traction. Adds split and Duo support. Its own reviewers complain about no **width** adjustment between halves, and resent the subscription. Those are your two openings.
- **SplitKeyboard** — closest feature twin on iPhone: splits in portrait *and* landscape, has English swipe, lacks autocorrect. Also ships a compact mode **including a floating-styled mode** — study it for §5.
- **ReachType** — split only "when there is enough room." Useful mainly to see how a free tier converts.
- **Banana Split** — removed spellcheck, autocorrect, suggestions, and auto-capitalization in 1.3.0 after users rebelled at unstoppable corrections. **The category is retreating from autocorrect.** Undo-on-backspace and "never correct the just-deleted word" are the difference between shipping autocorrect and shipping the thing people uninstall over.
- **Typewise** — the hexagon case, see §16.

## 15. Open decisions

1. **KeyboardKit as a base or not?** Its split feature now ships for Duo and all iPads. Confirm its licensing on that feature before building on it; if it's unrestricted, M2 and M2b may collapse.
2. **Swipe in v1 or v1.1?** Shipping without it gets you a usable daily keyboard three weeks sooner; shipping with it makes $2.99 easier to justify on day one.
3. **$2.99 or match $3.99?** Undercutting aids discovery among five lookalikes; the delta is unlikely to change a decided buyer's mind.
4. **Unlisted or public first?** Recommended: unlisted, then public with the repo.
5. **Verify on hardware:** whether iPadOS 26 removed split from iPad mini. If it did, the addressable market is larger and belongs in your App Store description.

---

## 16. Appendix — Hexagon layout (future / maybe)

**Status: not in v1. Not scheduled. Gated — see revisit criteria below.**

### Why it's attractive
Typewise's hexagon keys are roughly 70% larger than rectangular keys at equal screen width, aimed squarely at thumb accuracy. It has ~857 App Store ratings — by far the most social proof in this category.

### Why it's deferred, not rejected

**a) Geometric conflict with the core product.** Hexagons earn their benefit by tiling gap-free into a compact block. A split layout requires a central void, which forces either half-hexagons on the inner edge or the loss of a column — and either way each half is narrower, so the hexagons shrink back to roughly rectangular-key size. Hexagon and split are **rival answers to the same question** ("how do I hit the right key with my thumb?"): hexagons solve it by shape, split solves it by position. Stacking them is redundant and technically hostile. **Document this in code so nobody "fixes" it later.**

**b) Compact mode is the wrong place; Full mode is the right one.** Hexagon belongs as a **Full-mode-only** `KeyLayout` implementation, available on iPhone where split isn't offered anyway. It competes with nothing in your lineup there.

**c) Legal perimeter.** Typewise calls it "our patented hexagonal layout," and a co-founder is a named inventor on a hexagonal-keyboard patent. The publicised filing, however, covers text prediction and autocorrect, not geometry — and hexagon touchscreen keys have prior art going back to at least 1998. Practical read: **the shape is safe; their specific arrangement and directional gesture map are not.** Any hexagon work must diverge in row offset, key count, proportions, and gesture mapping.

**d) The company left the category.** Typewise's founders shut the consumer chapter in 2022 and now run an enterprise AI customer-experience platform; the app persists in maintenance mode. That's both an opportunity (orphaned users) and a warning — a well-funded, well-reviewed hexagon keyboard still couldn't sustain a consumer business, because the shape is beloved by a minority and rejected by the majority.

**e) Swipe is compatible.** The decoder is layout-agnostic by design (§6), so a hex lattice is feedable with no rework. Hexagons don't break gesture typing; they break split.

### Cheaper hedges to ship in v1's visual identity
- **Staggered outer columns** — recovers part of the thumb-accuracy gain, zero relearning, no patent proximity.
- **Squircle keys with wider gutters** and a distinctive palette — delivers the "this doesn't look like every other keyboard" feeling, retains QWERTY muscle memory, and reduces copycat exposure.

### Revisit criteria
Reopen this section only if **both**:
1. v1 has shipped and you personally still want it after a month of daily use, **and**
2. one of: sustained user requests for alternative layouts, or measurable evidence that your mis-tap rate is dominated by key *shape* rather than key *position*.

If the appeal was really "I want it to not look like every other keyboard," take the squircle hedge and close this appendix permanently.

### If built, the work is
~1–2 weeks of evenings: one new `KeyLayout` conformance, hex hit-testing (point-in-hexagon), visual redesign of key rendering, and a divergence pass against Typewise's arrangement. Swipe, autocorrect, and the host app are untouched — which is the entire payoff of the protocol design in §4.

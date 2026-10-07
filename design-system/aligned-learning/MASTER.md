# Design System Master File

> **LOGIC:** When building a specific page, first check `design-system/aligned-learning/pages/[page-name].md`.
> If that file exists, its rules **override** this Master file.
> If not, strictly follow the rules below.

---

**Project:** Aligned Learning
**Category:** Enterprise educational platform (organization internal use)
**Direction:** Professional, dense, credible. Dark-first with a fully supported light mode.

---

## Global Rules

### Identity

- **Product name:** `Aligned Learning` — used verbatim on every screen. No other brand
  variants ("Enterprise Technical Academy", "Aligned Automation", etc.) are allowed.
- **Audience:** working professionals in an organization. Tone: calm, factual, no hype,
  no gamification language, no emojis as icons.

### Color Palette (source of truth: `lib/theme/app_palette.dart`)

| Role | Dark | Light | Dart token |
|------|------|-------|-----------|
| Brand / Primary | `#3B82F6`-family blue | blue | `tokens.brand` |
| Canvas (background) | near-black navy | soft gray-white | `tokens.canvas` |
| Surface | raised dark panel | white panel | `tokens.surface` |
| Text primary | `#F5F7FA` | `#0B1220` | `tokens.textPrimary` |
| Text secondary | slate 300 | slate 700 | `tokens.textSecondary` |
| Text muted | slate 500 | slate 500 | `tokens.textMuted` |
| Hairline | 10% white | 10% black | `tokens.hairline` |
| Success | green | green | `tokens.success` |
| Danger | red | red | `tokens.danger` |

**Rules:**
- Never hardcode `Color(0xFF…)` in screens — always `context.tokens.*` or
  `Theme.of(context).colorScheme.*`.
- Dark-only constants (`AppPalette.dark*` referenced directly from widgets) are banned;
- every color must resolve per active theme so light mode passes **4.5:1** contrast.
- Status/tech pill colors (`TechPalette`, `DocPalette`) must supply a light-mode variant.

### Typography (source of truth: `lib/theme/app_typography.dart`)

- **UI / body:** Inter
- **Display / headings:** Outfit
- **Data / durations / sizes:** JetBrains Mono
- **Floor:** no text below **12 dp** anywhere (labels, chips, metrics, nav tabs).
- **Ceiling:** body copy 14–16 DP; screen titles 22–28 DP; hero only on Course detail.
- Letter-spacing: uppercase eyebrows 1.2–3.0, everything else 0.
- Fonts must be **bundled** in `pubspec.yaml` (no runtime network fetch).

### Spacing — strict 4dp grid (`AppSpace`)

| Token | Value | Usage |
|-------|-------|-------|
| `xs` / `sm` | 4 / 8 | icon gaps, inline |
| `md` / `lg` | 12 / 16 | component padding |
| `xl` / `xxl` | 20 / 24 | page gutter, card padding |
| `section` | 28 | between page sections |
| `gutter` | 20 | horizontal page margin |
| `touchTarget` | 48 | **minimum** tappable size, no exceptions |
| `dockClearance` | 104 | scroll bottom inset under floating dock |

### Radius (`AppRadius`): 8 / 12 / 16 / 20 / 28 / pill. One radius per role.

### Motion (`AppMotion`)

- Micro-interactions 150–300 ms, page transitions ≤ 400 ms, curve `expo.out`.
- **Reduce motion** setting must scale all `AppMotion` durations to near-instant.

---

## Component Specs (source of truth: `lib/widgets/app_components.dart`)

Use these — do not hand-roll equivalents:

| Component | Use for |
|-----------|---------|
| `AppPageHeader` | every screen header (icon tile + eyebrow + title + hairline) |
| `AppSurface` | the one card primitive |
| `AppButton` | all actions (filled / outlined / ghost / danger) |
| `AppIconButton` | icon actions — always 48 dp touch target |
| `AppPill` | status & metadata chips |
| `AppSegmentControl` | 2–4 way in-screen switching |
| `AppEmptyState` | empty states — title + message + action button |
| `AppSkeletonBox` | loading placeholders |
| `AppProgressBar` | determinate progress |
| `SectionHeader` | section eyebrows |
| `showAppSnack()` | all toasts — must support Undo for destructive actions |

**States:** every data-backed screen implements all four — loading (skeleton) /
content / empty (with action) / **error with Retry**. Silent failure is a bug.

---

## Style Guidelines

**Style:** Enterprise technical — dense, quiet, high information density.
Dark-first (default), light mode is a peer implementation, not an afterthought.

**Keywords:** professional, credible, calm, systematic, data-forward, accessible.

**Do:**
- Token-driven color and type everywhere
- Visible focus states, ≥48 dp targets, ≥12 dp text
- Real numbers from data (no hardcoded stats)
- Transitions 150–300 ms

**Don't:**
- Emojis as icons (use Material/`Icons.*` consistently)
- Fake telemetry, placebo settings, actions that do nothing
- Brand-name drift
- Hardcoded hex colors, hardcoded statistics
- Text < 12 dp, touch targets < 48 dp
- Low-contrast text (minimum 4.5:1)

---

## Pre-Delivery Checklist

- [ ] `dart analyze` clean
- [ ] Brand name is "Aligned Learning" on every screen
- [ ] Dark **and** light mode both reviewed on the changed screen
- [ ] No hardcoded `Color(0xFF…)` or font sizes < 12 dp in screens
- [ ] All four states handled (loading / content / empty / error+Retry)
- [ ] Touch targets ≥ 48 dp, semantics labels present
- [ ] Destructive actions confirm or offer Undo
- [ ] Reduce motion respected by new animations

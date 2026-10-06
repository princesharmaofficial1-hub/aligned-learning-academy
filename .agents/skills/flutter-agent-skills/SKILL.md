---
name: flutter-agent-skills
description: Expert Flutter and Dart development workflows, architectural patterns, state management, widget optimization, responsive design, and bug fixing across mobile, web, and desktop.
---

# Flutter & Dart Agent Skills

Comprehensive production runbook and engineering patterns for Flutter applications.

## 1. Architecture & Project Structure
- **Feature-first / Layer-first structure**:
  - `models/`: Immutable data classes with copyWith, fromJson, toJson.
  - `providers/` / `blocs/`: State management decoupled from presentation.
  - `screens/`: High-level views that compose reusable widgets.
  - `widgets/`: Pure, reusable, self-contained presentation components.
  - `services/`: External APIs, database, network, local storage.
  - `theme/`: Centralized palette, typography, design tokens, and components.

## 2. Widget Tree & Layout Guidelines
- **Zero Overflow Guarantee**:
  - Always protect rows that contain dynamic text using `Flexible` or `Expanded`.
  - Use `Wrap` or `SingleChildScrollView` for variable tags, chips, or badge rows.
  - Use `LayoutBuilder` to provide adaptive layouts across compact, medium, and expanded widths.
  - In `CustomScrollView`, use `SliverList` with delegates for large lists rather than creating dozens of `SliverToBoxAdapter` elements.
- **Touch Targets & Accessibility**:
  - Minimum touch target is 48x48dp on Android and 44x44pt on iOS.
  - Wrap interactive elements in `Semantics(button: true, label: ...)`.
  - Support accessibility font scaling without UI breaking by clamping text scalers gracefully.

## 3. State Management Best Practices
- **Provider / Riverpod / BLoC**:
  - Never call state mutations or async operations directly inside `build()`.
  - Use `context.select()` or `Consumer` to rebuild only the subtrees that depend on changed state.
  - Keep controllers (`TextEditingController`, `ScrollController`, `AnimationController`) tied to the State lifecycle with proper `dispose()`.

## 4. Theme & Dark/Light Mode Consistency
- Use centralized Design Tokens (`AppSpace`, `AppRadius`, `AppIcon`, `AppMotion`, `AppAlpha`).
- Never hardcode colors in widgets. Derive colors from `Theme.of(context).colorScheme` or typed `ThemeExtension` tokens.
- Always verify contrast in both Dark and Light modes.

## 5. Performance & Resource Management
- Mark static widgets and icon constructors with `const` to avoid redundant allocations.
- Cancel Timers and StreamSubscriptions in `dispose()`.
- Use cached image fallbacks with placeholders to avoid flickering.

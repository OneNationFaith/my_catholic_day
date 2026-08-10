# One Nation Faith Technical Blueprint

**Current checkpoint:** August 10, 2026
**Platform:** Flutter / Dart
**Repository:** `OneNationFaith/my_catholic_day`

## Core Principle

Keep source domains separate and join them deliberately.

Do not let one convenient data source become the authority for unrelated domains.

## Current Application Structure

Primary source layout:

- `lib/data/` — data repositories and fixed data helpers
- `lib/models/` — domain models
- `lib/screens/` — UI screens
- `lib/services/` — application/domain services and databases
- `lib/theme/` — theme definitions
- `assets/` — bundled databases, calendar data, lectionary data, images
- `tool/` — source-fetching, normalization, and build utilities
- `test/` — automated tests

## Scripture Architecture

### Display text

Primary bundled display Bible:
- Douay-Rheims

Asset:
- `assets/databases/dra.db`

Reason:
- Catholic translation
- suitable licensing/public-domain posture for bundled display text

### Metadata/reference support

`assets/databases/webc.db` remains intentionally because tooling uses it for Bible metadata/reference validation.

The app should not treat that database as the displayed Catholic Bible merely because it exists.

## Lectionary Architecture

Pipeline:

**Lectionary source data → normalized Mass reading references → bundled annual JSON → Scripture database lookup → displayed Scripture text**

Key rule:

The lectionary answers **what passages are assigned**.

The Scripture database answers **what those passages say in the bundled Bible translation**.

These are separate responsibilities.

Current assets include:
- `assets/data/lectionary/2026.json`
- `assets/data/lectionary/2027.json`

USCCB pages may be used for authoritative manual verification where appropriate, but automated USCCB scraping is not part of the architecture.

## Liturgical Calendar Architecture

Pipeline:

**LitCal annual civil-year data → One Nation Faith normalization/U.S. rules → bundled annual calendar JSON → repository → CatholicDayService → UI**

Current production asset:
- `assets/data/liturgical_calendar/2026.json`

Source snapshots:
- `tool/source/liturgical_calendar/2026_litcal_raw.json`
- `tool/source/liturgical_calendar/2026_litcal_ascension_thursday_raw.json`

Tools:
- `tool/fetch_liturgical_calendar.dart`
- `tool/build_liturgical_calendar.dart`

Generated drafts are not committed as source-of-truth assets.

## Calendar/Lectionary Separation

This is a non-negotiable architectural rule.

The calendar determines:
- liturgical day identity
- season
- rank/grade
- color options
- precedence
- optional memorials
- vigils
- regional calendar variants
- U.S. observances

The lectionary determines:
- Mass reading references
- reading choices
- Psalm reference/response metadata
- Gospel acclamation reference
- reading order

A calendar event's grade must not automatically select lectionary readings.

## Regional Ascension

The 2026 calendar carries a regional Ascension Thursday variant.

Current state-code MVP:
- CT
- MA
- ME
- NE
- NH
- NY
- PA
- RI
- VT

Represented ecclesiastical provinces:
- Boston
- Hartford
- New York
- Omaha
- Philadelphia

The repository accepts an optional state code. A user setting still needs to be wired into the service/UI so the correct variant is selected automatically.

State-based handling is an MVP approximation; future diocesan nuance may require a more precise location model.

## U.S. Normalization Layer

Raw provider data should be preserved for audit.

One Nation Faith corrections or generated events belong in normalization fields rather than silently mutating the original source record.

Examples already handled:
- June 13, 2026 weekday/optional memorial combination
- Saturday Blessed Virgin Mary option
- 2026 Assumption obligation normalization
- regional Ascension overrides

## Holy Days of Obligation

Do not blindly trust generic provider settings.

U.S. obligation status can depend on:
- national norms
- weekday placement
- transfers
- regional rules

Annual validation against authoritative U.S. norms is required before shipping each year's calendar.

## Liturgical Colors

Provider data can contain multiple allowable colors.

UI color resolution must be deliberate rather than always selecting the first array value.

Known policy examples:
- prefer rose when rose is an allowed option for Gaudete/Laetare
- use red for martyr celebrations where appropriate

## User Data

Current user-name personalization uses `SharedPreferences`.

Near-term:
- add a state/location preference using the same local-first approach

Sensitive spiritual information—especially conscience/confession data—should default to local/private handling.

## Testing Standard

Minimum before a milestone commit:

1. `flutter analyze`
2. `flutter test`
3. focused tests for new edge cases
4. `git diff --check`
5. inspect `git status`
6. commit only expected files
7. push a clean checkpoint

Calendar tests currently protect:
- default Sunday Ascension behavior
- New York Thursday Ascension behavior
- June 13, 2026 normalization
- 2026 Assumption obligation normalization

## Yearly Calendar Workflow

For each new year:

1. Fetch national U.S. civil calendar source.
2. Fetch Thursday-Ascension variant source.
3. Build normalized annual draft.
4. Validate date coverage and key resolution.
5. Review regional transfers.
6. Verify U.S. Holy Day of Obligation exceptions.
7. Review special collisions/optional memorials.
8. Produce `assets/data/liturgical_calendar/<year>.json`.
9. Add focused tests for unusual annual cases.
10. Run full analyzer/test suite.
11. Commit source snapshots, builder-compatible data, and production asset.

Goal: yearly updates should be repeatable and verification-heavy, not hand-built.

## Source-Control Rule

Treat GitHub as the durable source of truth for committed project work.

Avoid remote edits while local uncommitted work exists because that can create divergence.

When AI assistance is used:
- ChatGPT remains the primary architecture/planning source of truth.
- Claude may be used as a secondary repository worker or code reviewer.
- Cross-file changes should be reviewed and tested before acceptance.

## Near-Term Technical Priorities

1. Wire local state preference into calendar resolution.
2. Add service-level tests.
3. Improve display-title normalization.
4. Continue App V1 features.
5. Establish 2027 calendar asset generation using the existing pipeline.
6. Keep governance documents updated when major architectural decisions change.

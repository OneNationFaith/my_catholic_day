# One Nation Faith Product Roadmap

**Current checkpoint:** August 10, 2026
**Current phase:** Phase 1 — Foundation

## North Star

Build a Catholic companion that helps users move from **Know → Understand → Live**, with practical guidance that leads to prayer, Scripture, sacramental life, parish connection, and everyday Catholic living.

## Phase 1 — Foundation

### Completed or substantially completed

- Public product identity: **One Nation Faith**
- Flutter app shell and Windows branding
- Splash screen and logo integration
- Main navigation structure:
  - Today
  - Pray
  - Learn
  - Live
  - My Church
- Local user-name personalization
- Douay-Rheims Scripture database
- Daily readings infrastructure
- Gospel introduction/conclusion handling
- Douay-Rheims Psalm-numbering correction
- 2026 lectionary data
- 2027 lectionary groundwork/data
- 2026 U.S. liturgical calendar pipeline
- Regional Ascension support architecture
- U.S. normalization for known 2026 edge cases
- Calendar repository and service integration
- Focused calendar tests
- GitHub source control and clean checkpoint

### Next foundation work

1. Add a user location/state preference so regional Ascension rules can be applied automatically.
2. Add focused service-level tests for calendar-to-UI mapping.
3. Normalize user-facing liturgical titles consistently.
4. Review Holy Day of Obligation behavior annually against U.S. norms.
5. Establish the repeatable 2027 calendar generation and verification workflow.
6. Preserve and maintain the four project governance documents in `docs/`.
7. Continue app V1 feature development.

## App V1 Feature Plan

### Today

Goal: make the home screen the user's daily Catholic starting point.

Current:
- Date and greeting
- Liturgical celebration
- Season and color
- Rosary mysteries
- Holy Day of Obligation status
- Today's Readings
- Today's Prayer
- Saint of the Day

Planned:
- Contextual “Did You Know?” cards
- Better liturgical explanations
- Deeper Saint content
- Region-aware calendar behavior
- Links into related prayer and learning content

### Pray

Current:
- Core prayer experience
- Existing prayer pages

Planned:
- Traditional prayers
- Rosary
- Divine Mercy Chaplet
- Novenas
- Guided prayer
- “Pray With Me” style flows
- Liturgy of the Hours guidance where appropriate

### Learn

Planned:
- Clear Catholic teaching
- Catechism-linked explanations
- Scripture explanations
- Sacramental teaching
- “Why Catholics do this” explanations
- Searchable reference content

### Prepare for Sacraments

Planned:
- Baptism
- Confession
- Eucharist
- Marriage
- Other sacramental preparation as appropriate

### Confession

Planned:
- Examination of Conscience
- Preparation flow
- Step-by-step in-confessional guide
- Act of Contrition support
- Strong privacy model
- No unnecessary central storage of conscience/confession data

### Live

Planned:
- Practical Catholic living
- Works of mercy
- Fasting/abstinence reminders and explanations
- Household/family Catholic practices
- Seasonal/liturgical living
- Ways to put teaching into action

### My Church

Planned:
- Parish information
- Diocese information
- Mass/confession links or schedules where reliable
- Localized Catholic resources
- Regional settings

### Search

Planned:
- Cross-feature search
- Prayer
- Scripture
- Catholic teaching
- Saints
- Sacraments
- Parish/resource content

## Phase 2 — Daily Companion

Expand the app beyond isolated features into a connected daily experience.

Key principle:
- **Know** what the Church teaches or celebrates.
- **Understand** what it means.
- **Live** it through a concrete next action.

Expected work:
- Cross-link Today, Pray, Learn, and Live
- Context-aware recommendations
- Seasonal content
- Family-friendly pathways
- More robust personalization without unnecessary data collection

## Phase 3 — Website

Build the broader One Nation Faith web presence around:

- Discover
- Learn
- Live
- Read
- Shop
- About

The website may carry longer-form evergreen content while the app remains optimized for daily use and guided actions.

## Phase 4 — Ecosystem

Long-term expansion may include:

- Broader Catholic resource library
- Parish/diocesan integrations
- Family resources
- Books and publications
- Educational materials
- Media
- Carefully chosen commerce that supports rather than replaces the mission

## Development Rule

Before a major feature or architecture decision, ask:

1. Does it conform to the Constitution?
2. Does it serve a real user need?
3. Is the Catholic content accurate?
4. Are sourcing, licensing, and privacy handled correctly?
5. Does it belong in the current phase?
6. Can we test or verify the important behavior?

If not, stop and resolve the problem before expanding the feature.

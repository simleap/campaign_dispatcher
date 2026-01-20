# Campaign Dispatcher (Rails 7)

Campaign Dispatcher is a small Rails 7 app for creating “campaigns” with recipients and dispatching them asynchronously via Sidekiq, with live progress updates powered by Turbo Streams.

This project is intentionally scoped for a short technical assessment: it demonstrates Rails conventions, pragmatic architecture, and a clean UI — without pulling in unnecessary frontend or infrastructure complexity.

## Product Snapshot

- Campaign CRUD with nested recipients (email and/or phone number)
- One-click dispatch that runs asynchronously (Sidekiq) and streams realtime progress updates
- Idempotent dispatching (safe to retry) with Postgres advisory locking to prevent double-processing
- “Dispatched campaigns cannot be edited” guard to preserve data integrity

## Stack

- Rails 7.2.x + PostgreSQL
- Hotwire (Turbo Streams + Turbo Frames) + a small Stimulus controller for nested form rows
- Sidekiq + Redis
- Tailwind CSS
- RSpec (request, job, system, and service specs)

## Setup

### Prereqs

- Ruby (see `.ruby-version`) + Bundler
- PostgreSQL running locally
- Redis running locally
- Google Chrome (for JS system specs via Selenium)

### Install

```bash
bundle install
bin/rails db:prepare
```

## Run

### Option A: `bin/dev` (recommended)

Runs Rails, Tailwind watcher, and Sidekiq from `Procfile.dev`.

```bash
bin/dev
```

### Option B: separate processes

```bash
bin/rails server
bundle exec sidekiq -C config/sidekiq.yml
```

### Environment variables

- `REDIS_URL` (defaults to `redis://localhost:6379/1`)
- `SIDEKIQ_CONCURRENCY` (defaults to `5`)

### Sidekiq Web (development only)

- Visit `http://localhost:3000/sidekiq`

## How Dispatch Works

- Campaign statuses: `pending` → `processing` → `completed`
- Recipient statuses: `queued` → `sent` / `failed`
- Dispatch is triggered from the campaign show page, and uses a two-layer safety approach:
  - Start guard: an atomic DB update transitions `pending → processing` once.
  - Worker guard: a Postgres advisory lock ensures only one worker can process a campaign at a time.
- Idempotency: dispatch only processes recipients with `status = queued`, so retries won’t re-send recipients already `sent`/`failed`.
- Failure handling: each recipient is handled independently — failures are captured into `status=failed` + `error_message`, and the job continues.

### Delivery simulation

To keep the assessment self-contained, delivery is stubbed (no external providers):

- `Campaigns::DeliveryStub` simulates “sending” with a random delay per recipient (`sleep(rand(1..3))`) in non-test environments.
- Message content comes from real templates:
  - `app/views/campaigns/dispatch_email.text.erb`
  - `app/views/campaigns/dispatch_sms.text.erb`

## Realtime UI (Turbo Streams)

The campaign show page subscribes to Turbo Streams for that campaign.

During dispatch:

- Each recipient row is broadcast-replaced as soon as its status changes.
- The progress/header component is broadcast-replaced after each recipient update.
- No polling is used.

## “SPA-like” navigation (Turbo Frames)

The app uses a top-level Turbo Frame for page navigation so moving between campaign pages feels instant and avoids full refreshes, while keeping the server-rendered Rails approach.

## Data Integrity

- String-backed enums in the Rails models.
- DB check constraints enforce valid `status` values.
- DB check constraint enforces `email` or `phone_number` is present for each recipient.
- Indexes:
  - `recipients (campaign_id, status)` for progress queries
  - unique `recipients (campaign_id, email)` to prevent duplicates
  - unique `recipients (campaign_id, phone_number)` to prevent duplicates

## Tests

```bash
bundle exec rspec
```

- Request spec covers campaign creation with nested recipients.
- Job/service specs cover dispatch transitions, failure handling, and idempotency.
- System spec (JS) creates a campaign via the nested form and asserts live Turbo Stream updates.

## Architectural Decisions (and why)

### The Rails Way

- Conventional RESTful controllers and routes (`CampaignsController` + nested attributes)
- Clear model boundaries with validations + DB constraints (defense in depth)
- Small service objects for orchestration and testability:
  - `Campaigns::Dispatch` (starts dispatch atomically)
  - `Campaigns::DispatchRunner` (core processing loop)
  - `Campaigns::DeliveryStub` + `Campaigns::MessageTemplates` (delivery + templates)
  - `Campaigns::DispatchBroadcaster` (Turbo Stream broadcasts)

### Hotwire Proficiency

- Turbo Streams do the heavy lifting for realtime UI updates (server-rendered partial replacement; no polling).
- Stimulus is used only for nested-form ergonomics (add/remove recipient rows).
- Turbo Frames provide “SPA-like” navigation without introducing a client-side framework.

### Architectural sanity (failures + retries)

- Dispatch is safe to retry:
  - Idempotency: only `queued` recipients are processed.
  - Advisory lock: prevents two workers processing the same campaign concurrently.
  - Per-recipient exception handling: one bad recipient won’t stop the whole campaign.
- We intentionally let unexpected runner errors bubble to Sidekiq so retries can occur (while still preventing duplicate work via idempotency + locking).

### Tailwind polish

- Custom pages (no scaffolds), consistent spacing/typography, badges, breadcrumbs, and accessible form controls.

### Pragmatism (6-hour trade-offs)

- Focused on correctness, observability, and a smooth UX: nested forms, realtime progress, retry-safe jobs, and strong data integrity.
- Stubbed delivery (no provider integration) but still implemented real templates to show how messaging would be structured.
- Skipped auth/roles/multi-tenancy to keep the scope aligned with the assessment window.

## Future Improvements (If More Time)

If this were a 40-hour build, I’d focus on production hardening and scaling:

- Fan-out delivery (one job per recipient or batches) with rate limiting and provider-specific retry policies
- Integrate real providers (email/SMS), including provider error mapping and dead-letter queues
- Observability: structured logs, per-recipient delivery attempts, metrics, tracing, and an audit log
- Admin UX: filters, search, pagination, export, and better failure introspection
- Auth + authorization + multi-tenant safety (ownership, roles, and access control)
- Recipient import (CSV), smarter normalization, duplicate detection, and richer validation/formatting

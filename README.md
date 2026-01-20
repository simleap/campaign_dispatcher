# Campaign Dispatcher (Rails 7)

A small Rails 7 app for creating campaigns with recipients and dispatching them asynchronously with live progress updates via Turbo Streams.

## Stack

- Rails 7.2.x + PostgreSQL
- Hotwire (Turbo Streams) + a small Stimulus controller for nested form rows
- Sidekiq + Redis
- Tailwind CSS
- RSpec (request, job, system specs)

## Setup

### Prereqs

- Ruby (see `.ruby-version`)
- PostgreSQL running locally
- Redis running locally

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

### Sidekiq Web (development only)

- Visit `http://localhost:3000/sidekiq`

## How Dispatch Works

- Campaign statuses: `pending` → `processing` → `completed`
- Recipient statuses: `queued` → `sent` / `failed`
- Dispatch is triggered from the campaign show page.
- Double-dispatch prevention:
  - Controller uses an atomic update to move a campaign from `pending` to `processing` once.
  - `DispatchCampaignJob` also takes a Postgres advisory lock to ensure only one worker processes a campaign at a time.
- Idempotency:
  - The job only processes recipients with `status = queued`, so retries won’t re-process already `sent`/`failed` recipients.

### Delivery simulation

To keep the assessment self-contained, delivery is simulated:

- Random delay per recipient (`sleep 1..3`) in non-test environments.
- Recipients are marked `sent` once processed.

## Realtime UI (Turbo Streams)

The campaign show page subscribes to Turbo Streams for that campaign.

During dispatch:

- Each recipient row is broadcast-replaced as soon as its status changes.
- The progress/header component is broadcast-replaced after each recipient update.
- No polling is used.

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
- Job spec covers dispatch transitions, failure handling, and idempotency.
- System spec (JS) creates a campaign via the nested form and asserts live Turbo Stream updates.

## Architectural Notes

- Turbo Streams are used for realtime updates because they keep rendering server-side and minimize frontend state.
- Stimulus is used only where it adds UX value (dynamic nested recipient rows).

## Future Improvements (If More Time)

- Fan-out: enqueue one job per recipient (or batch) for better parallelism.
- Rate limiting, retries with backoff, and provider integrations (email/SMS gateways).
- More robust observability (structured logs, per-recipient attempts, audit trail).
- Auth + per-user ownership, authorization, multi-tenant safeguards.
- Import recipients (CSV upload), duplicate detection/normalization, email/phone validation.

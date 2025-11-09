Below is a concise-but-complete **PRD** you can hand to yourself/teammates and build from right away. It’s tailored to your current todo/contacts/task tracker and the **TanStack Start Hackathon** requirements.

---

# PRD — **HackPack** (Event‑to‑Workspace Planner)

**One‑liner**
Paste any hackathon/conference page → **Firecrawl** extracts key info (deadlines, rules, judges, prizes, social tags) → **Convex** seeds a collaborative workspace with tasks + a shared calendar. **CodeRabbit** PR reviews gate task completion. **Sentry** instruments the flow. **Autumn** meters AI helpers. Hosted on **Netlify**. **Cloudflare Turnstile** protects imports.

**Target deadline**

* Submission due: **Monday, November 17, 2025, 12:00 PM PT** (public URL + video demo + `tanstackstart` tag on Vibe Apps).

---

## 1) Goals & Non‑Goals

**Goals**

1. One‑click import of an event URL → actionable workspace (tasks + calendar) in ≤60s.
2. Real‑time collaboration (presence, comments, drag‑drop) via Convex live queries.
3. Code‑aware tasks that reflect **CodeRabbit** PR review status.
4. Streaming UX using **TanStack Start** (no spinners-only waits).
5. Sponsor coverage: TanStack Start, Convex, Netlify, Firecrawl, Sentry, Autumn, Cloudflare, CodeRabbit—used **meaningfully**.

**Non‑Goals**

* Native mobile apps.
* Complex role-based access control beyond Owner/Editor/Viewer.
* Full CRM; contacts are light-weight for the hackathon use case.

---

## 2) Success Metrics (MVP)

* **TTV (Time‑to‑Value):** From “Paste URL” → “Workspace usable” **≤60s** p90.
* **Extraction quality:** Auto-create **≥10** relevant tasks + **≥2** calendar events from a typical Luma/Devpost page.
* **Realtime:** Cross‑tab task move **<300ms** perceived latency.
* **PR gating:** Task with `prUrl` changes state automatically within **≤10s** after CodeRabbit approves.
* **Stability:** Sentry error rate **<1%** sessions during demo.
* **Submission readiness:** Public, non‑localhost URL; video demo; sponsor usage checklist page.

---

## 3) Users & Personas

* **Hackathon Solo Builder**: Needs instant plan and deadlines; minimal setup.
* **Small Team (2–4)**: Needs live collaboration, shared calendar, PR‑gated tasks.
* **Mentor/Judge Viewer**: Read‑only shared link to see progress & sponsor usage.

---

## 4) Core User Stories (MVP)

1. **Import**

   * As a builder, when I paste an event URL, I see a **streaming** progress log and, within a minute, my workspace has tasks and calendar items seeded from the page.
   * As a builder, I can preview extracted items, edit, and confirm “Create Plan”.

2. **Tasks & Collaboration**

   * As a team, we see a **Kanban** (Backlog / In Progress / Blocked / Done) that updates in real time.
   * As a user, I can comment on tasks and see presence/typing indicators.

3. **Calendar**

   * As a user, I see upcoming deadlines in week/month view and can **subscribe via ICS**.

4. **Dev Workflow**

   * As a developer, I link a task to a **GitHub PR**; the task auto‑unblocks when **CodeRabbit** approves.

5. **AI & Billing (Autumn)**

   * As a user, I can click **“Summarize rules into compliance tasks”** and see credits decrement via Autumn.

6. **Security & Abuse**

   * As a user, I must pass **Cloudflare Turnstile** to start an import.

7. **Observability**

   * As a developer, I can see **Sentry** traces and errors for import + streaming.

8. **Share**

   * As a builder, I can create a **public read‑only link** to my workspace and a **Sponsor Usage** page that lists where each sponsor is integrated.

---

## 5) Scope (MVP vs. Stretch)

**MVP**

* Import URL → seed tasks & calendar.
* Kanban, comments, presence.
* ICS feed.
* PR gating via CodeRabbit/GitHub webhook.
* One AI helper (Compliance summarizer) billed via Autumn.
* Turnstile on import form.
* Sentry errors + performance.
* Public read‑only share link + Sponsor Usage page.
* Hosted on Netlify; environment config documented.

**Stretch (time‑boxed, safe to cut)**

* Cloudflare Workers AI for classification of extracted sections.
* R2 storage for cover images.
* “Smart schedule” that auto‑inserts prep windows.

---

## 6) Information Architecture & Navigation

* `/` — Dashboard (upcoming deadlines, recent activity).
* `/import` — Paste URL → streamed extraction → preview → “Create Plan”.
* `/tasks` — Kanban with filters/search; quick-create.
* `/tasks/:id` — Task detail, comments, presence cursors.
* `/calendar` — Week/Month + **GET /calendar/:workspaceId.ics**.
* `/dev` — GitHub PRs + CodeRabbit status chips.
* `/settings` — Tokens (Firecrawl, Autumn), SSO placeholders, Sentry health, Turnstile test.
* `/share/:slug` — Public read‑only view (Dashboard, Tasks, Calendar).
* `/sponsors` — Auto‑generated Sponsor Usage checklist.

---

## 7) Data Model (Convex)

```
users:        { _id, name, email, avatarUrl }
workspaces:   { _id, name, slug, ownerId }
memberships:  { _id, userId, workspaceId, role: 'owner'|'editor'|'viewer' }
imports:      { _id, workspaceId, url, status: 'queued'|'running'|'done'|'error',
                logs: [{ts, level, msg}], startedAt, finishedAt, raw?, mapped? }
events:       { _id, workspaceId, title, startAt, endAt, source: 'import'|'manual', url? }
tasks:        { _id, workspaceId, title, status: 'backlog'|'in_progress'|'blocked'|'done',
                dueAt?, assigneeId?, labels: string[], sourceId?: importId, prUrl?, prStatus? }
contacts:     { _id, workspaceId, name, email?, links?: string[] }
comments:     { _id, taskId, authorId, body, createdAt }
presence:     { _id, workspaceId, userId, lastSeenAt, cursor? }
billing:      { _id, workspaceId, credits: number, provider: 'autumn' }
```

---

## 8) System Architecture (high‑level)

```
[Browser]
  ├─ TanStack Start (full-doc SSR, loaders, streaming)
  ├─ Sentry SDK
  └─ Cloudflare Turnstile widget
        │
        ▼
[Start Server Functions] —— calls ——> [Convex actions/queries]
        │                                ├─ persist imports/tasks/events
        │                                ├─ presence live queries
        │                                └─ webhook handlers (GitHub/CodeRabbit)
        ├─ Firecrawl API (extract page)
        ├─ Autumn API (credits)
        └─ GitHub Webhooks (PR + CodeRabbit checks)
        
[Netlify] hosts app (env vars), deploy previews
```

---

## 9) APIs / Server Functions (examples)

**Start server functions**

* `POST /api/import.start`: body { url, turnstileToken }

  * Validate Turnstile → enqueue Convex action → return importId; start **stream**.
* `GET /api/import.stream?importId=...`: SSE/stream; emits logs and partial results.
* `GET /calendar/:workspaceId.ics`: returns `text/calendar`.

**Convex actions/queries**

* `imports.start(url, workspaceId)`
* `imports.appendLog(importId, msg)`
* `imports.finish(importId, mapped)`
* `tasks.create/update/reorder`
* `tasks.linkPR(taskId, prUrl)`
* `presence.heartbeat(workspaceId)`
* `billing.getBalance(workspaceId)`, `billing.consume(workspaceId, n)`
* `ai.summarizeRules(importId)` (checks Autumn credits first)

**Webhooks**

* `POST /webhooks/github` (PR opened/synchronized/review events + CodeRabbit check runs)

  * Update `tasks.prStatus` = `pending` | `changes_requested` | `approved`
  * If `approved` → unlock task completion.

---

## 10) Firecrawl Mapping Rules (MVP)

* Titles containing `submission`, `deadline`, `due` → calendar events with endAt.
* `judging`, `criteria`, `prize`, `rules` → create **compliance tasks**.
* Social callouts: `@tan_stack`, `@convex_dev`, etc. → **social tasks**.
* Detected dates → normalized to ISO with source timezone; store `url` for provenance.

Fallbacks:

* If no dates found → create generic tasks + **one** calendar event for submission date the user inputs manually (inline prompt).

---

## 11) UX Flows (text)

**Import**

1. Paste URL → pass Turnstile → click **Import**.
2. Streaming log shows: “Fetching… Extracting… Found 3 dates… Generating tasks…”.
3. Preview lists proposed tasks/events with checkboxes; user can deselect.
4. Click **Create Plan** → Kanban + Calendar populate.

**PR Gating**

1. Add `prUrl` to a task (or pick from `/dev`).
2. Task shows chip: “CodeRabbit: Reviewing…”.
3. On webhook with approval, chip → “Approved”, task becomes completable.

**AI Summarizer (Autumn)**

1. Click “Summarize rules” → modal shows credit cost 1.
2. On confirm, consume credit → create 5 “compliance” tasks.

---

## 12) Functional Requirements (acceptance‑testable)

* **FR‑1**: Pasting a valid public event URL and pressing **Import** must create **≥10** tasks and **≥2** events or show an actionable empty state if extraction is insufficient.
* **FR‑2**: Import progress must appear via **streamed** logs with at least 5 steps.
* **FR‑3**: Tasks move between columns and reflect across two browser sessions in **≤300ms**.
* **FR‑4**: Adding a `prUrl` to a task must lock “Mark Done” until **CodeRabbit Approved** is received.
* **FR‑5**: Public read‑only share link must render Dashboard + Tasks + Calendar without auth.
* **FR‑6**: Downloadable **ICS** feed must include all events with correct times (PT or provided tz).
* **FR‑7**: AI Summarizer must decrement Autumn credits and fail gracefully when out of credits.
* **FR‑8**: Turnstile must be validated server‑side; failing validation blocks import.
* **FR‑9**: Sentry must capture an error if Firecrawl returns non‑200 or JSON parse fails.

---

## 13) Non‑Functional Requirements

* **Performance**: TTFB for `/import` route **<300ms** (cached shell) + streamed chunks thereafter.
* **Reliability**: If Firecrawl fails, user sees a friendly retry with logged steps.
* **Security**: Rate‑limit imports (IP + workspace). No secrets in client logs.
* **Accessibility**: Keyboard actions for add/move; focus-visible; contrast AA.
* **Privacy**: Public share is **explicit** and revocable; default is private.

---

## 14) Sponsor Integration Matrix (with acceptance criteria)

| Sponsor        | Integration                                                                  | Acceptance Criteria                                                                 |
| -------------- | ---------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| TanStack Start | Full‑doc SSR + **streaming** logs for import; server functions for RPC.      | Demo shows chunked messages appearing during import; no full‑page spinner.          |
| Convex         | Reactive DB for tasks, events, comments, presence; actions for webhooks.     | Two tabs show real‑time task move & comments; presence dots update.                 |
| Netlify        | Host app + Deploy Previews; env config.                                      | Published URL + at least one Deploy Preview link in demo.                           |
| Firecrawl      | Extract page sections → map to tasks/events.                                 | Import a Luma page and show seeded plan; logs show “Found judges/prizes/deadlines”. |
| Sentry         | Error + Performance instrumentation.                                         | Show Sentry trace of an import + one captured error (forced).                       |
| Autumn         | Credit‑metered AI summarizer.                                                | Credits go down when used; 0 credits blocks the action with CTA.                    |
| Cloudflare     | **Turnstile** on import form (required); optional Workers AI classification. | Failing Turnstile prevents import; success path logged.                             |
| CodeRabbit     | PR review status gates task completion.                                      | Task is locked until CodeRabbit “Approved”; then becomes completable within 10s.    |

---

## 15) Test Plan (MVP)

* **Unit**: mapping utilities (date detection, section classification), ICS generator.
* **Integration**: Import start → Firecrawl mock → Convex writes → stream emits logs.
* **Webhook**: Simulate GitHub event with CodeRabbit check run (pending → approved).
* **E2E (two browsers)**: drag task in A reflects in B ≤300ms.
* **A11y**: Keyboard: `n` new task, `Enter` edit, `Esc` close.
* **Perf**: Largest route `import` emits first chunk ≤1s on a warm run.

---

## 16) Risks & Mitigations

* **Unreliable extraction** → Provide editable preview + manual “Add deadline”.
* **GitHub/CodeRabbit webhook complexity** → Start with polling PR checks; add webhook if time remains.
* **Time crunch** → Defer Workers AI/R2; ship Turnstile + basic mapping + PR gating first.
* **Timezone mistakes** → Normalize all dates to ISO; show source timezone + PT.

---

## 17) Build Milestones (date‑bound to hackathon)

* **Nov 9**: Convex schema; `/import` shell; Sentry; Turnstile; basic Kanban.
* **Nov 10–11**: Firecrawl import end‑to‑end with streaming logs + preview → seed DB.
* **Nov 12**: Presence, comments, real‑time drag‑drop; ICS feed.
* **Nov 13**: PR gating (polling) + `/dev` PR list; CodeRabbit status chip.
* **Nov 14**: Autumn credits + AI summarizer (rules → 5 tasks).
* **Nov 15**: Public share pages + Sponsor Usage checklist.
* **Nov 16**: Polish, perf pass, record **90‑sec demo**; Netlify deploy; Vibe Apps metadata.
* **Nov 17 (by 12:00 PM PT)**: Submit + social posts.

---

## 18) Launch Checklist (Hackathon compliance)

* [ ] Built with **TanStack Start** + **Convex** (code refs in README).
* [ ] Uses **Netlify** hosting (public URL).
* [ ] **Firecrawl** import in demo.
* [ ] **Sentry** dashboard visible with at least 1 trace & 1 error.
* [ ] **Autumn** credits used by AI summarizer.
* [ ] **Cloudflare Turnstile** enforced.
* [ ] **CodeRabbit** PR gating shown.
* [ ] Submit to **Vibe Apps** with `tanstackstart` tag + video demo (≤2 min).
* [ ] Social share on X/LinkedIn with @handles: `@tan_stack`, `@convex_dev`, `@coderabbitai`, `@firecrawl_dev`, `@netlify`, `@autumnpricing`, `@Cloudflare`, `@getsentry`.

---

## 19) Acceptance Examples (concrete)

* Import the **TanStack Start Hackathon** page → create events:

  * “Submissions due” → **Nov 17, 2025, 12:00 PM PT**
  * “Judging window” → **Nov 17–24, 2025**
* Create tasks:

  * “Instrument Sentry (FE + server)”
  * “Add CodeRabbit PR gate for core feature”
  * “Post social update with @handles”
  * “Record demo video & upload to Vibe Apps”
  * “Add Turnstile to import form”
* Calendar shows them; ICS exports correctly; PR gating works end‑to‑end.

---

## 20) Demo Script (90 seconds)

1. Paste event URL on **/import** → pass Turnstile → click **Import**. Streaming logs appear (“Fetching… Extracting… Found deadlines…”).
2. Click **Create Plan** → switch to **/tasks**; Kanban fills. Open second tab to show **live updates**.
3. Go to **/dev**; link a task to a PR → chip shows “CodeRabbit: Reviewing…”, then “Approved”; task unlocks and is completed.
4. Open **/calendar**; click **Subscribe (ICS)**.
5. Click **Summarize rules** → Autumn credits decrement → 5 tasks added.
6. Show **Sentry** trace & one captured error.
7. Visit **/sponsors** page to show the usage checklist; copy **public share link**.

---

## 21) Implementation Notes (quick pointers)

* **Streaming**: Use TanStack Start loaders/actions with streamed responses for import logs (SSE or chunked render).
* **Realtime**: Convex live queries for tasks, comments, presence; optimistic updates on drag.
* **PR status**: If CodeRabbit API hookup is heavy, poll GitHub Checks API for a `coderabbit` check run status; map to `pending / changes_requested / approved`.
* **Timezone**: Store UTC with `sourceTz` metadata; render with user’s tz; show PT for hackathon dates.
* **ICS**: Generate on the server; cache for 60s; ETag by workspace updatedAt.

---

## 22) Future (post‑hack)

* Multi‑event aggregation across a season; templates; scoring matrix; Slack/Discord bots; mobile PWA.

---



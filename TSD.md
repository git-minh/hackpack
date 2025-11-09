Below is a **technical specification** for your hackathon app (codename **HackPack**) aligned with your existing todo/contacts/tasks foundation and the TanStack Start + sponsor requirements.

---

# Technical Spec — HackPack (Event‑to‑Workspace Planner)

**Purpose**
Turn any public event page (e.g., Luma/Devpost/blog post) into a collaborative **workspace** with seeded **tasks** and **calendar events**. Showcase TanStack Start streaming, Convex real‑time sync, Firecrawl extraction, CodeRabbit‑gated task completion, Sentry observability, Autumn credit‑metered AI helpers, Netlify hosting, and Cloudflare Turnstile protection.

**Key decisions (MVP)**

* **Auth-lite**: No third‑party auth to keep scope tight. Workspaces are private by default; collaboration uses **signed invite links** (JWT) for Editor access. Public **read‑only** links use a separate signed token.
* **PR gating**: Use **GitHub webhooks** (and/or polling) to consume CodeRabbit check statuses. Users paste a PR URL into a task; no OAuth required.
* **Streaming UX**: The `/import` route streams logs during extraction using TanStack Start server functions + SSE/ReadableStream.
* **AI credits**: Only one AI feature (rule→task summarizer) is metered via Autumn.

---

## 1) Architecture

```
Client (React + TanStack Start)
 ├─ Start Router (full-doc SSR + streaming)
 ├─ UI (Tasks, Calendar, Import, Dev, Settings, Share)
 ├─ Sentry SDK
 └─ Cloudflare Turnstile widget
        │
        ▼
Start Server Functions (Vite/TS) on Netlify
 ├─ /api/import.start      (POST)  -> validate Turnstile, enqueue Convex action
 ├─ /api/import.stream     (GET)   -> SSE/ReadableStream progress logs
 ├─ /calendar/:ws.ics      (GET)   -> ICS feed generation
 ├─ /webhooks/github       (POST)  -> verify HMAC, update task.prStatus
 ├─ /api/ai/summarize      (POST)  -> Autumn credit check + summarization
 ├─ /api/invite.exchange   (POST)  -> JWT -> session cookie for workspace
 └─ /api/turnstile.verify  (POST)  -> server-side Turnstile verification
        │
        ▼
Convex (Reactive DB: actions/queries)
 ├─ Data: users, workspaces, memberships, imports, tasks, events, comments, presence, billing
 ├─ Live queries for tasks/events/comments/presence
 └─ Actions for Firecrawl mapping, webhook handling, billing accounting
        │
        ├────────► Firecrawl API (extract content)
        ├────────► Cloudflare Turnstile verify API
        ├────────► Autumn API (credits)
        └────────► GitHub Webhooks (ingress only / optional Checks polling)

Hosting/Infra
- Netlify (build/deploy, env secrets, edge/CDN)
- Sentry (frontend+server perf & errors)
- (Optional) Cloudflare Workers AI or R2 for stretch goals
```

---

## 2) Tech Stack

* **Framework**: TanStack Start (React), TanStack Router
* **Language**: TypeScript strict
* **Build**: Vite
* **DB/Realtime**: Convex (actions/mutations/live queries)
* **UI**: Headless primitives + dnd-kit for Kanban
* **Validation**: zod
* **Date/tz**: date-fns-tz (normalize to UTC; store `sourceTz`)
* **Telemetry**: Sentry (browser + server)
* **Security**: Cloudflare Turnstile; HMAC for GitHub webhook; JWT for invites
* **Deployment**: Netlify (Deploy Previews enabled)

---

## 3) Data Model (Convex)

**Collections & Indexes**

```ts
// users
{
  _id: Id<'users'>,
  displayName: string,
  avatarUrl?: string
}
// workspaces
{
  _id: Id<'workspaces'>,
  name: string,
  slug: string,             // unique
  ownerId: Id<'users'>,
  createdAt: number         // epoch ms
}
// memberships
{
  _id: Id<'memberships'>,
  workspaceId: Id<'workspaces'>,
  userId: Id<'users'>,
  role: 'owner'|'editor'|'viewer'
}
index('byWorkspaceUser', ['workspaceId', 'userId'])

// imports
{
  _id: Id<'imports'>,
  workspaceId: Id<'workspaces'>,
  url: string,
  status: 'queued'|'running'|'done'|'error',
  logs: {ts:number, level:'info'|'warn'|'error', msg:string}[],
  startedAt?: number,
  finishedAt?: number,
  raw?: unknown,        // Firecrawl raw payload (capped/truncated)
  mapped?: {
    events: ImportedEvent[],
    tasks: ImportedTask[]
  }
}
index('byWorkspace', ['workspaceId'])

// events (calendar)
{
  _id: Id<'events'>,
  workspaceId: Id<'workspaces'>,
  title: string,
  startAt: number,     // epoch ms (UTC)
  endAt: number,       // epoch ms (UTC)
  source: 'import'|'manual',
  url?: string,
  sourceTz?: string
}
index('byWorkspaceStart', ['workspaceId', 'startAt'])

// tasks
{
  _id: Id<'tasks'>,
  workspaceId: Id<'workspaces'>,
  title: string,
  status: 'backlog'|'in_progress'|'blocked'|'done',
  dueAt?: number,        // epoch ms UTC
  assigneeId?: Id<'users'>,
  labels: string[],
  sourceId?: Id<'imports'>,
  prUrl?: string,
  prStatus?: 'pending'|'changes_requested'|'approved',
  order: number          // Kanban stable order
}
index('byWorkspaceStatusOrder', ['workspaceId','status','order'])
index('byWorkspaceDue', ['workspaceId','dueAt'])

// comments
{
  _id: Id<'comments'>,
  taskId: Id<'tasks'>,
  authorId: Id<'users'>,
  body: string,
  createdAt: number
}
index('byTask', ['taskId','createdAt'])

// presence
{
  _id: Id<'presence'>,
  workspaceId: Id<'workspaces'>,
  userId: Id<'users'>,
  lastSeenAt: number,
  cursor?: {x:number,y:number}  // optional
}
index('byWorkspaceUser', ['workspaceId','userId'])

// billing (Autumn)
{
  _id: Id<'billing'>,
  workspaceId: Id<'workspaces'>,
  credits: number,               // integer
  provider: 'autumn',
  updatedAt: number
}
index('byWorkspace', ['workspaceId'])
```

**Type helpers**

```ts
type ImportedEvent = { title: string; startAt: number; endAt: number; url?: string; sourceTz?: string };
type ImportedTask  = { title: string; labels?: string[]; dueAt?: number };
```

---

## 4) Routes & Loaders (TanStack Start)

### Route map

```
/                    Dashboard (deadlines, activity)
/import              Paste URL → streamed extraction → preview → "Create Plan"
/tasks               Kanban board (Backlog, In Progress, Blocked, Done)
/tasks/:taskId       Task detail (comments, presence, PR status)
/calendar            Calendar (week/month)
/dev                 PR list + CodeRabbit status chips
/settings            Tokens (Firecrawl, Autumn), Sentry health, Turnstile test
/share/:slug         Public read-only view (dashboard + tasks + calendar)
/sponsors            Sponsor Usage checklist (auto-generated)
```

### Loader/action signatures (TypeScript)

```ts
// /import (server action)
export async function action_importStart({ request }: { request: Request }) {
  const { url, turnstileToken, workspaceId } = await request.json();
  await verifyTurnstile(turnstileToken);                 // throws on failure
  const importId = await convex.mutation('imports/start', { url, workspaceId });
  // kick off background Convex action that calls Firecrawl; streaming handled separately
  return json({ importId });
}

// /import.stream (SSE)
export async function loader_importStream({ request }: { request: Request }) {
  const importId = new URL(request.url).searchParams.get('importId')!;
  const encoder = new TextEncoder();
  const stream = new ReadableStream({
    start(controller) {
      const unsub = convex.watchLogs(importId, (log) => {
        controller.enqueue(encoder.encode(`data: ${JSON.stringify(log)}\n\n`));
      });
      // close when import is done
      convex.onImportDone(importId, () => {
        controller.enqueue(encoder.encode('event: done\ndata: {}\n\n'));
        unsub(); controller.close();
      });
    }
  });
  return new Response(stream, {
    headers: { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache' }
  });
}
```

> Client subscribes with `EventSource` and progressively renders a terminal‑style log and preview list as partial results arrive.

---

## 5) Convex actions/queries (contract)

```ts
// imports/start
input: { url: string; workspaceId: Id<'workspaces'> }
effect:
  - create imports doc (status=queued)
  - enqueue action 'imports/run'

// imports/run (action)
input: { importId: Id<'imports'> }
effect:
  - set status=running, appendLog('Fetching URL ...')
  - call FirecrawlAdapter.extract(url)
  - appendLog('Parsing sections ...')
  - const mapped = Mapping.mapToTasksAndEvents(raw)
  - update imports.mapped = mapped
  - append partial preview events/tasks via appendLog({type:'preview',mappedPartial})
  - on confirm (client action 'imports/commit'), create events & tasks in bulk

// imports/commit
input: { importId, selections: {eventIds: number[], taskIds: number[]} }
effect:
  - write events/tasks into collections (atomic)
  - set status=done

// tasks/upsert, tasks/reorder, tasks/setStatus, tasks/linkPR, tasks/setAssignee
// events/listInRange (live query)
// presence/heartbeat (mutates presence), presence/list (live query)
// comments/create (mutation), comments/listByTask (live query)
// billing/getBalance (query), billing/consume (mutation)

// webhooks/github (server function calls convex.action 'dev/ingestWebhook')
```

---

## 6) External integrations

### 6.1 Firecrawl Adapter

**Normalization interface**

```ts
type FirecrawlSection = { heading?: string; text: string; hrefs?: string[]; datetimeHints?: string[] };
type FirecrawlResult  = { url: string; title?: string; sections: FirecrawlSection[] };

interface IFirecrawlAdapter {
  extract(url: string): Promise<FirecrawlResult>;
}
```

**Mapping heuristics (MVP)**

* Sections whose `heading|text` matches `/submission|deadline|due/i` → `ImportedEvent` with `endAt`.
* Ranges like `Nov 17–24` → create two events or one event with range (prefer **two** to make reminders easier).
* Matches `/rules|criteria|judging|prize|credits|sponsors/i` → create **compliance tasks**.
* Matches Twitter/X/LinkedIn handles (e.g., `@tan_stack`) → **social tasks**.
* Datetime extraction:

  * Parse with date-fns; if timezone strings present (e.g., `PT`, `GMT+7`) capture `sourceTz`; otherwise default to `America/Los_Angeles` for hackathon pages; always store UTC timestamps.

**Partial preview streaming**
While mapping, emit `appendLog({ type:'preview', items:[...], progress:0.4 })` so the UI can render checkboxes early.

### 6.2 Cloudflare Turnstile

* Client embeds Turnstile widget; server verifies:

```ts
async function verifyTurnstile(token: string) {
  const resp = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', {
    method: 'POST',
    body: new URLSearchParams({ secret: CF_TURNSTILE_SECRET, response: token })
  });
  const data = await resp.json();
  if (!data.success) throw new Error('turnstile_failed');
}
```

### 6.3 GitHub + CodeRabbit

* **Webhook endpoint**: `POST /webhooks/github`
* **Events**: `check_run`, `pull_request` (optional), `status`
* **Verification**: `X-Hub-Signature-256` HMAC SHA256 with `GITHUB_WEBHOOK_SECRET`.
* **Mapping**:

  * Identify CodeRabbit by `check_run.app.name === 'CodeRabbit'` (or `name` contains `CodeRabbit`).
  * Extract PR URL (`check_run.check_suite.pull_requests[0].html_url`).
  * Update all tasks in workspace where `tasks.prUrl === PR_URL`:

    * status: `pending` | `changes_requested` | `approved` (map from GitHub conclusion/status).
    * When `approved`, allow completion UI.

**Fallback**: A polling task can GET the Checks API for the pasted PR URL every 10s (only for demo if webhooks unavailable).

### 6.4 Autumn (credits)

* **Server guard** on AI summarizer route:

  1. `billing/getBalance`
  2. If `credits >= 1`, call `billing/consume(1)` in a transaction
  3. Perform summarization (model can be Workers AI/OpenAI‑compatible—you’ll plug in what’s available), return generated task list.

* Minimal UI: a meter with remaining credits and CTA to “Add credits” (link to Autumn‑hosted checkout or a mocked “grant credits” button for demo if needed).

### 6.5 Sentry

* Initialize in both client and server; capture:

  * Route transition spans (client)
  * `/api/import.start` span with child spans for Firecrawl call, mapping, DB writes (server)
  * Force one error path in demo (e.g., invalid URL) to show captured issue.

### 6.6 Netlify

* **Build command**: `pnpm build`
* **Publish**: `dist/`
* **Functions**: Netlify Functions/Edge Functions for server endpoints
* **Env**: Use Netlify UI to inject secrets (see §13)

---

## 7) Frontend UI/UX (components & states)

**Import page**

* Components: `UrlInput`, `TurnstileBlock`, `LogStream`, `PreviewList`, `CreatePlanButton`
* States: `idle` → `verifying` → `running` (stream logs) → `preview` (checkboxes) → `committing` → `done`
* Errors: `turnstile_failed`, `fetch_error`, `mapping_error` (toast + Sentry capture)

**Kanban**

* `Board` (columns from `status`), `Card` (task), `AssigneeChip`, `PRStatusChip`
* Drag & drop with **optimistic** reorder; persist `order` per status lane

**Task detail**

* Tabs: Details / Comments / Activity
* “Mark done” disabled if `prUrl` present and `prStatus !== 'approved'`
* Presence cursors shown when others on same task

**Calendar**

* Simple week/month; event click → jump to related tasks if any
* “Subscribe” button → downloads `workspace.ics` link

**Dev page**

* PR list (optional if webhook-only); field to paste PR URL; attach to selected task; show CodeRabbit status chip

**Share**

* Toggle “Public read-only link” → generates `/share/:slug` (JWT without write perms)

**Sponsors**

* Checkboxes auto-filled from detection of used features; links to specific places in app

---

## 8) ICS feed

**Endpoint**: `GET /calendar/:workspaceId.ics`
**Implementation**: Build `.ics` string with CRLF and UTC times; `UID` = `${eventId}@hackpack`.

```ics
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//HackPack//EN
CALSCALE:GREGORIAN
METHOD:PUBLISH
BEGIN:VEVENT
UID:evt_123@hackpack
DTSTAMP:20251109T120000Z
DTSTART:20251117T200000Z
DTEND:20251117T210000Z
SUMMARY:Submissions due
URL:https://...
END:VEVENT
END:VCALENDAR
```

Cache for 60s; set `ETag` based on workspace `updatedAt`.

---

## 9) Security model

* **Access control**:

  * Private workspace by default.
  * **Editor invite**: JWT (`role=editor`, `workspaceId`, `exp`) exchanged for an httpOnly session cookie bound to workspace.
  * **Public share**: JWT (`role=viewer`) passed via URL; renders server-side read-only UI; **never** sets write session.

* **Webhook verification**: HMAC SHA256; reject if signature mismatch; constant-time compare.

* **Input validation**: All server endpoints validate with zod.

* **Rate limiting**:

  * `/api/import.start` 5/min per IP + per workspace (simple in‑memory + Convex counter).
  * Turnstile required to reach start endpoint.

* **Secrets**: Only on server; never logged; redact in Sentry.

* **CSP** (Netlify headers):

  * `default-src 'self'`
  * `connect-src 'self' https://api.sentry.io https://*.convex.cloud`
  * `img-src 'self' data: https:`
  * plus Turnstile frame allowances.

---

## 10) Performance

* **Streaming first chunk** on `/import` within 1s (warm start).
* **Code-splitting** by route; hydrate only interactive parts (Kanban).
* **Optimistic UI** for drag & drop; reconcile on ack.
* **Convex live queries** minimized with lean projections (select only fields used).
* **Memoized Kanban lists** keyed by `status` to avoid re-render storms.

---

## 11) Error handling

* **Categorized errors** (`turnstile_failed`, `firecrawl_unreachable`, `mapping_failed`, `webhook_invalid`, `billing_insufficient_credits`).
* Surface friendly messages; log errors to Sentry with context (workspaceId, importId, but no PII).

---

## 12) Testing Strategy

* **Unit**:

  * Mapping utils (date/range parsing; handle `Nov 17–24` and `18:55 GMT+7`).
  * ICS generator (golden file compare).
  * JWT invite encode/decode/exp.

* **Integration**:

  * Import flow: mock Firecrawl adapter; assert preview items; commit writes events/tasks.
  * Webhook: send signed payload; task `prStatus` transitions.

* **E2E (Playwright)**:

  * Two browser contexts: drag card in A reflects in B ≤300ms.
  * Public share link is read-only (no POSTs succeed).
  * Turnstile failure blocks import.

* **A11y**: Axe checks; keyboard navigation on Kanban & modals.

---

## 13) Configuration & Environment Variables

| Key                     | Purpose                                              |
| ----------------------- | ---------------------------------------------------- |
| `CONVEX_URL`            | Convex deployment endpoint                           |
| `SENTRY_DSN`            | Sentry project DSN (browser + server)                |
| `FIRECRAWL_API_KEY`     | Firecrawl access token                               |
| `AUTUMN_API_KEY`        | Autumn API token                                     |
| `CF_TURNSTILE_SITE_KEY` | Client widget key                                    |
| `CF_TURNSTILE_SECRET`   | Server verification secret                           |
| `GITHUB_WEBHOOK_SECRET` | HMAC secret for GitHub webhooks                      |
| `JWT_SECRET`            | Invite token signing secret                          |
| `APP_BASE_URL`          | Public base URL (for webhook registration, ICS URLs) |

Netlify: set all as secure environment variables; never commit to repo.

---

## 14) Build & Deploy (Netlify)

* **Build cmd**: `pnpm i --frozen-lockfile && pnpm build`
* **Publish dir**: `dist/`
* **Functions**: `netlify/functions/**` (or Start’s server build target configured to Netlify)
* **Headers**: `_headers` file with CSP; `_redirects` for clean routes
* **Deploy Previews**: on PRs; link in demo to show Netlify integration

---

## 15) Telemetry & Metrics (Sentry + custom)

* **Sentry transactions**: `import.start`, `import.stream`, `mapping`, `commit`, `ai.summarize`, `webhooks.github`.
* **Custom counters** (Convex): `imports_started`, `imports_succeeded`, `imports_failed`, `ai_tasks_created`, `pr_gate_approved`.
* **Perf budgets**: p75 TTFB for `/import` < 300ms (shell), p75 stream first message < 1s.

---

## 16) Detailed Flows

### 16.1 Import & Stream (sequence)

1. Client → `/api/import.start` `{url, turnstileToken, workspaceId}`
2. Server verifies Turnstile → `imports/start` (Convex) creates doc (`running`) & enqueues `imports/run`
3. Client opens `EventSource(/api/import.stream?importId=...)`
4. `imports/run` appends logs (`Fetching…`, `Extracting…`, `Found 3 dates…`) and partial previews → server pushes SSE lines
5. User selects/deselects items → clicks **Create Plan** → `/api/import.commit` → `imports/commit` writes events/tasks
6. Stream sends `event: done` → client closes; navigates to `/tasks` & `/calendar`

### 16.2 PR Gate

1. User pastes PR URL into task
2. GitHub → (via CodeRabbit) emits `check_run` events to `/webhooks/github`
3. Server verifies signature → maps to task(s) → updates `prStatus`
4. UI updates real‑time via Convex live query; “Mark Done” unlocks when approved

### 16.3 AI Summarizer

1. Client POST `/api/ai/summarize` with `{importId}`
2. Server checks Autumn balance (`billing/getBalance`) → `billing/consume(1)`
3. Run summarizer → return 5 tasks → create tasks via Convex mutation

---

## 17) Example Contracts (zod)

```ts
const ImportStartInput = z.object({
  url: z.string().url(),
  turnstileToken: z.string().min(5),
  workspaceId: z.string()
});

const ImportedEventZ = z.object({
  title: z.string().min(2),
  startAt: z.number().int(),
  endAt: z.number().int(),
  url: z.string().url().optional(),
  sourceTz: z.string().optional()
});

const ImportedTaskZ = z.object({
  title: z.string().min(2),
  dueAt: z.number().int().optional(),
  labels: z.array(z.string()).max(8).optional()
});
```

---

## 18) Kanban Ordering

* Each column (`status`) has independent `order` sequence.
* Reorder algorithm:

  * On drag, compute new `order` using fractional indexing (midpoint between neighbors) to avoid re‑numbering storms.
  * Persist via `tasks/reorder` mutation; broadcast with live query.

---

## 19) Definition of Done (MVP)

* Import flow streams and produces **≥10 tasks** and **≥2 events** from the TanStack Hackathon Luma page.
* Two browsers show live Kanban updates and presence.
* PR gating works (manually trigger CodeRabbit approve on demo repo PR).
* ICS calendar subscribes in Google Calendar/Apple Calendar.
* AI summarizer creates 5 compliance tasks and decrements Autumn credits.
* Turnstile blocks bot submissions.
* Sentry shows at least one trace and one captured error.
* Public read‑only share works; write operations are blocked.

---

## 20) Risk & Mitigation (implementation-level)

* **Ambiguous date parsing** → keep `sourceTz` and show explicit absolute times in UI; let user edit dates pre‑commit.
* **Webhook delivery delays** → show “Reviewing…” with last updated time; include manual “Refresh PR status” (poll once).
* **Firecrawl page variance** → harden mapping with keyword + date proximity (look for nearest date around keyword lines).
* **Turnstile false negatives** → allow retry; backoff on repeated failures.

---

## 21) Minimal File/Folder Layout

```
/app
  /routes
    index.tsx
    import.tsx                 // form + client stream
    tasks.tsx
    tasks.$taskId.tsx
    calendar.tsx
    dev.tsx
    settings.tsx
    share.$slug.tsx
    sponsors.tsx
  /server
    api.import.start.ts
    api.import.stream.ts
    api.import.commit.ts
    api.ai.summarize.ts
    api.invite.exchange.ts
    calendar.ics.ts
    webhooks.github.ts
    sentry.server.ts
    turnstile.verify.ts
  /components
    LogStream.tsx
    KanbanBoard.tsx
    TaskCard.tsx
    CalendarView.tsx
    PresenceAvatars.tsx
  /lib
    firecrawlAdapter.ts
    mapping.ts
    ics.ts
    jwt.ts
    validators.ts
    github.ts
    autumn.ts
    convexClient.ts
/convex
  schema.ts
  imports.ts
  tasks.ts
  events.ts
  presence.ts
  comments.ts
  billing.ts
netlify.toml
```

---

## 22) Netlify Config (snippet)

```toml
# netlify.toml
[build]
  command = "pnpm i --frozen-lockfile && pnpm build"
  publish = "dist"

[[headers]]
  for = "/*"
  [headers.values]
  Content-Security-Policy = "default-src 'self'; img-src 'self' data: https:; connect-src 'self' https://api.sentry.io https://*.convex.cloud; frame-src https://challenges.cloudflare.com; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'"

[[redirects]]
  from = "/api/*"
  to = "/.netlify/functions/:splat"
  status = 200
```

---

## 23) Demo Script Hooks (code cues)

* In `/import`, show the **first streamed log** within 1s:

  * `appendLog('Fetching …')`, `appendLog('Extracting …')`, `appendLog('Found 3 deadlines')`, `appendLog('Found judges & prizes')`, `appendLog('Generating 12 tasks and 3 events')`.

* In `/dev`, a task with `prUrl` shows `<PRStatusChip status="pending" />` → updates to `"approved"` when webhook arrives.

* In `/sponsors`, automatically tick items when corresponding code paths (Sentry init, Turnstile verify, Convex live query, etc.) have run at least once in the current session.


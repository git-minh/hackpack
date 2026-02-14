# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Task Master AI Instructions
**Import Task Master's development workflow commands and guidelines, treat as if import is in the main CLAUDE.md file.**
@./.taskmaster/CLAUDE.md

## Project Overview

HackPack is an **Event-to-Workspace Planner** built for the TanStack Start Hackathon. It transforms any hackathon/conference page into a collaborative workspace with auto-generated tasks and calendar events using AI extraction and real-time collaboration features.

**Hackathon submission deadline**: Monday, November 17, 2025, 12:00 PM PT

## Core Architecture

### Tech Stack
- **Framework**: TanStack Start (React) with TanStack Router v2 for file-based routing
- **Language**: TypeScript (strict mode)
- **Build**: Vite + Nitro v2 (server preset)
- **Database**: Convex (reactive DB with actions/mutations/live queries)
- **Styling**: Tailwind CSS (configured with @tailwindcss/vite plugin)
- **Deployment**: Netlify (with Deploy Previews)
- **Server**: Nitro v2 preset configured in `vite.config.ts`

### Key Sponsor Integrations (Required for Hackathon)
1. **TanStack Start** - Full-doc SSR + streaming logs for import
2. **Convex** - Reactive DB for tasks, events, comments, presence
3. **Netlify** - Hosting + Deploy Previews + env config
4. **Firecrawl** - Extract event pages → map to tasks/events
5. **Sentry** - Error + Performance instrumentation
6. **Autumn** - Credit-metered AI summarizer
7. **Cloudflare Turnstile** - Import form protection
8. **CodeRabbit** - PR review status gates task completion

## Common Development Commands

```bash
# Development
npm run dev              # Start dev server with Vinxi
npm run routes:watch     # Watch and regenerate route tree (run alongside dev)

# Build & Deploy
npm run build           # Production build
npm run start           # Start production server
npm run preview         # Preview production build

# Type Safety & Routes
npm run typecheck       # TypeScript type checking (no emit)
npm run routes          # Generate route tree once

# Task Master (see @./.taskmaster/CLAUDE.md for full list)
task-master list        # View all tasks
task-master next        # Get next available task
task-master show <id>   # View task details
```

## Route Architecture

### Route Generation
- Routes are **file-based** in `src/routes/`
- Route tree is **auto-generated** at `src/routeTree.gen.ts` via TanStack Router CLI
- **NEVER** manually edit `src/routeTree.gen.ts`
- Run `npm run routes` after creating/modifying route files
- Use `npm run routes:watch` during development for automatic regeneration
- Configuration in `tsr.config.json` points to `./src/routes` directory

### Implemented Route Structure (per TSD.md)
```
/                         Dashboard (deadlines, activity)           -> src/routes/index.tsx
/import                   Paste URL → streaming extraction           -> src/routes/import.tsx
/tasks                    Kanban board                              -> src/routes/tasks.tsx
/tasks/:taskId            Task detail (comments, presence)          -> src/routes/tasks.$taskId.tsx
/calendar                 Calendar (week/month)                      -> src/routes/calendar.tsx
/dev                      GitHub PRs + CodeRabbit status chips       -> src/routes/dev.tsx
/settings                 Tokens, Sentry health, Turnstile test      -> src/routes/settings.tsx
/share/:slug              Public read-only view                      -> src/routes/share.$slug.tsx
/sponsors                 Sponsor Usage checklist                    -> src/routes/sponsors.tsx
```

### Route File Patterns (TanStack Router v2)
- `__root.tsx` - Root layout for all routes (src/routes/__root.tsx)
- `index.tsx` - Home/dashboard route (src/routes/index.tsx)
- `import.tsx` - Import flow page (src/routes/import.tsx)
- `tasks.tsx` - Tasks list page (src/routes/tasks.tsx)
- `tasks.$taskId.tsx` - Dynamic task detail page with :taskId param
- `share.$slug.tsx` - Dynamic public share page with :slug param

## Data Architecture (Convex)

### Core Collections
```typescript
users:        { _id, displayName, avatarUrl? }
workspaces:   { _id, name, slug (unique), ownerId, createdAt }
memberships:  { _id, workspaceId, userId, role: 'owner'|'editor'|'viewer' }
imports:      { _id, workspaceId, url, status, logs, startedAt, finishedAt, raw?, mapped? }
events:       { _id, workspaceId, title, startAt, endAt, source, url?, sourceTz? }
tasks:        { _id, workspaceId, title, status, dueAt?, assigneeId?, labels, sourceId?, prUrl?, prStatus?, order }
comments:     { _id, taskId, authorId, body, createdAt }
presence:     { _id, workspaceId, userId, lastSeenAt, cursor? }
billing:      { _id, workspaceId, credits, provider: 'autumn', updatedAt }
```

### Task Statuses
- `backlog` - Ready to work on
- `in_progress` - Currently being worked on
- `blocked` - Waiting on external factors (e.g., PR approval)
- `done` - Completed

### PR Status Flow
- `pending` - CodeRabbit reviewing
- `changes_requested` - Changes needed
- `approved` - Ready to complete task

## Server Functions & API Routes

### Server Functions Architecture
- **Server Preset**: Nitro v2 (configured in `vite.config.ts`)
- **Location**: `src/server/` directory
- **Handler Pattern**: Use `defineEventHandler` from Nitro/h3
- **APIs**: `readBody`, `getQuery`, `setResponseHeader`, `sendStream` from h3

### Implemented Server Endpoints (per TSD.md)
```
POST /api/import/start           # src/server/api/import/start.ts
GET  /api/import/stream          # src/server/api/import/stream.ts (SSE)
POST /api/import/commit          # src/server/api/import/commit.ts
POST /api/ai/summarize           # src/server/api/ai/summarize.ts
POST /api/invite/exchange        # src/server/api/invite.exchange.ts
GET  /calendar/:ws.ics           # src/server/calendar/[ws].ics.ts
POST /webhooks/github            # src/server/webhooks/github.ts
POST /api/turnstile/verify       # src/server/api/turnstile.verify.ts
```

### Server Function Example
```ts
// src/server/api/example.ts
export default defineEventHandler(async (event) => {
  const body = await readBody(event);  // POST body
  const query = getQuery(event);       // URL query params

  // Process request...

  return { success: true };
});
```

## Key Implementation Patterns

### Streaming UX
- Import flow uses **streaming** to show progressive extraction logs
- NO full-page spinners - use SSE or ReadableStream for chunked updates
- First chunk must appear within 1s (warm start)

### Real-time Collaboration
- Use Convex **live queries** for tasks, events, comments, presence
- **Optimistic updates** for drag-and-drop Kanban
- Cross-tab updates should reflect in <300ms

### PR Gating
- Tasks with `prUrl` lock "Mark Done" until `prStatus === 'approved'`
- GitHub webhook at `/webhooks/github` receives CodeRabbit check_run events
- Verify webhook with HMAC SHA256 using `X-Hub-Signature-256` header
- Fallback: poll GitHub Checks API if webhooks unavailable

### Security
- **Turnstile** required on import form (server-side verification)
- **JWT** for workspace invites (Editor) and public shares (Viewer)
- **HMAC** verification for GitHub webhooks
- **Rate limiting** on import endpoint (5/min per IP + workspace)
- **Input validation** with zod on all server endpoints

### Date/Timezone Handling
- Store all times as **UTC timestamps** (epoch ms)
- Capture `sourceTz` during extraction (default to `America/Los_Angeles` for hackathon pages)
- Render with user's timezone, show PT for hackathon deadlines

## Environment Variables (Netlify)

```
CONVEX_URL                # Convex deployment endpoint
SENTRY_DSN                # Sentry project DSN (browser + server)
FIRECRAWL_API_KEY         # Firecrawl access token
AUTUMN_API_KEY            # Autumn API token
CF_TURNSTILE_SITE_KEY     # Client widget key
CF_TURNSTILE_SECRET       # Server verification secret
GITHUB_WEBHOOK_SECRET     # HMAC secret for GitHub webhooks
JWT_SECRET                # Invite token signing secret
APP_BASE_URL              # Public base URL
```

**NEVER** commit secrets to repo. Use Netlify UI to set environment variables.

## Firecrawl Mapping Rules

### Auto-detection Heuristics
- Headings/text matching `/submission|deadline|due/i` → calendar events with `endAt`
- Matches `/rules|criteria|judging|prize|credits|sponsors/i` → compliance tasks
- Social handles (`@tan_stack`, `@convex_dev`, etc.) → social tasks
- Date ranges like `Nov 17–24` → create two events or one with range

### Streaming Preview
- Emit partial results during mapping via `appendLog({ type:'preview', items, progress })`
- User can select/deselect items before committing

## Testing Requirements

### MVP Acceptance Criteria
- Import TanStack Hackathon page → create **≥10 tasks** and **≥2 events** in ≤60s
- Streaming shows ≥5 progressive log steps
- Two browser tabs reflect task moves in ≤300ms
- PR gating locks/unlocks task within 10s of CodeRabbit approval
- ICS feed works in Google Calendar/Apple Calendar
- AI summarizer creates 5 tasks and decrements Autumn credits
- Turnstile blocks invalid submissions
- Sentry captures ≥1 trace and ≥1 error

### Test Types
- **Unit**: Date parsing, ICS generation, JWT encode/decode
- **Integration**: Import flow with mocked Firecrawl, webhook handling
- **E2E**: Two-browser real-time updates, public share read-only enforcement
- **A11y**: Keyboard navigation (n=new, Enter=edit, Esc=close)

## Performance Budgets

- TTFB for `/import` route: <300ms (cached shell)
- Stream first chunk: ≤1s
- Kanban drag-drop perceived latency: <300ms
- Code-split by route; hydrate only interactive parts

## File Organization

```
/src
  /routes/              # TanStack Router v2 file-based routes
    __root.tsx          # Root layout
    index.tsx           # Dashboard
    import.tsx          # Import flow
    tasks.tsx           # Kanban board
    tasks.$taskId.tsx   # Task detail
    calendar.tsx        # Calendar view
    dev.tsx             # Dev/PR tools
    settings.tsx        # Settings
    share.$slug.tsx     # Public share
    sponsors.tsx        # Sponsor checklist
  /server/              # Nitro v2 server functions
    /api/               # API endpoints
      /import/          # Import endpoints
        start.ts        # POST /api/import/start
        stream.ts       # GET /api/import/stream
        commit.ts       # POST /api/import/commit
      /ai/
        summarize.ts    # POST /api/ai/summarize
      invite.exchange.ts
      turnstile.verify.ts
    /calendar/
      [ws].ics.ts       # GET /calendar/:ws.ics
    /webhooks/
      github.ts         # POST /webhooks/github
  /components/          # React components
    Layout.tsx          # App layout wrapper
    LogStream.tsx       # Streaming log display
    KanbanBoard.tsx     # Kanban component
    TaskCard.tsx        # Task card
    CalendarView.tsx    # Calendar component
    PresenceAvatars.tsx # Presence indicators
  /lib/                 # Utilities
    firecrawlAdapter.ts # Firecrawl integration
    mapping.ts          # Event→task mapping
    ics.ts              # ICS generation
    jwt.ts              # JWT helpers
    validators.ts       # Zod schemas
    github.ts           # GitHub API helpers
    autumn.ts           # Autumn billing
    convexClient.ts     # Convex client setup
    sentry.ts           # Sentry instrumentation
  client.tsx            # Client entry point
  router.tsx            # Router instance
  routeTree.gen.ts      # Auto-generated (DO NOT EDIT)

/convex                 # Convex backend
  schema.ts             # Data model
  imports.ts            # Import actions/queries
  tasks.ts              # Task mutations/queries
  events.ts             # Event queries
  presence.ts           # Presence tracking
  comments.ts           # Comments
  billing.ts            # Autumn billing logic

vite.config.ts          # Vite + Nitro v2 config
tsr.config.json         # TanStack Router config ("./src/routes")
netlify.toml            # Netlify deployment config
```

## Netlify Deployment

### Build Configuration
```toml
[build]
  command = "pnpm i --frozen-lockfile && pnpm build"
  publish = "dist"
```

### CSP Headers
```
Content-Security-Policy = "default-src 'self'; img-src 'self' data: https:; connect-src 'self' https://api.sentry.io https://*.convex.cloud; frame-src https://challenges.cloudflare.com; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'"
```

## Hackathon Submission Checklist

- [ ] Built with TanStack Start + Convex (code refs in README)
- [ ] Uses Netlify hosting (public URL)
- [ ] Firecrawl import in demo
- [ ] Sentry dashboard visible (≥1 trace, ≥1 error)
- [ ] Autumn credits used by AI summarizer
- [ ] Cloudflare Turnstile enforced
- [ ] CodeRabbit PR gating shown
- [ ] Submit to Vibe Apps with `tanstackstart` tag + video demo (≤2 min)
- [ ] Social share with @handles: `@tan_stack`, `@convex_dev`, `@coderabbitai`, `@firecrawl_dev`, `@netlify`, `@autumnpricing`, `@Cloudflare`, `@getsentry`

## Important Notes

### Route Tree Regeneration
Always run `npm run routes` after creating or modifying route files. The generated `routeTree.gen.ts` is critical for TanStack Router to work correctly.

### Convex Integration
This project requires Convex setup. If Convex is not yet initialized, you'll need to:
1. Install Convex CLI: `npm install -g convex`
2. Initialize: `npx convex dev`
3. Set `CONVEX_URL` in environment

### Development Workflow with Task Master
See `.taskmaster/CLAUDE.md` for complete Task Master integration. Use `task-master next` to get the next task to implement, and `task-master show <id>` for detailed requirements.

### Streaming Implementation
TanStack Start supports streaming via server functions returning `ReadableStream` or using SSE (Server-Sent Events). The import flow is the primary place to demonstrate this capability.

### Real-time with Convex
Use Convex live queries for automatic real-time updates. No polling needed - Convex pushes changes to all connected clients.

import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/sponsors')({
  component: SponsorsPage,
})

function SponsorsPage() {
  const sponsors = [
    {
      name: 'TanStack Start',
      integration: 'Full-doc SSR + streaming logs for import',
      file: 'app/routes/api/import.stream.ts',
      acceptance: 'Demo shows chunked messages appearing during import'
    },
    {
      name: 'Convex',
      integration: 'Reactive DB for tasks, events, comments, presence',
      file: 'convex/schema.ts',
      acceptance: 'Two tabs show real-time task move & comments'
    },
    {
      name: 'Netlify',
      integration: 'Host app + Deploy Previews',
      file: 'netlify.toml',
      acceptance: 'Published URL + Deploy Preview link in demo'
    },
    {
      name: 'Firecrawl',
      integration: 'Extract page sections → map to tasks/events',
      file: 'app/lib/firecrawl.ts',
      acceptance: 'Import shows seeded plan with extracted data'
    },
    {
      name: 'Sentry',
      integration: 'Error + Performance instrumentation',
      file: 'app/lib/sentry.server.ts',
      acceptance: 'Show Sentry trace + captured error'
    },
    {
      name: 'Autumn',
      integration: 'Credit-metered AI summarizer',
      file: 'app/lib/autumn.ts',
      acceptance: 'Credits decrement when used, blocks at 0'
    },
    {
      name: 'Cloudflare Turnstile',
      integration: 'Bot protection on import form',
      file: 'app/components/TurnstileWidget.tsx',
      acceptance: 'Failing Turnstile prevents import'
    },
    {
      name: 'CodeRabbit',
      integration: 'PR review status gates task completion',
      file: 'app/routes/webhooks/github.ts',
      acceptance: 'Task locked until CodeRabbit approves'
    },
  ]

  return (
    <div className="p-6 max-w-6xl mx-auto">
      <h1 className="text-3xl font-bold mb-4">Sponsor Integration Checklist</h1>
      <p className="text-gray-600 mb-6">
        This page documents how each hackathon sponsor technology is integrated in HackPack.
      </p>

      <div className="space-y-4">
        {sponsors.map((sponsor) => (
          <div key={sponsor.name} className="bg-white rounded-lg shadow p-6">
            <div className="flex items-start justify-between">
              <div className="flex-1">
                <h2 className="text-xl font-bold mb-2">{sponsor.name}</h2>
                <p className="text-gray-700 mb-2">{sponsor.integration}</p>
                <p className="text-sm text-gray-500 mb-2">
                  <span className="font-medium">Code:</span> <code className="bg-gray-100 px-2 py-1 rounded">{sponsor.file}</code>
                </p>
                <p className="text-sm text-gray-600">
                  <span className="font-medium">Acceptance:</span> {sponsor.acceptance}
                </p>
              </div>
              <div>
                <input
                  type="checkbox"
                  className="w-5 h-5 text-blue-600"
                  aria-label={`Mark ${sponsor.name} as verified`}
                />
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="mt-8">
        <button className="bg-blue-600 text-white px-6 py-3 rounded-md hover:bg-blue-700">
          📥 Generate Submission Report
        </button>
      </div>
    </div>
  )
}

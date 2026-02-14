import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/dev')({
  component: DevPage,
})

function DevPage() {
  return (
    <div className="p-6">
      <h1 className="text-3xl font-bold mb-4">Development Workflow</h1>
      <p className="text-gray-600 mb-6">
        Manage GitHub PRs and CodeRabbit review statuses for workspace tasks.
      </p>

      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-semibold mb-4">PR-Linked Tasks</h2>

        <div className="space-y-3">
          <div className="border border-gray-300 rounded-lg p-4">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="font-medium">Sample Task with PR</h3>
                <a href="#" className="text-sm text-blue-600 hover:underline">
                  github.com/owner/repo/pull/123 ↗
                </a>
              </div>
              <div className="flex gap-2">
                <span className="px-2 py-1 bg-green-100 text-green-800 text-xs rounded">
                  Open
                </span>
                <span className="px-2 py-1 bg-yellow-100 text-yellow-800 text-xs rounded">
                  CodeRabbit: Pending
                </span>
              </div>
            </div>
          </div>
        </div>

        <div className="mt-4 text-sm text-gray-500">
          Tasks will be automatically unblocked when CodeRabbit approves the PR
        </div>
      </div>
    </div>
  )
}

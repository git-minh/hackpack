import { createFileRoute, Link } from '@tanstack/react-router'

export const Route = createFileRoute('/tasks/$taskId')({
  component: TaskDetailPage,
})

function TaskDetailPage() {
  const { taskId } = Route.useParams()

  return (
    <div className="p-6 max-w-4xl mx-auto">
      <div className="mb-4">
        <Link to="/tasks" className="text-blue-600 hover:text-blue-800 text-sm">
          ← Back to Tasks
        </Link>
      </div>

      <div className="bg-white rounded-lg shadow-lg p-6">
        <h1 className="text-3xl font-bold mb-4">Task #{taskId}</h1>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Status</label>
            <select className="border border-gray-300 rounded px-3 py-2">
              <option>Backlog</option>
              <option>In Progress</option>
              <option>Blocked</option>
              <option>Done</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
            <textarea
              className="w-full border border-gray-300 rounded px-3 py-2"
              rows={4}
              placeholder="Task description..."
            />
          </div>

          <div>
            <h3 className="font-semibold mb-2">Comments</h3>
            <div className="bg-gray-50 rounded p-4 text-sm text-gray-500">
              Comments will appear here (real-time collaboration)
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

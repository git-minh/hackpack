import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/tasks')({
  component: TasksPage,
})

function TasksPage() {
  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">Tasks</h1>
        <button className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
          + New Task
        </button>
      </div>

      {/* Kanban board will go here */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {['Backlog', 'In Progress', 'Blocked', 'Done'].map((status) => (
          <div key={status} className="bg-gray-50 rounded-lg p-4">
            <h3 className="font-semibold mb-3 text-gray-700">{status}</h3>
            <div className="space-y-2">
              <div className="bg-white p-3 rounded shadow-sm border border-gray-200">
                <p className="text-sm">Sample task</p>
                <span className="text-xs text-gray-500">Placeholder</span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

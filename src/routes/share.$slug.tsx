import { createFileRoute, Link } from '@tanstack/react-router'

export const Route = createFileRoute('/share/$slug')({
  component: SharePage,
})

function SharePage() {
  const { slug } = Route.useParams()

  return (
    <div className="p-6">
      <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
        <p className="text-sm text-blue-800">
          📢 You are viewing a shared workspace (read-only).
          <Link to="/" className="ml-2 underline font-medium">Sign in to collaborate</Link>
        </p>
      </div>

      <div>
        <h1 className="text-3xl font-bold mb-4">Shared Workspace: {slug}</h1>
        <p className="text-gray-600 mb-6">
          This is a public read-only view of the workspace.
        </p>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-white rounded-lg shadow p-4">
            <h3 className="font-semibold text-gray-700 mb-2">Tasks</h3>
            <p className="text-3xl font-bold text-blue-600">0</p>
          </div>
          <div className="bg-white rounded-lg shadow p-4">
            <h3 className="font-semibold text-gray-700 mb-2">Events</h3>
            <p className="text-3xl font-bold text-green-600">0</p>
          </div>
          <div className="bg-white rounded-lg shadow p-4">
            <h3 className="font-semibold text-gray-700 mb-2">Members</h3>
            <p className="text-3xl font-bold text-purple-600">0</p>
          </div>
        </div>
      </div>
    </div>
  )
}

import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/settings')({
  component: SettingsPage,
})

function SettingsPage() {
  return (
    <div className="p-6 max-w-4xl">
      <h1 className="text-3xl font-bold mb-6">Settings</h1>

      <div className="space-y-6">
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold mb-4">General</h2>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-1">Workspace Name</label>
              <input
                type="text"
                className="w-full border border-gray-300 rounded px-3 py-2"
                placeholder="My Workspace"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Workspace Slug</label>
              <input
                type="text"
                className="w-full border border-gray-300 rounded px-3 py-2"
                placeholder="my-workspace"
              />
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold mb-4">Integrations</h2>
          <div className="space-y-3">
            {['Firecrawl', 'Sentry', 'Autumn', 'Cloudflare Turnstile'].map((service) => (
              <div key={service} className="flex items-center justify-between py-2 border-b">
                <span>{service}</span>
                <span className="px-2 py-1 bg-gray-100 text-gray-600 text-xs rounded">
                  Not Configured
                </span>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold mb-4">Billing</h2>
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Autumn AI Credits</p>
              <p className="text-2xl font-bold">0</p>
            </div>
            <button className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
              Purchase Credits
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

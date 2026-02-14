import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/import')({
  component: ImportPage,
})

function ImportPage() {
  return (
    <div className="p-6">
      <h1 className="text-3xl font-bold mb-4">Import Event</h1>
      <p className="text-gray-600 mb-6">
        Paste any hackathon or conference URL to automatically extract tasks and calendar events.
      </p>
      <div className="max-w-2xl">
        <div className="bg-white rounded-lg shadow p-6">
          <label htmlFor="eventUrl" className="block text-sm font-medium mb-2">
            Event URL
          </label>
          <input
            type="url"
            id="eventUrl"
            placeholder="https://lu.ma/tanstack-start-hackathon"
            className="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
          <div className="mt-4">
            {/* Turnstile widget will go here */}
            <div className="bg-gray-100 border border-gray-300 rounded p-4 text-center text-sm text-gray-500">
              Cloudflare Turnstile verification (to be implemented)
            </div>
          </div>
          <button
            className="mt-6 w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 transition-colors"
            disabled
          >
            Import & Extract
          </button>
        </div>
      </div>
    </div>
  )
}

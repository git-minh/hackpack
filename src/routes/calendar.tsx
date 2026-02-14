import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/calendar')({
  component: CalendarPage,
})

function CalendarPage() {
  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">Calendar</h1>
        <button className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
          + New Event
        </button>
      </div>

      <div className="bg-white rounded-lg shadow p-6">
        <div className="mb-4 flex gap-2">
          <button className="px-3 py-1 bg-gray-200 rounded hover:bg-gray-300">Week</button>
          <button className="px-3 py-1 bg-gray-200 rounded hover:bg-gray-300">Month</button>
        </div>

        <div className="border border-gray-300 rounded-lg p-8 text-center text-gray-500">
          Calendar view will be implemented with react-big-calendar
        </div>

        <div className="mt-4">
          <button className="text-blue-600 hover:text-blue-800 text-sm">
            📥 Subscribe (ICS feed)
          </button>
        </div>
      </div>
    </div>
  )
}

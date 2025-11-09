import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/')({
  component: Home,
})

function Home() {
  return (
    <div className="p-4">
      <h2>Welcome to HackPack!</h2>
      <p>Transform any hackathon or event page into an actionable workspace with tasks and deadlines.</p>
      <div className="mt-4">
        <h3>Features:</h3>
        <ul>
          <li>✨ Import event pages with Firecrawl</li>
          <li>📋 Auto-generate tasks and calendar events</li>
          <li>🤝 Real-time collaboration with Convex</li>
          <li>🔒 PR gating with CodeRabbit</li>
          <li>📊 Sentry monitoring</li>
          <li>🚀 Hosted on Netlify</li>
        </ul>
      </div>
    </div>
  )
}

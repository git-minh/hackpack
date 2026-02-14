import { createRootRoute, Outlet, Link } from '@tanstack/react-router'
import { TanStackRouterDevtools } from '@tanstack/react-router-devtools'
import { Layout } from '../components/Layout'

export const Route = createRootRoute({
  component: RootComponent,
  errorComponent: RootErrorComponent,
  pendingComponent: () => (
    <div className="flex items-center justify-center min-h-screen">
      <div className="text-center">
        <div className="inline-block w-8 h-8 border-4 border-blue-600 border-t-transparent rounded-full animate-spin" />
        <p className="mt-2 text-gray-600">Loading...</p>
      </div>
    </div>
  ),
  notFoundComponent: () => (
    <Layout>
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <h1 className="text-6xl font-bold text-gray-300">404</h1>
          <p className="mt-4 text-xl text-gray-600">Page not found</p>
          <Link to="/" className="mt-4 inline-block text-blue-600 hover:underline">
            Go back home
          </Link>
        </div>
      </div>
    </Layout>
  ),
})

function RootComponent() {
  return (
    <>
      <Layout>
        <Outlet />
      </Layout>
      <TanStackRouterDevtools />
    </>
  )
}

function RootErrorComponent({ error }: { error: Error }) {
  return (
    <Layout>
      <div className="flex items-center justify-center min-h-screen p-4">
        <div className="max-w-2xl w-full bg-red-50 border border-red-200 rounded-lg p-6">
          <h1 className="text-2xl font-bold text-red-800 mb-4">Oops! Something went wrong</h1>
          <div className="bg-white rounded p-4 mb-4">
            <pre className="text-sm text-gray-800 overflow-auto">{error.message}</pre>
          </div>
          <button
            onClick={() => window.location.reload()}
            className="bg-red-600 text-white px-4 py-2 rounded hover:bg-red-700"
          >
            Reload Page
          </button>
        </div>
      </div>
    </Layout>
  )
}

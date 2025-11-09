import { createRootRoute, Outlet } from '@tanstack/react-router'
import { TanStackRouterDevtools } from '@tanstack/router-devtools'

export const Route = createRootRoute({
  component: () => (
    <>
      <div className="p-2">
        <h1>HackPack - Event-to-Workspace Planner</h1>
        <Outlet />
      </div>
      <TanStackRouterDevtools />
    </>
  ),
})

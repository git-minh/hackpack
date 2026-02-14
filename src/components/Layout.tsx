import { Link, useMatchRoute } from '@tanstack/react-router'
import { useState } from 'react'

interface LayoutProps {
  children: React.ReactNode
}

export function Layout({ children }: LayoutProps) {
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const matchRoute = useMatchRoute()

  const navigation = [
    { name: 'Dashboard', href: '/', icon: '📊' },
    { name: 'Import', href: '/import', icon: '📥' },
    { name: 'Tasks', href: '/tasks', icon: '✅' },
    { name: 'Calendar', href: '/calendar', icon: '📅' },
    { name: 'Dev', href: '/dev', icon: '💻' },
    { name: 'Settings', href: '/settings', icon: '⚙️' },
  ]

  const isActive = (href: string) => {
    if (href === '/') {
      return matchRoute({ to: '/', fuzzy: false })
    }
    return matchRoute({ to: href, fuzzy: true })
  }

  return (
    <div className="flex h-screen bg-gray-100">
      {/* Mobile sidebar backdrop */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black bg-opacity-50 z-20 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={`
          fixed lg:static inset-y-0 left-0 z-30
          w-64 bg-white shadow-lg
          transform transition-transform duration-300 ease-in-out
          ${sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
        `}
      >
        <div className="flex flex-col h-full">
          {/* Header */}
          <div className="p-4 border-b border-gray-200">
            <div className="flex items-center justify-between">
              <h1 className="text-xl font-bold text-gray-800">HackPack</h1>
              <button
                className="lg:hidden text-gray-500 hover:text-gray-700"
                onClick={() => setSidebarOpen(false)}
                aria-label="Close sidebar"
              >
                ✕
              </button>
            </div>
            {/* Workspace Switcher Placeholder */}
            <div className="mt-3">
              <button className="w-full text-left px-3 py-2 bg-gray-50 hover:bg-gray-100 rounded-md text-sm flex items-center justify-between">
                <span>My Workspace</span>
                <span className="text-xs">▼</span>
              </button>
            </div>
          </div>

          {/* Navigation */}
          <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
            {navigation.map((item) => {
              const active = isActive(item.href)
              return (
                <Link
                  key={item.name}
                  to={item.href}
                  className={`
                    flex items-center gap-3 px-3 py-2 rounded-md text-sm font-medium
                    transition-colors duration-150
                    ${
                      active
                        ? 'bg-blue-50 text-blue-700 border-l-4 border-blue-700'
                        : 'text-gray-700 hover:bg-gray-100'
                    }
                  `}
                  onClick={() => setSidebarOpen(false)}
                >
                  <span className="text-lg">{item.icon}</span>
                  <span>{item.name}</span>
                </Link>
              )
            })}
          </nav>

          {/* Footer / User Menu */}
          <div className="p-4 border-t border-gray-200">
            <div className="flex items-center gap-3 px-3 py-2 hover:bg-gray-100 rounded-md cursor-pointer">
              <div className="w-8 h-8 bg-gray-300 rounded-full flex items-center justify-center">
                👤
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-gray-700 truncate">User</p>
                <p className="text-xs text-gray-500 truncate">user@example.com</p>
              </div>
            </div>
          </div>
        </div>
      </aside>

      {/* Main content */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Mobile header */}
        <header className="lg:hidden bg-white shadow-sm p-4 flex items-center gap-3">
          <button
            onClick={() => setSidebarOpen(true)}
            className="text-gray-500 hover:text-gray-700"
            aria-label="Open sidebar"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>
          <h1 className="text-lg font-bold text-gray-800">HackPack</h1>
        </header>

        {/* Page content */}
        <main className="flex-1 overflow-y-auto">
          {children}
        </main>
      </div>
    </div>
  )
}

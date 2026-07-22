# Comprehensive Testing Guide

> **Complete testing documentation covering code quality, UI testing, accessibility, performance, and CI/CD**

## Table of Contents

1. [Code Quality & Linting](#code-quality--linting)
2. [Unit & Component Testing](#unit--component-testing)
3. [Integration Testing](#integration-testing)
4. [Accessibility Testing](#accessibility-testing)
5. [Visual Regression Testing](#visual-regression-testing)
6. [Performance Testing](#performance-testing)
7. [Viewport & Responsive Testing](#viewport--responsive-testing)
8. [E2E Testing](#e2e-testing)
9. [Security Testing](#security-testing)
10. [CI/CD Integration](#cicd-integration)
11. [Test Maintenance](#test-maintenance)
12. [Best Practices](#best-practices)

---

## Code Quality & Linting

### ESLint Configuration

Our project uses ESLint 8.57.0 with React-specific rules.

#### Current Configuration

**Location**: `eslint.config.js`

```javascript
import js from '@eslint/js'
import globals from 'globals'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'

export default [
  { ignores: ['dist'] },
  {
    files: ['**/*.{js,jsx,ts,tsx}'],
    languageOptions: {
      ecmaVersion: 2020,
      globals: globals.browser,
    },
    plugins: {
      'react-hooks': reactHooks,
      'react-refresh': reactRefresh,
    },
    rules: {
      ...reactHooks.configs.recommended.rules,
      'react-refresh/only-export-components': [
        'warn',
        { allowConstantExport: true },
      ],
    },
  },
]
```

#### Running Linting

```bash
# Check for linting errors
npm run lint

# Auto-fix issues (where possible)
npm run lint -- --fix

# Lint specific files
npx eslint src/components/**/*.tsx

# Show errors only (no warnings)
npx eslint src --quiet
```

#### Custom Lint Rules (Recommended)

Create `.eslintrc.cjs` for additional rules:

```javascript
module.exports = {
  extends: ['./eslint.config.js'],
  rules: {
    // Code Quality
    'no-console': ['warn', { allow: ['warn', 'error'] }],
    'no-debugger': 'error',
    'no-alert': 'error',
    'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    
    // React Best Practices
    'react/prop-types': 'off', // Using TypeScript
    'react/react-in-jsx-scope': 'off', // Not needed in React 17+
    'react-hooks/rules-of-hooks': 'error',
    'react-hooks/exhaustive-deps': 'warn',
    
    // TypeScript
    '@typescript-eslint/no-explicit-any': 'warn',
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    
    // Accessibility
    'jsx-a11y/alt-text': 'error',
    'jsx-a11y/anchor-is-valid': 'error',
    'jsx-a11y/click-events-have-key-events': 'warn',
    'jsx-a11y/no-static-element-interactions': 'warn',
  },
}
```

#### TypeScript Strict Mode

**Location**: `tsconfig.json`

```json
{
  "compilerOptions": {
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "noImplicitReturns": true,
    "skipLibCheck": true
  }
}
```

**Running Type Check:**

```bash
# Type check without building
npx tsc --noEmit

# Watch mode for development
npx tsc --noEmit --watch

# Type check specific files
npx tsc --noEmit src/components/demo.tsx
```

#### Code Formatting with Prettier (Optional)

**Installation:**
```bash
npm install -D prettier eslint-config-prettier
```

**`.prettierrc.json`:**
```json
{
  "semi": false,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100,
  "arrowParens": "always"
}
```

---

## Unit & Component Testing

### Vitest Setup

**Framework**: Vitest 4.1.10  
**Environment**: jsdom 27.0.1  
**Testing Library**: @testing-library/react 16.3.2

#### Test File Naming Conventions

```
Component.tsx          → Component.test.tsx
utils.ts               → utils.test.ts
hooks/useAuth.ts       → hooks/useAuth.test.ts
services/api.ts        → services/api.test.ts
```

#### Basic Test Structure

```typescript
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MyComponent } from './MyComponent'

describe('MyComponent', () => {
  beforeEach(() => {
    // Setup before each test
  })

  afterEach(() => {
    // Cleanup after each test
    vi.clearAllMocks()
  })

  it('should render correctly', () => {
    render(<MyComponent />)
    expect(screen.getByRole('button')).toBeInTheDocument()
  })

  it('should handle user interaction', async () => {
    const user = userEvent.setup()
    const handleClick = vi.fn()
    
    render(<MyComponent onClick={handleClick} />)
    await user.click(screen.getByRole('button'))
    
    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  it('should handle async operations', async () => {
    render(<MyComponent />)
    
    await waitFor(() => {
      expect(screen.getByText(/loading/i)).not.toBeInTheDocument()
    })
    
    expect(screen.getByText(/success/i)).toBeInTheDocument()
  })
})
```

#### Testing Library Query Priority

**Order of preference (most to least accessible):**

1. **`getByRole`** - Most accessible, tests semantic HTML
   ```typescript
   screen.getByRole('button', { name: /submit/i })
   screen.getByRole('textbox', { name: /email/i })
   screen.getByRole('heading', { level: 1 })
   ```

2. **`getByLabelText`** - Good for form fields
   ```typescript
   screen.getByLabelText(/email address/i)
   ```

3. **`getByPlaceholderText`** - Use when label is not available
   ```typescript
   screen.getByPlaceholderText(/enter your email/i)
   ```

4. **`getByText`** - For non-interactive content
   ```typescript
   screen.getByText(/welcome back/i)
   ```

5. **`getByTestId`** - Last resort only
   ```typescript
   screen.getByTestId('custom-component')
   ```

#### Mocking Best Practices

**Mock External Dependencies:**

```typescript
// Mock API calls
vi.mock('@/services/api', () => ({
  fetchUser: vi.fn(() => Promise.resolve({ id: 1, name: 'John' })),
}))

// Mock router
vi.mock('react-router-dom', () => ({
  useNavigate: () => vi.fn(),
  useParams: () => ({ id: '123' }),
}))

// Mock components
vi.mock('@/components/ui/shader-lines', () => ({
  ShaderAnimation: () => <div data-testid="shader">Shader</div>,
}))

// Mock hooks
vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { name: 'John' }, isAuthenticated: true }),
}))
```

**Mock timers:**

```typescript
import { vi } from 'vitest'

it('handles timeout', () => {
  vi.useFakeTimers()
  
  const callback = vi.fn()
  setTimeout(callback, 1000)
  
  vi.advanceTimersByTime(1000)
  expect(callback).toHaveBeenCalled()
  
  vi.useRealTimers()
})
```

#### Testing Async Components

```typescript
it('loads data on mount', async () => {
  render(<DataComponent />)
  
  // Wait for loading to disappear
  await waitFor(() => {
    expect(screen.queryByText(/loading/i)).not.toBeInTheDocument()
  })
  
  // Check data is displayed
  expect(screen.getByText(/john doe/i)).toBeInTheDocument()
})
```

---

## Integration Testing

### Testing Component Integration

**Test multiple components working together:**

```typescript
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { App } from './App'

describe('Newsletter Signup Integration', () => {
  it('submits form and shows success message', async () => {
    const user = userEvent.setup()
    render(<App />)
    
    // Find and fill form
    const emailInput = screen.getByPlaceholderText(/enter your email/i)
    await user.type(emailInput, 'test@example.com')
    
    // Submit form
    const submitButton = screen.getByRole('button', { name: /notify me/i })
    await user.click(submitButton)
    
    // Verify success state
    expect(await screen.findByText(/subscribed/i)).toBeInTheDocument()
    expect(submitButton).toBeDisabled()
  })
})
```

### Testing with Context Providers

```typescript
import { render } from '@testing-library/react'
import { ThemeProvider } from '@/contexts/ThemeContext'
import { AuthProvider } from '@/contexts/AuthContext'

const AllProviders = ({ children }) => (
  <ThemeProvider>
    <AuthProvider>
      {children}
    </AuthProvider>
  </ThemeProvider>
)

const customRender = (ui, options) =>
  render(ui, { wrapper: AllProviders, ...options })

// Usage
customRender(<MyComponent />)
```

---

## Accessibility Testing

### Automated Accessibility Testing

**Install axe-core:**

```bash
npm install -D @axe-core/react vitest-axe
```

**Setup:**

```typescript
import { axe, toHaveNoViolations } from 'vitest-axe'
import { render } from '@testing-library/react'

expect.extend(toHaveNoViolations)

it('should not have accessibility violations', async () => {
  const { container } = render(<MyComponent />)
  const results = await axe(container)
  expect(results).toHaveNoViolations()
})
```

### Manual Accessibility Checklist

#### Keyboard Navigation

```typescript
it('is keyboard navigable', async () => {
  const user = userEvent.setup()
  render(<Form />)
  
  // Tab through form fields
  await user.tab()
  expect(screen.getByRole('textbox')).toHaveFocus()
  
  await user.tab()
  expect(screen.getByRole('button')).toHaveFocus()
  
  // Submit with Enter
  await user.keyboard('{Enter}')
  expect(screen.getByText(/submitted/i)).toBeInTheDocument()
})
```

#### ARIA Attributes

```typescript
it('has proper ARIA attributes', () => {
  render(<Modal isOpen />)
  
  const dialog = screen.getByRole('dialog')
  expect(dialog).toHaveAttribute('aria-modal', 'true')
  expect(dialog).toHaveAttribute('aria-labelledby')
  expect(dialog).toHaveAttribute('aria-describedby')
})
```

#### Screen Reader Testing

**Test with actual screen readers:**
- **NVDA** (Windows) - Free
- **JAWS** (Windows) - Paid
- **VoiceOver** (macOS/iOS) - Built-in
- **TalkBack** (Android) - Built-in

#### Color Contrast

**Tool**: Contrast Checker (browser extension)

- **Normal text**: Minimum 4.5:1
- **Large text**: Minimum 3:1
- **UI components**: Minimum 3:1

#### Focus Management

```typescript
it('manages focus correctly', async () => {
  const { rerender } = render(<Modal isOpen={false} />)
  
  rerender(<Modal isOpen={true} />)
  
  // Focus should move to modal
  await waitFor(() => {
    expect(screen.getByRole('dialog')).toHaveFocus()
  })
  
  // Close modal
  rerender(<Modal isOpen={false} />)
  
  // Focus should return to trigger
  expect(document.activeElement).toBe(document.body)
})
```

---

## Visual Regression Testing

### Playwright Visual Testing

**Installation:**

```bash
npm install -D @playwright/test
npx playwright install
```

**Configuration:** `playwright.config.ts`

```typescript
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  
  use: {
    baseURL: 'http://localhost:5173',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
    { name: 'Mobile Chrome', use: { ...devices['Pixel 5'] } },
    { name: 'Mobile Safari', use: { ...devices['iPhone 12'] } },
  ],
  
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:5173',
    reuseExistingServer: !process.env.CI,
  },
})
```

**Visual Regression Test:**

```typescript
import { test, expect } from '@playwright/test'

test('landing page visual regression', async ({ page }) => {
  await page.goto('/')
  
  // Wait for shader animation to load
  await page.waitForLoadState('networkidle')
  
  // Take screenshot
  await expect(page).toHaveScreenshot('landing-page.png', {
    fullPage: true,
    maxDiffPixels: 100,
  })
})

test('newsletter form states', async ({ page }) => {
  await page.goto('/')
  
  // Initial state
  await expect(page.locator('form')).toHaveScreenshot('form-initial.png')
  
  // Filled state
  await page.fill('input[type="email"]', 'test@example.com')
  await expect(page.locator('form')).toHaveScreenshot('form-filled.png')
  
  // Success state
  await page.click('button[type="submit"]')
  await expect(page.locator('form')).toHaveScreenshot('form-success.png')
})
```

---

## Performance Testing

### Lighthouse CI

**Installation:**

```bash
npm install -D @lhci/cli
```

**Configuration:** `lighthouserc.json`

```json
{
  "ci": {
    "collect": {
      "startServerCommand": "npm run preview",
      "url": ["http://localhost:4173/"],
      "numberOfRuns": 3
    },
    "assert": {
      "preset": "lighthouse:recommended",
      "assertions": {
        "categories:performance": ["error", {"minScore": 0.9}],
        "categories:accessibility": ["error", {"minScore": 0.95}],
        "categories:best-practices": ["error", {"minScore": 0.9}],
        "categories:seo": ["error", {"minScore": 0.9}]
      }
    },
    "upload": {
      "target": "temporary-public-storage"
    }
  }
}
```

**Run Lighthouse:**

```bash
# Build first
npm run build

# Run Lighthouse CI
npx lhci autorun
```

### React Performance Testing

**React DevTools Profiler:**

```typescript
import { Profiler } from 'react'

function onRenderCallback(
  id: string,
  phase: 'mount' | 'update',
  actualDuration: number,
  baseDuration: number,
  startTime: number,
  commitTime: number
) {
  console.log(`${id} (${phase}) took ${actualDuration}ms`)
}

export function App() {
  return (
    <Profiler id="App" onRender={onRenderCallback}>
      <DemoOne />
    </Profiler>
  )
}
```

### Bundle Size Analysis

```bash
# Install analyzer
npm install -D rollup-plugin-visualizer

# Add to vite.config.ts
import { visualizer } from 'rollup-plugin-visualizer'

export default defineConfig({
  plugins: [
    react(),
    visualizer({ open: true })
  ]
})

# Build and analyze
npm run build
```

### Core Web Vitals Testing

```typescript
import { getCLS, getFID, getFCP, getLCP, getTTFB } from 'web-vitals'

function sendToAnalytics(metric) {
  console.log(metric.name, metric.value)
}

getCLS(sendToAnalytics)
getFID(sendToAnalytics)
getFCP(sendToAnalytics)
getLCP(sendToAnalytics)
getTTFB(sendToAnalytics)
```

---

## Viewport & Responsive Testing

### Standard Viewport Sizes

```typescript
const VIEWPORTS = {
  mobile: { width: 375, height: 667 },      // iPhone SE
  mobileLandscape: { width: 667, height: 375 },
  tablet: { width: 768, height: 1024 },     // iPad
  tabletLandscape: { width: 1024, height: 768 },
  laptop: { width: 1366, height: 768 },     // Common laptop
  desktop: { width: 1920, height: 1080 },   // Full HD
  ultrawide: { width: 2560, height: 1440 }, // 2K
  '4k': { width: 3840, height: 2160 },      // 4K
}
```

### Testing Responsive Design

**With Playwright:**

```typescript
import { test, expect } from '@playwright/test'

const BREAKPOINTS = [
  { name: 'mobile', width: 375, height: 667 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'desktop', width: 1920, height: 1080 },
]

BREAKPOINTS.forEach(({ name, width, height }) => {
  test(`responsive design on ${name}`, async ({ page }) => {
    await page.setViewportSize({ width, height })
    await page.goto('/')
    
    // Check layout
    const form = page.locator('form')
    
    if (name === 'mobile') {
      // Form should stack vertically
      await expect(form).toHaveCSS('flex-direction', 'column')
    } else {
      // Form should be horizontal
      await expect(form).toHaveCSS('flex-direction', 'row')
    }
    
    // Take screenshot
    await expect(page).toHaveScreenshot(`${name}-view.png`)
  })
})
```

### Tailwind Breakpoint Testing

```typescript
import { render, screen } from '@testing-library/react'

it('applies responsive classes correctly', () => {
  render(<DemoOne />)
  
  const heading = screen.getByText(/launching something cool/i)
  
  // Check Tailwind classes
  expect(heading).toHaveClass('text-5xl') // Mobile
  expect(heading).toHaveClass('md:text-7xl') // Desktop
})
```

### Testing Orientation Changes

```typescript
test('handles orientation change', async ({ page }) => {
  await page.goto('/')
  
  // Portrait
  await page.setViewportSize({ width: 375, height: 667 })
  await expect(page).toHaveScreenshot('portrait.png')
  
  // Landscape
  await page.setViewportSize({ width: 667, height: 375 })
  await expect(page).toHaveScreenshot('landscape.png')
})
```

### Container Query Testing

```typescript
it('adapts to container size', () => {
  const { container } = render(
    <div style={{ width: '300px' }}>
      <ResponsiveComponent />
    </div>
  )
  
  // Component should adapt to 300px container
  expect(container.firstChild).toHaveStyle({ fontSize: '14px' })
})
```

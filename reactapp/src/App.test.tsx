import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import App from './App'

// Mock the DemoOne component
vi.mock('./components/demo', () => ({
  default: () => <div data-testid="demo-component">Demo One Component</div>,
}))

describe('App Component', () => {
  it('renders without crashing', () => {
    render(<App />)
    expect(screen.getByTestId('demo-component')).toBeInTheDocument()
  })

  it('renders the DemoOne component', () => {
    render(<App />)
    expect(screen.getByText(/Demo One Component/i)).toBeInTheDocument()
  })
})

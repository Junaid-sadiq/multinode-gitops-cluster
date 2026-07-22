import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import DemoOne from './demo'

// Mock the ShaderAnimation component
vi.mock('@/components/ui/shader-lines', () => ({
  ShaderAnimation: () => <div data-testid="shader-animation">Shader Animation</div>,
}))

describe('DemoOne Component', () => {
  it('renders the heading text correctly', () => {
    render(<DemoOne />)
    
    expect(screen.getByText(/Launching Something Cool/i)).toBeInTheDocument()
    expect(screen.getByText(/Very Soon/i)).toBeInTheDocument()
  })

  it('renders the newsletter signup call to action', () => {
    render(<DemoOne />)
    
    expect(screen.getByText(/Sign Up for Newsletter/i)).toBeInTheDocument()
  })

  it('renders the email input field', () => {
    render(<DemoOne />)
    
    const emailInput = screen.getByPlaceholderText(/Enter your email/i)
    expect(emailInput).toBeInTheDocument()
    expect(emailInput).toHaveAttribute('type', 'email')
    expect(emailInput).toHaveAttribute('required')
  })

  it('renders the submit button', () => {
    render(<DemoOne />)
    
    const submitButton = screen.getByRole('button', { name: /Notify Me/i })
    expect(submitButton).toBeInTheDocument()
  })

  it('renders the ShaderAnimation component', () => {
    render(<DemoOne />)
    
    expect(screen.getByTestId('shader-animation')).toBeInTheDocument()
  })

  it('allows user to type email address', async () => {
    const user = userEvent.setup()
    render(<DemoOne />)
    
    const emailInput = screen.getByPlaceholderText(/Enter your email/i) as HTMLInputElement
    await user.type(emailInput, 'test@example.com')
    
    expect(emailInput.value).toBe('test@example.com')
  })

  it('submits the form with valid email', async () => {
    const user = userEvent.setup()
    const consoleSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
    
    render(<DemoOne />)
    
    const emailInput = screen.getByPlaceholderText(/Enter your email/i)
    const submitButton = screen.getByRole('button', { name: /Notify Me/i })
    
    await user.type(emailInput, 'test@example.com')
    await user.click(submitButton)
    
    expect(consoleSpy).toHaveBeenCalledWith('Email submitted:', 'test@example.com')
    
    consoleSpy.mockRestore()
  })

  it('shows success message after form submission', async () => {
    const user = userEvent.setup()
    render(<DemoOne />)
    
    const emailInput = screen.getByPlaceholderText(/Enter your email/i)
    const submitButton = screen.getByRole('button', { name: /Notify Me/i })
    
    await user.type(emailInput, 'test@example.com')
    await user.click(submitButton)
    
    await waitFor(() => {
      expect(screen.getByText(/✓ Subscribed!/i)).toBeInTheDocument()
    })
  })

  it('disables button after submission', async () => {
    const user = userEvent.setup()
    render(<DemoOne />)
    
    const emailInput = screen.getByPlaceholderText(/Enter your email/i)
    const submitButton = screen.getByRole('button', { name: /Notify Me/i })
    
    await user.type(emailInput, 'test@example.com')
    await user.click(submitButton)
    
    await waitFor(() => {
      expect(submitButton).toBeDisabled()
    })
  })

  it('clears email input after successful submission timeout', async () => {
    vi.useFakeTimers()
    const user = userEvent.setup({ delay: null })
    
    render(<DemoOne />)
    
    const emailInput = screen.getByPlaceholderText(/Enter your email/i) as HTMLInputElement
    const submitButton = screen.getByRole('button', { name: /Notify Me/i })
    
    await user.type(emailInput, 'test@example.com')
    await user.click(submitButton)
    
    // Fast-forward time by 3 seconds
    vi.advanceTimersByTime(3000)
    
    await waitFor(() => {
      expect(emailInput.value).toBe('')
    })
    
    vi.useRealTimers()
  })

  it('prevents form submission without email', () => {
    render(<DemoOne />)
    
    const form = screen.getByRole('button', { name: /Notify Me/i }).closest('form')
    const emailInput = screen.getByPlaceholderText(/Enter your email/i)
    
    // Try to submit empty form
    fireEvent.submit(form!)
    
    // Email input should have the 'required' attribute preventing submission
    expect(emailInput).toBeInvalid()
  })

  it('has proper responsive classes', () => {
    const { container } = render(<DemoOne />)
    
    const heading = screen.getByText(/Launching Something Cool/i)
    expect(heading).toHaveClass('text-5xl', 'md:text-7xl')
    
    const subtitle = screen.getByText(/Sign Up for Newsletter/i)
    expect(subtitle).toHaveClass('text-xl', 'md:text-2xl')
  })

  it('applies proper styling classes to form elements', () => {
    render(<DemoOne />)
    
    const emailInput = screen.getByPlaceholderText(/Enter your email/i)
    expect(emailInput).toHaveClass('rounded-full', 'bg-white/10', 'backdrop-blur-md')
    
    const submitButton = screen.getByRole('button', { name: /Notify Me/i })
    expect(submitButton).toHaveClass('rounded-full', 'bg-white', 'text-black')
  })
})

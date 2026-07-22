import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { ShaderAnimation } from './shader-lines'

describe('ShaderAnimation Component', () => {
  let mockThree: any
  
  beforeEach(() => {
    // Mock Three.js
    mockThree = {
      Camera: vi.fn().mockImplementation(function() {
        this.position = { z: 0 }
      }),
      Scene: vi.fn().mockImplementation(function() {
        this.add = vi.fn()
      }),
      PlaneBufferGeometry: vi.fn(),
      Vector2: vi.fn(),
      ShaderMaterial: vi.fn(),
      Mesh: vi.fn(),
      WebGLRenderer: vi.fn().mockImplementation(function() {
        this.setPixelRatio = vi.fn()
        this.domElement = document.createElement('canvas')
        this.setSize = vi.fn()
        this.render = vi.fn()
        this.dispose = vi.fn()
      }),
    }
    
    // Mock script loading
    const originalCreateElement = document.createElement.bind(document)
    vi.spyOn(document, 'createElement').mockImplementation((tag: string) => {
      const element = originalCreateElement(tag)
      if (tag === 'script') {
        // Simulate script loading
        setTimeout(() => {
          (window as any).THREE = mockThree
          element.dispatchEvent(new Event('load'))
        }, 0)
      }
      return element
    })
  })

  afterEach(() => {
    delete (window as any).THREE
    vi.restoreAllMocks()
  })

  it('renders the container div', () => {
    const { container } = render(<ShaderAnimation />)
    const containerDiv = container.firstChild as HTMLElement
    
    expect(containerDiv).toBeInTheDocument()
    expect(containerDiv).toHaveClass('w-full', 'h-full', 'absolute')
  })

  it('loads Three.js script dynamically', async () => {
    render(<ShaderAnimation />)
    
    await waitFor(() => {
      const scripts = document.querySelectorAll('script')
      const threeScript = Array.from(scripts).find(
        script => script.src.includes('three.min.js')
      )
      expect(threeScript).toBeTruthy()
    })
  })

  it('initializes Three.js scene after script loads', async () => {
    render(<ShaderAnimation />)
    
    await waitFor(() => {
      expect((window as any).THREE).toBeDefined()
    }, { timeout: 1000 })
  })

  it('creates a canvas element for WebGL rendering', async () => {
    const { container } = render(<ShaderAnimation />)
    
    await waitFor(() => {
      const canvas = container.querySelector('canvas')
      expect(canvas).toBeInTheDocument()
    }, { timeout: 1000 })
  })

  it('applies proper CSS classes to container', () => {
    const { container } = render(<ShaderAnimation />)
    const containerDiv = container.firstChild as HTMLElement
    
    expect(containerDiv.className).toContain('w-full')
    expect(containerDiv.className).toContain('h-full')
    expect(containerDiv.className).toContain('absolute')
  })

  it('cleans up on unmount', async () => {
    const { unmount } = render(<ShaderAnimation />)
    
    // Wait for script to load
    await waitFor(() => {
      expect((window as any).THREE).toBeDefined()
    }, { timeout: 1000 })
    
    const cancelAnimationFrameSpy = vi.spyOn(window, 'cancelAnimationFrame')
    
    unmount()
    
    // Verify cleanup happened
    await waitFor(() => {
      expect(cancelAnimationFrameSpy).toHaveBeenCalled()
    })
  })

  it('handles missing Three.js gracefully', () => {
    // Remove the mock to simulate missing Three.js
    vi.spyOn(document, 'createElement').mockImplementation((tag: string) => {
      const element = document.createElement.bind(document)(tag)
      // Don't load Three.js
      return element
    })
    
    const { container } = render(<ShaderAnimation />)
    
    // Should still render container without errors
    expect(container.firstChild).toBeInTheDocument()
  })

  it('has proper ref for container element', () => {
    const { container } = render(<ShaderAnimation />)
    const containerDiv = container.firstChild as HTMLElement
    
    expect(containerDiv.tagName).toBe('DIV')
  })
})

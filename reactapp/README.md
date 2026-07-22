# React Shader Lines Demo

A modern React application featuring interactive WebGL shader animations using Three.js, built with Vite, TypeScript, Tailwind CSS, and shadcn/ui components.

## 🚀 Features

- **TypeScript** - Type-safe React development
- **Tailwind CSS** - Utility-first CSS framework
- **shadcn/ui** - High-quality, accessible UI components
- **Three.js** - WebGL shader animations
- **Vite** - Lightning-fast development experience
- **Hot Module Replacement** - Instant feedback during development

## 📋 Prerequisites

- Node.js v20.17.0 or higher
- npm 10.8.2 or higher

## 🛠️ Tech Stack

- **React 18.3.1** - UI library
- **TypeScript** - Type safety
- **Vite 5.4.1** - Build tool
- **Tailwind CSS** - Styling
- **shadcn/ui** - Component library
- **Three.js** - 3D graphics (loaded via CDN)
- **Lucide React** - Icon library

## 📦 Installation

The project is already set up. To install dependencies:

```bash
npm install
```

## 🏃‍♂️ Running the Application

Start the development server:

```bash
npm run dev
```

The application will be available at **http://localhost:5173/**

## 🏗️ Project Structure

```
reactapp/
├── src/
│   ├── components/
│   │   ├── ui/
│   │   │   └── shader-lines.tsx    # Shader animation component
│   │   └── demo.tsx                # Demo wrapper component
│   ├── lib/
│   │   └── utils.ts                # Utility functions (cn helper)
│   ├── App.tsx                     # Main application component
│   ├── main.tsx                    # Application entry point
│   ├── index.css                   # Global styles with Tailwind
│   └── App.css                     # Component-specific styles
├── public/                         # Static assets
├── components.json                 # shadcn/ui configuration
├── tailwind.config.js              # Tailwind CSS configuration
├── tsconfig.json                   # TypeScript configuration
├── vite.config.ts                  # Vite configuration
└── package.json                    # Project dependencies
```

## 🎨 Component Overview

### ShaderAnimation Component

Located at `src/components/ui/shader-lines.tsx`, this component:

- Dynamically loads Three.js from CDN
- Creates an animated WebGL shader scene
- Implements custom GLSL shaders for visual effects
- Handles window resizing and cleanup automatically
- Uses React hooks for lifecycle management

**Props**: None (self-contained)

**Usage**:
```tsx
import { ShaderAnimation } from "@/components/ui/shader-lines";

<div className="relative h-[650px] w-full">
  <ShaderAnimation />
</div>
```

### Demo Component

Located at `src/components/demo.tsx`:

- Wraps the shader animation with styled container
- Adds centered text overlay
- Fully responsive design

## 🎯 Key Features Explained

### Path Aliases

The project uses TypeScript path aliases for cleaner imports:

```typescript
// Instead of: import { ShaderAnimation } from '../../components/ui/shader-lines'
// You can use:
import { ShaderAnimation } from '@/components/ui/shader-lines'
```

### Tailwind CSS Integration

- Custom CSS variables for theming
- Dark mode support (via `class` strategy)
- shadcn/ui design tokens
- Responsive utilities

### shadcn/ui Setup

The project follows shadcn/ui conventions:

- Components in `src/components/ui/`
- Utilities in `src/lib/utils.ts`
- Proper `cn()` helper for className merging
- Configuration in `components.json`

## 🔧 Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint

## 🎨 Customization

### Modifying the Shader

Edit the fragment shader in `src/components/ui/shader-lines.tsx`:

```typescript
const fragmentShader = `
  // Your custom GLSL shader code here
`
```

### Styling

- Global styles: `src/index.css`
- Tailwind config: `tailwind.config.js`
- Component styles: Use Tailwind utility classes

### Adding shadcn/ui Components

To add more shadcn/ui components, you would typically use:

```bash
npx shadcn-ui@latest add button
```

However, since shadcn/ui requires a specific CLI setup, components are manually added following their structure.

## 🐛 Troubleshooting

### Three.js Not Loading

The component loads Three.js from CDN. Ensure you have an active internet connection.

### TypeScript Errors

Run `npm install` to ensure all type definitions are installed.

### Styling Issues

Ensure Tailwind CSS is properly configured and `index.css` contains the directives:
```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

## 📝 Notes

- The shader animation uses WebGL and requires a compatible browser
- Performance depends on GPU capabilities
- The component automatically handles cleanup to prevent memory leaks
- Responsive design is built-in with Tailwind utilities

## 🚀 Production Build

To build for production:

```bash
npm run build
```

The optimized files will be in the `dist/` directory.

To preview the production build locally:

```bash
npm run preview
```

## 📄 License

This project is part of a multi-node Kubernetes GitOps cluster demonstration.

## 🤝 Contributing

This is a demonstration project. Feel free to use it as a template for your own shader experiments!

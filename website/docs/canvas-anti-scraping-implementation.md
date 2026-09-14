# Canvas Anti-Scraping Implementation with YAML Syntax Highlighting (Web Worker Architecture)

## Overview

This implementation adds an anti-scraping feature to the Vite-based documentation site by replacing standard DOM-based code/text blocks with a `<canvas>` rendering implementation using a Web Worker with OffscreenCanvas API. This makes it difficult for scrapers to extract the raw text content while providing basic YAML syntax highlighting.

## Architecture Analysis

The application uses **React 18.3.0 + TypeScript** with Vite as the frontend framework. The `CodeViewer` component currently renders file content using Prism.js for syntax highlighting.

## Implementation Details

### 1. Worker File: `yaml-renderer.worker.ts`

Created a dedicated Web Worker that handles all YAML tokenization and canvas rendering:

#### Worker Message Handler
- Expects payload: `{ canvas, text, pixelRatio, width, height }`
- Uses `self.onmessage` event listener
- Returns `{ success: boolean, error?: string }` response

#### Offscreen Rendering Logic
- Receives `OffscreenCanvas` from main thread
- Gets context: `const ctx = canvas.getContext('2d')`
- Applies high-DPI scaling: `ctx.scale(pixelRatio, pixelRatio)`
- Sets standard monospace font
- Executes tokenizer and rendering loop directly on OffscreenCanvas

#### YAML Tokenizer Implementation
- **Token Types**: comments, keys, strings, booleans, numbers, default
- **Color Palette**: Dark mode theme with specific colors
- **Tokenization**: Regular expression-based parsing
- **Text Wrapping**: Respects token boundaries for proper wrapping
- **Rendering**: Horizontal X-offset loop with token-by-token drawing

#### High-DPI Support
- Scales canvas based on `window.devicePixelRatio`
- Uses `ctx.scale()` for proper scaling
- Maintains sharp text rendering

### 2. Main Thread Component: `CanvasCodeBlock.tsx`

Refactored to use Web Worker architecture:

#### Worker Initialization
```typescript
const worker = new Worker(
  new URL('./workers/yaml-renderer.worker.ts', import.meta.url),
  { type: 'module' }
);
```

#### OffscreenCanvas Transfer
```typescript
const offscreen = canvas.transferControlToOffscreen();
worker.postMessage(
  { canvas: offscreen, text: rawYamlString, pixelRatio: window.devicePixelRatio },
  [offscreen]
);
```

#### Lifecycle Management
- Worker initialized on mount
- Cleanup on unmount: `worker.terminate()`
- Resize handler for responsive rendering
- Initial render after layout dimensions known

### 3. YAML Tokenizer Implementation

#### Token Types
- **comment**: Anything starting with `#` to end of line
- **key**: Words followed by colon (e.g., `^\s*[\w.-]+:`)
- **string**: Text wrapped in single or double quotes
- **boolean**: `true` or `false`
- **number**: Numeric values
- **default**: Remaining whitespace or unclassified punctuation

#### Color Palette (Dark Mode)
- key: #E06C75 (Red/Pink)
- string: #98C379 (Green)
- number/boolean: #D19A66 (Orange)
- comment: #5C6370 (Grey)
- default: #ABB2BF (Light Grey)

### 4. Styles: `CanvasCodeBlock.css`

- Wrapper styling with border and background
- Canvas styling with transparent background
- Removed syntax highlighting color classes (now handled in worker)
- Copy button styling maintained

### 5. Integration: `CodeViewer.tsx`

Replaced the standard `<pre><code>` rendering with the new `CanvasCodeBlock` component:

```tsx
<div className="canvas-code-block-wrapper">
  <CanvasCodeBlock content={file.content} />
</div>
```

### 6. Styles: `CodeViewer.css`

Added canvas-related styles to the existing CSS file with theme support for both "runbook-dawn" and "terminal-dusk" themes.

## Security Trade-offs

- **Accessibility**: Screen readers cannot read canvas content due to `aria-hidden="true"`
- **Copy functionality**: Still works via button, but text is not accessible to screen readers
- **Visual rendering**: Text is rendered but not selectable via standard text selection

## Usage

The component is now used wherever the application renders playbook text (e.g., parsing the `Taskfile.yml` content). The component is automatically applied to all code blocks in the viewer.

## Testing

To test the implementation:

```bash
cd website
npm run dev
```

Navigate to any code file and verify:
- Text renders correctly on canvas
- High-DPI displays show sharp text
- Copy button works
- Context menu is blocked
- Scrollable content works
- Theme colors match the application theme
- YAML syntax highlighting works (keys, strings, numbers, booleans, comments)
- Worker handles rendering without blocking main thread

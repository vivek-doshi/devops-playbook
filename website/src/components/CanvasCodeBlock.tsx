import React, { useEffect, useRef, useCallback } from 'react';
import { debounce } from '../utils/debounce';

interface CanvasCodeBlockProps {
  content: string;
  language?: string;
}

export const CanvasCodeBlock: React.FC<CanvasCodeBlockProps> = ({ content }) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const wrapperRef = useRef<HTMLDivElement>(null);
  const contentRef = useRef<string>(content);
  const workerRef = useRef<Worker | null>(null);
  const observerRef = useRef<ResizeObserver | null>(null);

  // Initialize worker
  useEffect(() => {
    try {
      const worker = new Worker(
        new URL('../workers/yaml-renderer.worker.ts', import.meta.url),
        { type: 'module' }
      );
      workerRef.current = worker;

      // Handle worker response
      worker.onmessage = (e: MessageEvent<{ success: boolean, error?: string }>) => {
        if (e.data.success) {
          console.log('Canvas rendering completed successfully');
        } else {
      console.error('Canvas rendering failed:', e.data.error);
        }
      };

      return () => {
        worker.terminate();
      };
    } catch (error) {
      console.error('Failed to initialize worker:', error);
      return;
    }
  }, []);

  // Render content when dimensions are known
  const handleRender = useCallback((width: number, height: number) => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const dpr = window.devicePixelRatio || 1;

    // Set CSS dimensions
    canvas.style.width = `${width}px`;
    canvas.style.height = `${height}px`;

    // Set HTML attributes for high-DPI
    canvas.width = width * dpr;
    canvas.height = height * dpr;

    // Detach canvas from main thread
    const offscreen = canvas.transferControlToOffscreen();

    // Post message to worker
    const worker = workerRef.current;
    if (worker) {
      worker.postMessage(
        { type: 'INIT', canvas: offscreen, text: content, pixelRatio: dpr, width, height },
        [offscreen]
      );
    }
  }, [content]);

  // Debounced resize handler
  const debouncedResize = useCallback(debounce(() => {
    const wrapper = wrapperRef.current;
    const canvas = canvasRef.current;
    if (!wrapper || !canvas) return;

    const newWidth = wrapper.clientWidth || 600;
    const newHeight = wrapper.clientHeight || 400;

    // Update canvas CSS dimensions
    canvas.style.width = `${newWidth}px`;
    canvas.style.height = `${newHeight}px`;

    // Post resize message to worker
    const worker = workerRef.current;
    if (worker) {
      worker.postMessage({
        type: 'RESIZE',
        width: newWidth,
        height: newHeight,
        pixelRatio: window.devicePixelRatio || 1
      });
    }
  }, 150), []);

  // ResizeObserver setup
  useEffect(() => {
    const wrapper = wrapperRef.current;
    if (!wrapper) return;

    // Create ResizeObserver
    const observer = new ResizeObserver(() => {
      debouncedResize();
    });

    observerRef.current = observer;

    // Attach to wrapper
    observer.observe(wrapper);

    return () => {
      observer.disconnect();
    };
  }, [debouncedResize]);

  // Initial render
  useEffect(() => {
    const wrapper = wrapperRef.current;
    const canvas = canvasRef.current;
    if (!wrapper || !canvas) return;

    const newWidth = wrapper.clientWidth || 600;
    const newHeight = wrapper.clientHeight || 400;

    handleRender(newWidth, newHeight);
  }, [handleRender]);

  return (
    <div ref={wrapperRef} className="canvas-code-block-wrapper">
      <canvas
        ref={canvasRef}
        className="canvas-code-block"
        aria-hidden="true"
      />
      <button
        className="copy-code-btn"
        onClick={() => {
          navigator.clipboard.writeText(contentRef.current);
        }}
        title="Copy code to clipboard"
      >
        Copy Code
      </button>
    </div>
  );
};

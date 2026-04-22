// Note 1: Imports make dependencies explicit, which keeps module boundaries clear and simplifies maintenance.
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  // Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  plugins: [react()],
  base: '/devops-playbook/',
  build: {
    // Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    outDir: 'dist',
    sourcemap: false,
  },
  // Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  server: {
    port: 3000,
    open: true,
  }
})

// Note 1: Imports make dependencies explicit, which keeps module boundaries clear and simplifies maintenance.
import React from 'react'
import ReactDOM from 'react-dom/client'
// Note 2: Imports make dependencies explicit, which keeps module boundaries clear and simplifies maintenance.
import App from './App.tsx'

ReactDOM.createRoot(document.getElementById('root')!).render(
  // Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)

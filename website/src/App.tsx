// Note 1: Imports make dependencies explicit, which keeps module boundaries clear and simplifies maintenance.
import { useState, useEffect } from 'react';
import { Sidebar } from './components/Sidebar';
import { CodeViewer } from './components/CodeViewer';
// Note 2: Imports make dependencies explicit, which keeps module boundaries clear and simplifies maintenance.
import './App.css';

type ThemeName = 'ocean' | 'paper';

interface FileItem {
  // Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  path: string;
  category: string;
  language: string;
  // Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  size: number;
  content: string;
  fileName: string;
// Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

function App() {
  const [files, setFiles] = useState<FileItem[]>([]);
  // Note 6: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  const [selectedFile, setSelectedFile] = useState<FileItem | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [theme, setTheme] = useState<ThemeName>(() => {
    // Note 7: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
    const savedTheme = window.localStorage.getItem('devops-playbook-theme');
    return savedTheme === 'paper' ? 'paper' : 'ocean';
  });
  // Note 8: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    window.localStorage.setItem('devops-playbook-theme', theme);
  }, [theme]);

  useEffect(() => {
    // Note 10: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
    const loadFiles = async () => {
      try {
        const response = await fetch('./index.json');
        // Note 11: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting.
        if (!response.ok) throw new Error('Failed to load index');
        const data = await response.json();
        setFiles(data);
        // Note 12: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting.
        if (data.length > 0) {
          setSelectedFile(data[0]);
        }
      // Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      } catch (err) {
        setError('Failed to load file index. Make sure to run `npm run build` first.');
        console.error(err);
      // Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      } finally {
        setLoading(false);
      }
    // Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    };

    loadFiles();
  }, []);

  // Note 16: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting.
  if (loading) {
    return (
      <div className="app loading">
        // Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
        <div className="loading-spinner">Loading files...</div>
      </div>
    );
  // Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }

  if (error) {
    return (
      // Note 19: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      <div className="app error">
        <div className="error-message">
          <h2>⚠️ Error</h2>
          // Note 20: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
          <p>{error}</p>
          <p style={{ fontSize: '12px', color: '#888', marginTop: '16px' }}>
            Run <code>npm run build</code> to generate the index.json file.
          // Note 21: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
          </p>
        </div>
      </div>
    // Note 22: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    );
  }

  return (
    // Note 23: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    <div className="app" data-theme={theme}>
      <Sidebar
        files={files}
        selectedFile={selectedFile}
        onFileSelect={setSelectedFile}
        searchQuery={searchQuery}
        onSearchChange={setSearchQuery}
        theme={theme}
        onThemeChange={setTheme}
      />
      <CodeViewer file={selectedFile} />
    </div>
  );
}

export default App;

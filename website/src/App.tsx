import { useState, useEffect, useCallback } from 'react';
import { Sidebar } from './components/Sidebar';
import { CodeViewer } from './components/CodeViewer';
import { TopBar } from './components/TopBar';
import { Preloader } from './components/Preloader';
import './App.css';

type ThemeName = 'runbook-dawn' | 'terminal-dusk';

interface FileItem {
  path: string;
  category: string;
  language: string;
  size: number;
  content: string;
  fileName: string;
}

function App() {
  const [files, setFiles] = useState<FileItem[]>([]);
  const [selectedFile, setSelectedFile] = useState<FileItem | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [theme, setTheme] = useState<ThemeName>(() => {
    const savedTheme = window.localStorage.getItem('devops-playbook-theme');
    if (savedTheme === 'terminal-dusk' || savedTheme === 'midnight') {
      return 'terminal-dusk';
    }

    return 'runbook-dawn';
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showPreloader, setShowPreloader] = useState(true);

  useEffect(() => {
    window.localStorage.setItem('devops-playbook-theme', theme);
  }, [theme]);

  useEffect(() => {
    const loadFiles = async () => {
      try {
        const response = await fetch('./index.json');
        if (!response.ok) throw new Error('Failed to load index');
        const data = await response.json();
        setFiles(data);
      } catch (err) {
        setError('Failed to load file index. Make sure to run `npm run build` first.');
        console.error(err);
      } finally {
        setLoading(false);
      }
    };

    loadFiles();
  }, []);

  useEffect(() => {
    if (files.length === 0) {
      return;
    }

    const params = new URLSearchParams(window.location.search);
    const urlFile = params.get('file');

    if (!urlFile) {
      return;
    }

    const matched = files.find((item) => item.path === urlFile);
    if (matched) {
      setSelectedFile(matched);
    }
  }, [files]);

  useEffect(() => {
    if (files.length === 0) {
      return;
    }

    const onPopState = () => {
      const params = new URLSearchParams(window.location.search);
      const urlFile = params.get('file');

      if (!urlFile) {
        setSelectedFile(null);
        return;
      }

      const matched = files.find((item) => item.path === urlFile);
      setSelectedFile(matched ?? null);
    };

    window.addEventListener('popstate', onPopState);
    return () => window.removeEventListener('popstate', onPopState);
  }, [files]);

  const handleFileSelect = (file: FileItem) => {
    setSelectedFile(file);

    const params = new URLSearchParams(window.location.search);
    const current = params.get('file');
    if (current === file.path) {
      return;
    }

    params.set('file', file.path);
    const next = `${window.location.pathname}?${params.toString()}${window.location.hash}`;
    window.history.pushState({ file: file.path }, '', next);
  };

  const handleRandomFile = useCallback(() => {
    if (files.length === 0) return;
    const randomIndex = Math.floor(Math.random() * files.length);
    handleFileSelect(files[randomIndex]);
  }, [files]);

  if (showPreloader) {
    return (
      <Preloader
        theme={theme}
        onDone={() => setShowPreloader(false)}
      />
    );
  }

  if (loading) {
    return <Preloader theme={theme} />;
  }

  if (error) {
    return (
      <div className="app error">
        <div className="error-message">
          <h2>⚠️ Error</h2>
          <p>{error}</p>
          <p style={{ fontSize: '12px', color: '#888', marginTop: '16px' }}>
            Run <code>npm run build</code> to generate the index.json file.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="app" data-theme={theme}>
      <TopBar
        files={files}
        theme={theme}
        onThemeChange={setTheme}
        onRandomFile={handleRandomFile}
      />
      <div className="main-content">
        <Sidebar
          files={files}
          selectedFile={selectedFile}
          onFileSelect={handleFileSelect}
          searchQuery={searchQuery}
          onSearchChange={setSearchQuery}
        />
        <CodeViewer file={selectedFile} files={files} onFileSelect={handleFileSelect} />
      </div>
    </div>
  );
}

export default App;

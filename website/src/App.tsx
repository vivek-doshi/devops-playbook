import React, { useState, useEffect } from 'react';
import { Sidebar } from './components/Sidebar';
import { CodeViewer } from './components/CodeViewer';
import './App.css';

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
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const loadFiles = async () => {
      try {
        const response = await fetch('./index.json');
        if (!response.ok) throw new Error('Failed to load index');
        const data = await response.json();
        setFiles(data);
        if (data.length > 0) {
          setSelectedFile(data[0]);
        }
      } catch (err) {
        setError('Failed to load file index. Make sure to run `npm run build` first.');
        console.error(err);
      } finally {
        setLoading(false);
      }
    };

    loadFiles();
  }, []);

  if (loading) {
    return (
      <div className="app loading">
        <div className="loading-spinner">Loading files...</div>
      </div>
    );
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
    <div className="app">
      <Sidebar
        files={files}
        selectedFile={selectedFile}
        onFileSelect={setSelectedFile}
        searchQuery={searchQuery}
        onSearchChange={setSearchQuery}
      />
      <CodeViewer file={selectedFile} />
    </div>
  );
}

export default App;

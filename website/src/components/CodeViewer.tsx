import React, { useEffect } from 'react';
import { Copy, ExternalLink } from 'lucide-react';
import Prism from 'prismjs';
import 'prismjs/components/prism-bash';
import 'prismjs/components/prism-yaml';
import 'prismjs/components/prism-json';
import 'prismjs/components/prism-python';
import 'prismjs/components/prism-typescript';
import 'prismjs/components/prism-javascript';
import 'prismjs/components/prism-java';
import 'prismjs/components/prism-docker';
import 'prismjs/components/prism-go';
import 'prismjs/components/prism-ruby';
import './CodeViewer.css';

interface FileItem {
  path: string;
  category: string;
  language: string;
  size: number;
  content: string;
  fileName: string;
}

interface CodeViewerProps {
  file: FileItem | null;
}

export const CodeViewer: React.FC<CodeViewerProps> = ({ file }) => {
  const [copied, setCopied] = React.useState(false);

  useEffect(() => {
    if (file) {
      Prism.highlightAll();
    }
  }, [file]);

  if (!file) {
    return (
      <div className="code-viewer empty">
        <div className="empty-state">
          <div className="empty-icon">📁</div>
          <h2>Select a file to view</h2>
          <p>Browse the file tree on the left to get started</p>
        </div>
      </div>
    );
  }

  const handleCopy = () => {
    navigator.clipboard.writeText(file.content);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const gitHubUrl = `https://github.com/YOUR_USERNAME/devops-playbook/blob/main/${file.path}`;

  return (
    <div className="code-viewer">
      <div className="code-header">
        <div className="file-info">
          <span className="file-path">{file.path}</span>
          <span className="file-size">{(file.size / 1024).toFixed(1)} KB</span>
        </div>
        <div className="code-actions">
          <button
            className={`action-btn ${copied ? 'copied' : ''}`}
            onClick={handleCopy}
            title="Copy to clipboard"
          >
            <Copy size={16} />
            {copied ? 'Copied!' : 'Copy'}
          </button>
          <a
            href={gitHubUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="action-btn"
            title="View on GitHub"
          >
            <ExternalLink size={16} />
            GitHub
          </a>
        </div>
      </div>

      <div className="code-content">
        <pre>
          <code className={`language-${file.language}`}>
            {file.content}
          </code>
        </pre>
      </div>
    </div>
  );
};

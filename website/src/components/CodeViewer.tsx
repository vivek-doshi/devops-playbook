// Note 1: Imports make dependencies explicit, which keeps module boundaries clear and simplifies maintenance.
import React, { useEffect } from 'react';
import { Copy, ExternalLink } from 'lucide-react';
import Prism from 'prismjs';
// Note 2: Imports make dependencies explicit, which keeps module boundaries clear and simplifies maintenance.
import 'prismjs/components/prism-bash';
import 'prismjs/components/prism-yaml';
import 'prismjs/components/prism-json';
// Note 3: Imports make dependencies explicit, which keeps module boundaries clear and simplifies maintenance.
import 'prismjs/components/prism-python';
import 'prismjs/components/prism-typescript';
import 'prismjs/components/prism-javascript';
// Note 4: Imports make dependencies explicit, which keeps module boundaries clear and simplifies maintenance.
import 'prismjs/components/prism-java';
import 'prismjs/components/prism-docker';
import 'prismjs/components/prism-go';
// Note 5: Imports make dependencies explicit, which keeps module boundaries clear and simplifies maintenance.
import 'prismjs/components/prism-ruby';
import './CodeViewer.css';

interface FileItem {
  // Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  path: string;
  category: string;
  language: string;
  // Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  size: number;
  content: string;
  fileName: string;
// Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

interface CodeViewerProps {
  file: FileItem | null;
// Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

export const CodeViewer: React.FC<CodeViewerProps> = ({ file }) => {
  const [copied, setCopied] = React.useState(false);

  // Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  useEffect(() => {
    if (file) {
      Prism.highlightAll();
    // Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    }
  }, [file]);

  if (!file) {
    // Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    return (
      <div className="code-viewer empty">
        <div className="empty-state">
          // Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
          <div className="empty-icon">📁</div>
          <h2>Select a file to view</h2>
          <p>Browse the file tree on the left to get started</p>
        // Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
        </div>
      </div>
    );
  // Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }

  const handleCopy = () => {
    navigator.clipboard.writeText(file.content);
    // Note 16: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  // Note 17: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  const gitHubUrl = `https://github.com/vivek-doshi/devops-playbook/blob/main/${file.path}`;

  return (
    <div className="code-viewer">
      // Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      <div className="code-header">
        <div className="file-info">
          <span className="file-path">{file.path}</span>
          // Note 19: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
          <span className="file-size">{(file.size / 1024).toFixed(1)} KB</span>
        </div>
        <div className="code-actions">
          // Note 20: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
          <button
            className={`action-btn ${copied ? 'copied' : ''}`}
            onClick={handleCopy}
            // Note 21: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
            title="Copy to clipboard"
          >
            <Copy size={16} />
            // Note 22: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
            {copied ? 'Copied!' : 'Copy'}
          </button>
          <a
            // Note 23: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
            href={gitHubUrl}
            target="_blank"
            rel="noopener noreferrer"
            // Note 24: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
            className="action-btn"
            title="View on GitHub"
          >
            // Note 25: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
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

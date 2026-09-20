import React, { useEffect } from 'react';
import { Copy, Download, ExternalLink, Info, Tag, Wrench, FileText, Shield, Link, FileSearch } from 'lucide-react';
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
import 'prismjs/components/prism-hcl';
import 'prismjs/components/prism-powershell';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
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
  files: FileItem[];
  onFileSelect: (file: FileItem) => void;
}

const REPO_URL = 'https://github.com/vivek-doshi/devops-playbook';

function resolveRelativePath(currentFilePath: string, href: string): string {
  // Strip leading ./
  const cleaned = href.replace(/^\.\//,'');
  const currentDir = currentFilePath.split('/').slice(0, -1);
  const parts = [...currentDir];
  for (const part of cleaned.split('/')) {
    if (part === '..') parts.pop();
    else if (part !== '.') parts.push(part);
  }
  return parts.join('/');
}

function normalizeLocalPath(currentFilePath: string, href: string): string {
  const withoutHash = href.split('#')[0];
  const withoutQuery = withoutHash.split('?')[0];

  if (withoutQuery.startsWith('/')) {
    return withoutQuery.replace(/^\/+/, '');
  }

  return resolveRelativePath(currentFilePath, withoutQuery);
}

function findFileTarget(files: FileItem[], resolvedPath: string): FileItem | null {
  const normalized = resolvedPath.replace(/\/+/g, '/').replace(/^\//, '');
  const trimmed = normalized.replace(/\/$/, '');
  const candidates = [
    normalized,
    trimmed,
    `${trimmed}.md`,
    `${trimmed}/README.md`
  ].filter(Boolean);

  for (const candidate of candidates) {
    const found = files.find((item) => item.path === candidate);
    if (found) {
      return found;
    }
  }

  return null;
}

function toGitHubPathUrl(resolvedPath: string): string {
  const normalized = resolvedPath.replace(/^\//, '').replace(/\/$/, '');
  const hasExtension = /\.[a-z0-9]+$/i.test(normalized);
  const mode = hasExtension ? 'blob' : 'tree';
  return `${REPO_URL}/${mode}/main/${normalized}`;
}

interface TemplateMetadata {
  template?: string;
  whenToUse?: string;
  prerequisites?: string;
  secretsNeeded?: string;
  whatToChange?: string;
  relatedFiles?: string;
  maturity?: string;
}

function parseMetadata(content: string): TemplateMetadata {
  const meta: TemplateMetadata = {};
  const lines = content.split('\n').slice(0, 25);
  for (const line of lines) {
    const trimmed = line.replace(/^[#\s*/-]+/, '').trim();
    if (trimmed.startsWith('TEMPLATE:')) meta.template = trimmed.slice(9).trim();
    else if (trimmed.startsWith('WHEN TO USE:')) meta.whenToUse = trimmed.slice(12).trim();
    else if (trimmed.startsWith('PREREQUISITES:')) meta.prerequisites = trimmed.slice(14).trim();
    else if (trimmed.startsWith('SECRETS NEEDED:')) meta.secretsNeeded = trimmed.slice(15).trim();
    else if (trimmed.startsWith('WHAT TO CHANGE:')) meta.whatToChange = trimmed.slice(15).trim();
    else if (trimmed.startsWith('RELATED FILES:')) meta.relatedFiles = trimmed.slice(14).trim();
    else if (trimmed.startsWith('MATURITY:')) meta.maturity = trimmed.slice(9).trim();
  }
  return meta;
}

const maturityColors: Record<string, string> = {
  stable: '#22c55e',
  beta: '#f59e0b',
  experimental: '#ef4444',
  draft: '#6b7280',
};

function MaturityBadge({ value }: { value: string }) {
  const key = value.toLowerCase();
  const color = maturityColors[key] ?? '#6b7280';
  return (
    <span className="maturity-badge" style={{ borderColor: color, color }}>
      {value}
    </span>
  );
}

export const CodeViewer: React.FC<CodeViewerProps> = ({ file, files, onFileSelect }) => {
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
          <div className="empty-icon">
            <FileSearch size={42} strokeWidth={1.8} />
          </div>
          <h2>Select a file to view</h2>
          <p>No file is selected. Choose an item from the tree on the left.</p>
        </div>
      </div>
    );
  }

  const handleCopy = () => {
    navigator.clipboard.writeText(file.content);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const gitHubUrl = `${REPO_URL}/blob/main/${file.path}`;
  const meta = parseMetadata(file.content);
  const hasMeta = Object.values(meta).some(Boolean);
  const lineCount = file.content.split('\n').length;

  return (
    <div className="code-viewer">
      <div className="code-header">
        <div className="file-info">
          <span className="file-path">{file.path}</span>
          <span className="file-size">{(file.size / 1024).toFixed(1)} KB</span>
        </div>
        <div className="code-actions">
          {file.language !== 'pdf' && (
            <button
              className={`action-btn ${copied ? 'copied' : ''}`}
              onClick={handleCopy}
              title="Copy to clipboard"
            >
              <Copy size={16} />
              {copied ? 'Copied!' : 'Copy'}
            </button>
          )}
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

      <div className="code-body">
        <div className="code-content">
          {file.language === 'pdf' ? (
            <div className="pdf-download-view">
              <div className="pdf-download-card">
                <div className="pdf-icon">📄</div>
                <h2 className="pdf-title">{file.fileName}</h2>
                <p className="pdf-meta">{(file.size / 1024).toFixed(0)} KB · PDF Document</p>
                <div className="pdf-actions">
                  <a
                    href={`${import.meta.env.BASE_URL}${file.path}`}
                    download={file.fileName}
                    className="pdf-btn pdf-btn-primary"
                  >
                    <Download size={16} />
                    Download PDF
                  </a>
                  <a
                    href={`${import.meta.env.BASE_URL}${file.path}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="pdf-btn pdf-btn-secondary"
                  >
                    <ExternalLink size={16} />
                    Open in Browser
                  </a>
                </div>
              </div>
            </div>
          ) : file.language === 'markdown' ? (
            <div className="markdown-body">
              <ReactMarkdown
                remarkPlugins={[remarkGfm]}
                components={{
                  a: ({ href, children, ...props }) => {
                    if (!href) {
                      return <a {...props}>{children}</a>;
                    }

                    const isExternal =
                      href.startsWith('http://') ||
                      href.startsWith('https://') ||
                      href.startsWith('mailto:');

                    if (isExternal || href.startsWith('#')) {
                      return (
                        <a href={href} target="_blank" rel="noopener noreferrer" {...props}>
                          {children}
                        </a>
                      );
                    }

                    const resolved = normalizeLocalPath(file.path, href);

                    if (resolved === 'website') {
                      return (
                        <a href={import.meta.env.BASE_URL} {...props}>
                          {children}
                        </a>
                      );
                    }

                    const target = findFileTarget(files, resolved);
                    if (target) {
                      return (
                        <a
                          {...props}
                          href="#"
                          title={target.path}
                          onClick={(e) => {
                            e.preventDefault();
                            onFileSelect(target);
                          }}
                        >
                          {children}
                        </a>
                      );
                    }

                    return (
                      <a
                        href={toGitHubPathUrl(resolved)}
                        target="_blank"
                        rel="noopener noreferrer"
                        title={resolved}
                        {...props}
                      >
                        {children}
                      </a>
                    );
                  },
                }}
              >
                {file.content}
              </ReactMarkdown>
            </div>
          ) : file.language === 'svg' ? (
            <div className="svg-viewer">
              <img
                src={`data:image/svg+xml;charset=utf-8,${encodeURIComponent(file.content)}`}
                alt={file.fileName}
              />
            </div>
          ) : (
            <pre>
              <code className={`language-${file.language}`}>
                {file.content}
              </code>
            </pre>
          )}
        </div>

        <aside className="info-panel">
          <div className="info-panel-inner">
            <div className="info-panel-section info-stats">
              <div className="info-stat">
                <span className="info-stat-value">{lineCount}</span>
                <span className="info-stat-label">lines</span>
              </div>
              <div className="info-stat">
                <span className="info-stat-value">{(file.size / 1024).toFixed(1)}</span>
                <span className="info-stat-label">KB</span>
              </div>
              <div className="info-stat">
                <span className="info-stat-value lang-chip">{file.language}</span>
                <span className="info-stat-label">language</span>
              </div>
            </div>

            {hasMeta ? (
              <>
                {meta.template && (
                  <div className="info-panel-section">
                    <div className="info-panel-label"><Tag size={13} /> Template</div>
                    <p className="info-panel-value">{meta.template}</p>
                  </div>
                )}
                {meta.maturity && (
                  <div className="info-panel-section">
                    <div className="info-panel-label"><Info size={13} /> Maturity</div>
                    <MaturityBadge value={meta.maturity} />
                  </div>
                )}
                {meta.whenToUse && (
                  <div className="info-panel-section">
                    <div className="info-panel-label"><FileText size={13} /> When to use</div>
                    <p className="info-panel-value">{meta.whenToUse}</p>
                  </div>
                )}
                {meta.prerequisites && (
                  <div className="info-panel-section">
                    <div className="info-panel-label"><Wrench size={13} /> Prerequisites</div>
                    <p className="info-panel-value">{meta.prerequisites}</p>
                  </div>
                )}
                {meta.whatToChange && (
                  <div className="info-panel-section">
                    <div className="info-panel-label"><Wrench size={13} /> What to change</div>
                    <p className="info-panel-value">{meta.whatToChange}</p>
                  </div>
                )}
                {meta.secretsNeeded && meta.secretsNeeded.toLowerCase() !== 'none' && (
                  <div className="info-panel-section">
                    <div className="info-panel-label"><Shield size={13} /> Secrets needed</div>
                    <p className="info-panel-value">{meta.secretsNeeded}</p>
                  </div>
                )}
                {meta.relatedFiles && (
                  <div className="info-panel-section">
                    <div className="info-panel-label"><Link size={13} /> Related files</div>
                    <p className="info-panel-value info-mono">{meta.relatedFiles}</p>
                  </div>
                )}
              </>
            ) : (
              <div className="info-panel-section info-empty">
                <p>No template metadata found in this file.</p>
              </div>
            )}
          </div>
        </aside>
      </div>
    </div>
  );
};

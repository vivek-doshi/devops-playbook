import React, { useEffect, useMemo, useState } from 'react';
import {
  ChevronDown,
  ChevronRight,
  Search,
  FoldHorizontal,
  UnfoldHorizontal,
  Archive,
  BookMarked,
  Rocket,
  Zap,
  ShieldCheck,
  Layers,
  Box,
  FileText,
  TrendingDown,
  Monitor,
  Bell,
  Activity,
  Scale,
  CheckCircle,
  Terminal,
  Lock,
  Key,
  Cloud,
  Globe,
  Folder,
  FolderOpen,
} from 'lucide-react';
import './Sidebar.css';

interface FileItem {
  path: string;
  category: string;
  language: string;
  size: number;
  content: string;
  fileName: string;
}

interface SidebarProps {
  files: FileItem[];
  selectedFile: FileItem | null;
  onFileSelect: (file: FileItem) => void;
  searchQuery: string;
  onSearchChange: (query: string) => void;
}

interface FolderConfig {
  icon: React.ReactNode;
  color: string;
  bg: string;
}

const FOLDER_CONFIG: Record<string, FolderConfig> = {
  backup:        { icon: <Archive size={14} />,     color: '#f97316', bg: 'rgba(249,115,22,0.14)' },
  catalog:       { icon: <BookMarked size={14} />,  color: '#a855f7', bg: 'rgba(168,85,247,0.14)' },
  cd:            { icon: <Rocket size={14} />,      color: '#22c55e', bg: 'rgba(34,197,94,0.14)' },
  ci:            { icon: <Zap size={14} />,         color: '#eab308', bg: 'rgba(234,179,8,0.14)' },
  'ci-security': { icon: <ShieldCheck size={14} />, color: '#ef4444', bg: 'rgba(239,68,68,0.14)' },
  compose:       { icon: <Layers size={14} />,      color: '#3b82f6', bg: 'rgba(59,130,246,0.14)' },
  docker:        { icon: <Box size={14} />,         color: '#06b6d4', bg: 'rgba(6,182,212,0.14)' },
  docs:          { icon: <FileText size={14} />,    color: '#14b8a6', bg: 'rgba(20,184,166,0.14)' },
  finops:        { icon: <TrendingDown size={14} />,color: '#f59e0b', bg: 'rgba(245,158,11,0.14)' },
  'local-dev':   { icon: <Monitor size={14} />,     color: '#0ea5e9', bg: 'rgba(14,165,233,0.14)' },
  notifications: { icon: <Bell size={14} />,        color: '#f97316', bg: 'rgba(249,115,22,0.14)' },
  observability: { icon: <Activity size={14} />,    color: '#8b5cf6', bg: 'rgba(139,92,246,0.14)' },
  policy:        { icon: <Scale size={14} />,       color: '#6366f1', bg: 'rgba(99,102,241,0.14)' },
  quality:       { icon: <CheckCircle size={14} />, color: '#10b981', bg: 'rgba(16,185,129,0.14)' },
  scripts:       { icon: <Terminal size={14} />,    color: '#94a3b8', bg: 'rgba(148,163,184,0.14)' },
  secops:        { icon: <Lock size={14} />,        color: '#f43f5e', bg: 'rgba(244,63,94,0.14)' },
  secrets:       { icon: <Key size={14} />,         color: '#f59e0b', bg: 'rgba(245,158,11,0.14)' },
  terraform:     { icon: <Cloud size={14} />,       color: '#7c3aed', bg: 'rgba(124,58,237,0.14)' },
  website:       { icon: <Globe size={14} />,       color: '#0ea5e9', bg: 'rgba(14,165,233,0.14)' },
};

const DEFAULT_FOLDER_CONFIG: FolderConfig = {
  icon: <Folder size={14} />,
  color: '#94a3b8',
  bg: 'rgba(148,163,184,0.14)',
};

function getFolderConfig(name: string): FolderConfig {
  return FOLDER_CONFIG[name.toLowerCase()] ?? DEFAULT_FOLDER_CONFIG;
}

interface TreeNode {
  name: string;
  path: string;
  type: 'folder' | 'file';
  children: TreeNode[];
  file?: FileItem;
}

function createFolderNode(name: string, path: string): TreeNode {
  return { name, path, type: 'folder', children: [] };
}

function createFileNode(file: FileItem): TreeNode {
  return { name: file.fileName, path: file.path, type: 'file', children: [], file };
}

function sortTree(node: TreeNode): void {
  node.children.sort((a, b) => {
    if (a.type !== b.type) {
      return a.type === 'folder' ? -1 : 1;
    }
    return a.name.localeCompare(b.name);
  });

  node.children.forEach((child) => {
    if (child.type === 'folder') {
      sortTree(child);
    }
  });
}

function buildTree(files: FileItem[]): TreeNode {
  const root = createFolderNode('root', '');

  files.forEach((file) => {
    const parts = file.path.split('/').filter(Boolean);
    let current = root;

    for (let i = 0; i < parts.length - 1; i++) {
      const folderName = parts[i];
      const folderPath = parts.slice(0, i + 1).join('/');
      let folder = current.children.find(
        (child) => child.type === 'folder' && child.path === folderPath
      );

      if (!folder) {
        folder = createFolderNode(folderName, folderPath);
        current.children.push(folder);
      }

      current = folder;
    }

    current.children.push(createFileNode(file));
  });

  sortTree(root);
  return root;
}

function getFileCount(node: TreeNode): number {
  if (node.type === 'file') {
    return 1;
  }

  return node.children.reduce((sum, child) => sum + getFileCount(child), 0);
}

function getFolderPaths(node: TreeNode): string[] {
  if (node.type === 'file') {
    return [];
  }

  return [node.path, ...node.children.flatMap((child) => getFolderPaths(child))];
}

export const Sidebar: React.FC<SidebarProps> = ({
  files,
  selectedFile,
  onFileSelect,
  searchQuery,
  onSearchChange,
}) => {
  const [expandedFolders, setExpandedFolders] = useState<Set<string>>(new Set());

  const toggleFolder = (folder: string) => {
    const newExpanded = new Set(expandedFolders);
    if (newExpanded.has(folder)) {
      newExpanded.delete(folder);
    } else {
      newExpanded.add(folder);
    }
    setExpandedFolders(newExpanded);
  };

  const filteredFiles = useMemo(() => {
    const query = searchQuery.trim().toLowerCase();
    if (!query) {
      return files;
    }

    return files.filter(
      (item) =>
        item.path.toLowerCase().includes(query) ||
        item.fileName.toLowerCase().includes(query)
    );
  }, [files, searchQuery]);

  const tree = useMemo(() => buildTree(filteredFiles), [filteredFiles]);

  const allFolderPaths = useMemo(() => getFolderPaths(tree), [tree]);

  useEffect(() => {
    if (searchQuery.trim()) {
      setExpandedFolders(new Set(allFolderPaths));
    }
  }, [allFolderPaths, searchQuery]);

  const collapseAll = () => setExpandedFolders(new Set());
  const expandAll = () => setExpandedFolders(new Set(allFolderPaths));

  const renderNode = (node: TreeNode, depth: number): React.ReactNode => {
    if (node.type === 'file' && node.file) {
      return (
        <button
          key={node.path}
          className={`file-item ${selectedFile?.path === node.path ? 'active' : ''}`}
          onClick={() => onFileSelect(node.file as FileItem)}
          title={node.path}
          style={{ paddingLeft: `${28 + depth * 14}px` }}
        >
          <span className="file-name">{node.name}</span>
          <span className="file-lang">{node.file.language}</span>
        </button>
      );
    }

    const isExpanded = expandedFolders.has(node.path);
    const count = getFileCount(node);

    if (depth === 0) {
      const config = getFolderConfig(node.name);
      return (
        <div key={node.path} className="category">
          <button className="category-header" onClick={() => toggleFolder(node.path)}>
            <div
              className="category-icon"
              style={{ '--icon-color': config.color, '--icon-bg': config.bg } as React.CSSProperties}
            >
              {config.icon}
            </div>
            <span className="category-name">{node.name}</span>
            <span className="file-count">{count}</span>
            <span className="category-chevron">
              {isExpanded ? <ChevronDown size={14} /> : <ChevronRight size={14} />}
            </span>
          </button>
          {isExpanded && (
            <div className="category-children">
              {node.children.map((child) => renderNode(child, depth + 1))}
            </div>
          )}
        </div>
      );
    }

    return (
      <div key={node.path} className="category">
        <button
          className="folder-header"
          onClick={() => toggleFolder(node.path)}
          style={{ paddingLeft: `${14 + depth * 14}px` }}
        >
          <span className="subfolder-icon">
            {isExpanded ? <FolderOpen size={13} /> : <Folder size={13} />}
          </span>
          {isExpanded ? <ChevronDown size={13} /> : <ChevronRight size={13} />}
          <span className="folder-name">{node.name}</span>
          <span className="file-count">{count}</span>
        </button>
        {isExpanded && (
          <div>{node.children.map((child) => renderNode(child, depth + 1))}</div>
        )}
      </div>
    );
  };

  return (
    <div className="sidebar">
      <div className="sidebar-search-wrap">
        <div className="search-box">
          <Search size={15} />
          <input
            type="text"
            placeholder="Search templates..."
            value={searchQuery}
            onChange={(e) => onSearchChange(e.target.value)}
            className="search-input"
          />
        </div>
        <div className="tree-actions">
          <button className="tree-action-btn" type="button" onClick={collapseAll} title="Collapse all">
            <FoldHorizontal size={13} />
            <span>Collapse</span>
          </button>
          <button className="tree-action-btn" type="button" onClick={expandAll} title="Expand all">
            <UnfoldHorizontal size={13} />
            <span>Expand</span>
          </button>
        </div>
      </div>

      <div className="file-tree">
        {tree.children.map((node) => renderNode(node, 0))}
      </div>
    </div>
  );
};

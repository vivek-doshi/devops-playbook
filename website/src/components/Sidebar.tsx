import React, { useState, useMemo } from 'react';
import { ChevronDown, ChevronRight, Search } from 'lucide-react';
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
  theme: 'ocean' | 'midnight';
  onThemeChange: (theme: 'ocean' | 'midnight') => void;
}

interface TreeNode {
  name: string;
  path: string;
  type: 'folder' | 'file';
  children: TreeNode[];
  file?: FileItem;
}

function createFolderNode(name: string, path: string): TreeNode {
  return {
    name,
    path,
    type: 'folder',
    children: []
  };
}

function createFileNode(file: FileItem): TreeNode {
  return {
    name: file.fileName,
    path: file.path,
    type: 'file',
    children: [],
    file
  };
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

export const Sidebar: React.FC<SidebarProps> = ({
  files,
  selectedFile,
  onFileSelect,
  searchQuery,
  onSearchChange,
  theme,
  onThemeChange
}) => {
  const [expandedFolders, setExpandedFolders] = useState<Set<string>>(
    new Set(['cd', 'ci', 'docker', 'kubernetes'])
  );

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

  const renderNode = (node: TreeNode, depth: number): React.ReactNode => {
    if (node.type === 'file' && node.file) {
      return (
        <button
          key={node.path}
          className={`file-item ${selectedFile?.path === node.path ? 'active' : ''}`}
          onClick={() => onFileSelect(node.file as FileItem)}
          title={node.path}
          style={{ paddingLeft: `${24 + depth * 14}px` }}
        >
          <span className="file-name">{node.name}</span>
          <span className="file-lang">{node.file.language}</span>
        </button>
      );
    }

    const isExpanded = expandedFolders.has(node.path);
    const count = getFileCount(node);

    return (
      <div key={node.path} className="category">
        <button
          className={depth === 0 ? 'category-header' : 'folder-header'}
          onClick={() => toggleFolder(node.path)}
          style={depth > 0 ? { paddingLeft: `${12 + depth * 14}px` } : undefined}
        >
          {isExpanded ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
          <span className={depth === 0 ? 'category-name' : 'folder-name'}>{node.name}</span>
          <span className="file-count">{count}</span>
        </button>

        {isExpanded && <div>{node.children.map((child) => renderNode(child, depth + 1))}</div>}
      </div>
    );
  };

  return (
    <div className="sidebar">
      <div className="sidebar-header">
        <h1>devops-playbook</h1>
        <p className="subtitle">Code Template Browser</p>
        <div className="theme-switcher" role="group" aria-label="Theme selector">
          <button
            className={`theme-btn ${theme === 'ocean' ? 'active' : ''}`}
            onClick={() => onThemeChange('ocean')}
            type="button"
          >
            Ocean Ops
          </button>
          <button
            className={`theme-btn ${theme === 'midnight' ? 'active' : ''}`}
            onClick={() => onThemeChange('midnight')}
            type="button"
          >
            Midnight
          </button>
        </div>
      </div>

      <div className="search-box">
        <Search size={16} />
        <input
          type="text"
          placeholder="Search files..."
          value={searchQuery}
          onChange={(e) => onSearchChange(e.target.value)}
          className="search-input"
        />
      </div>

      <div className="file-tree">
        {tree.children.map((node) => renderNode(node, 0))}
      </div>
    </div>
  );
};

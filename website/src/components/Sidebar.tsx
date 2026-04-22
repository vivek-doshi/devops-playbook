// Note 1: Imports make dependencies explicit, which keeps module boundaries clear and simplifies maintenance.
import React, { useState, useMemo } from 'react';
import { ChevronDown, ChevronRight, Search } from 'lucide-react';
import './Sidebar.css';

// Note 2: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
interface FileItem {
  path: string;
  category: string;
  // Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  language: string;
  size: number;
  content: string;
  // Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  fileName: string;
}

interface SidebarProps {
  // Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  files: FileItem[];
  selectedFile: FileItem | null;
  onFileSelect: (file: FileItem) => void;
  // Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  searchQuery: string;
  onSearchChange: (query: string) => void;
  theme: 'ocean' | 'paper';
  // Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  onThemeChange: (theme: 'ocean' | 'paper') => void;
}

interface TreeNode {
  // Note 8: Resource identity and metadata drive automation, selectors, and operational traceability.
  name: string;
  path: string;
  type: 'folder' | 'file';
  // Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  children: TreeNode[];
  file?: FileItem;
}

// Note 10: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
function createFolderNode(name: string, path: string): TreeNode {
  return {
    name,
    // Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    path,
    type: 'folder',
    children: []
  // Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  };
}

function createFileNode(file: FileItem): TreeNode {
  // Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  return {
    name: file.fileName,
    path: file.path,
    // Note 14: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
    type: 'file',
    children: [],
    file
  // Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  };
}

function sortTree(node: TreeNode): void {
  // Note 16: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  node.children.sort((a, b) => {
    if (a.type !== b.type) {
      return a.type === 'folder' ? -1 : 1;
    // Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    }
    return a.name.localeCompare(b.name);
  });

  // Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  node.children.forEach((child) => {
    if (child.type === 'folder') {
      sortTree(child);
    // Note 19: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    }
  });
}

// Note 20: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
function buildTree(files: FileItem[]): TreeNode {
  const root = createFolderNode('root', '');

  files.forEach((file) => {
    // Note 21: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
    const parts = file.path.split('/').filter(Boolean);
    let current = root;

    for (let i = 0; i < parts.length - 1; i++) {
      // Note 22: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
      const folderName = parts[i];
      const folderPath = parts.slice(0, i + 1).join('/');
      let folder = current.children.find(
        // Note 23: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
        (child) => child.type === 'folder' && child.path === folderPath
      );

      if (!folder) {
        // Note 24: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
        folder = createFolderNode(folderName, folderPath);
        current.children.push(folder);
      }

      // Note 25: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      current = folder;
    }

    current.children.push(createFileNode(file));
  // Note 26: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  });

  sortTree(root);
  return root;
// Note 27: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

function getFileCount(node: TreeNode): number {
  if (node.type === 'file') {
    // Note 28: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    return 1;
  }

  return node.children.reduce((sum, child) => sum + getFileCount(child), 0);
// Note 29: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

export const Sidebar: React.FC<SidebarProps> = ({
  files,
  // Note 30: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  selectedFile,
  onFileSelect,
  searchQuery,
  // Note 31: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  onSearchChange,
  theme,
  onThemeChange
// Note 32: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}) => {
  const [expandedFolders, setExpandedFolders] = useState<Set<string>>(
    new Set(['cd', 'ci', 'docker', 'kubernetes'])
  // Note 33: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  );

  const toggleFolder = (folder: string) => {
    const newExpanded = new Set(expandedFolders);
    // Note 34: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting.
    if (newExpanded.has(folder)) {
      newExpanded.delete(folder);
    } else {
      // Note 35: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      newExpanded.add(folder);
    }
    setExpandedFolders(newExpanded);
  // Note 36: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  };

  const filteredFiles = useMemo(() => {
    const query = searchQuery.trim().toLowerCase();
    // Note 37: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting.
    if (!query) {
      return files;
    }

    // Note 38: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    return files.filter(
      (item) =>
        item.path.toLowerCase().includes(query) ||
        // Note 39: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
        item.fileName.toLowerCase().includes(query)
    );
  }, [files, searchQuery]);

  // Note 40: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  const tree = useMemo(() => buildTree(filteredFiles), [filteredFiles]);

  const renderNode = (node: TreeNode, depth: number): React.ReactNode => {
    if (node.type === 'file' && node.file) {
      // Note 41: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      return (
        <button
          key={node.path}
          // Note 42: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
          className={`file-item ${selectedFile?.path === node.path ? 'active' : ''}`}
          onClick={() => onFileSelect(node.file as FileItem)}
          title={node.path}
          // Note 43: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
          style={{ paddingLeft: `${24 + depth * 14}px` }}
        >
          <span className="file-name">{node.name}</span>
          // Note 44: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
          <span className="file-lang">{node.file.language}</span>
        </button>
      );
    // Note 45: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    }

    const isExpanded = expandedFolders.has(node.path);
    const count = getFileCount(node);

    // Note 46: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    return (
      <div key={node.path} className="category">
        <button
          // Note 47: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
          className={depth === 0 ? 'category-header' : 'folder-header'}
          onClick={() => toggleFolder(node.path)}
          style={depth > 0 ? { paddingLeft: `${12 + depth * 14}px` } : undefined}
        // Note 48: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
        >
          {isExpanded ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
          <span className={depth === 0 ? 'category-name' : 'folder-name'}>{node.name}</span>
          // Note 49: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
          <span className="file-count">{count}</span>
        </button>

        {isExpanded && <div>{node.children.map((child) => renderNode(child, depth + 1))}</div>}
      // Note 50: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      </div>
    );
  };

  // Note 51: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  return (
    <div className="sidebar">
      <div className="sidebar-header">
        // Note 52: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
        <h1>devops-playbook</h1>
        <p className="subtitle">Code Template Browser</p>
        <div className="theme-switcher" role="group" aria-label="Theme selector">
          // Note 53: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
          <button
            className={`theme-btn ${theme === 'ocean' ? 'active' : ''}`}
            onClick={() => onThemeChange('ocean')}
            // Note 54: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
            type="button"
          >
            Ocean Ops
          // Note 55: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
          </button>
          <button
            className={`theme-btn ${theme === 'paper' ? 'active' : ''}`}
            onClick={() => onThemeChange('paper')}
            type="button"
          >
            Paper Terminal
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

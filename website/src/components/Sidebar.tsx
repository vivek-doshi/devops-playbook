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
}

export const Sidebar: React.FC<SidebarProps> = ({
  files,
  selectedFile,
  onFileSelect,
  searchQuery,
  onSearchChange
}) => {
  const [expandedFolders, setExpandedFolders] = useState<Set<string>>(new Set(['docker', 'ci', 'kubernetes']));

  const toggleFolder = (folder: string) => {
    const newExpanded = new Set(expandedFolders);
    if (newExpanded.has(folder)) {
      newExpanded.delete(folder);
    } else {
      newExpanded.add(folder);
    }
    setExpandedFolders(newExpanded);
  };

  // Group files by category and subcategory
  const groupedFiles = useMemo(() => {
    const groups: Record<string, Record<string, FileItem[]>> = {};

    files.forEach(file => {
      if (!groups[file.category]) {
        groups[file.category] = {};
      }

      const parts = file.path.split('/');
      const subCategory = parts.length > 1 ? parts[1] : 'root';

      if (!groups[file.category][subCategory]) {
        groups[file.category][subCategory] = [];
      }

      groups[file.category][subCategory].push(file);
    });

    return groups;
  }, [files]);

  // Filter files based on search
  const filteredGroups = useMemo(() => {
    if (!searchQuery.trim()) return groupedFiles;

    const query = searchQuery.toLowerCase();
    const filtered: typeof groupedFiles = {};

    Object.entries(groupedFiles).forEach(([category, subcats]) => {
      const filteredSubcats: Record<string, FileItem[]> = {};

      Object.entries(subcats).forEach(([subcat, items]) => {
        const matchedItems = items.filter(item =>
          item.path.toLowerCase().includes(query) ||
          item.fileName.toLowerCase().includes(query)
        );

        if (matchedItems.length > 0) {
          filteredSubcats[subcat] = matchedItems;
        }
      });

      if (Object.keys(filteredSubcats).length > 0) {
        filtered[category] = filteredSubcats;
      }
    });

    return filtered;
  }, [groupedFiles, searchQuery]);

  return (
    <div className="sidebar">
      <div className="sidebar-header">
        <h1>CI/CD Reference</h1>
        <p className="subtitle">Code Template Browser</p>
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
        {Object.entries(filteredGroups).map(([category, subcats]) => (
          <div key={category} className="category">
            <button
              className="category-header"
              onClick={() => toggleFolder(category)}
            >
              {expandedFolders.has(category) ? (
                <ChevronDown size={16} />
              ) : (
                <ChevronRight size={16} />
              )}
              <span className="category-name">{category}</span>
              <span className="file-count">
                {Object.values(subcats).reduce((sum, items) => sum + items.length, 0)}
              </span>
            </button>

            {expandedFolders.has(category) && (
              <div className="subcategories">
                {Object.entries(subcats).map(([subcat, items]) => (
                  <div key={subcat} className="subcategory">
                    <div className="subcat-name">{subcat}</div>
                    <div className="file-list">
                      {items.map((file) => (
                        <button
                          key={file.path}
                          className={`file-item ${selectedFile?.path === file.path ? 'active' : ''}`}
                          onClick={() => onFileSelect(file)}
                          title={file.path}
                        >
                          <span className="file-name">{file.fileName}</span>
                          <span className="file-lang">{file.language}</span>
                        </button>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

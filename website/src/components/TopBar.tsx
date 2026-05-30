import React, { useMemo, useEffect, useState } from 'react';
import { Shuffle, Sun, Moon, ExternalLink, PanelLeftOpen, PanelLeftClose } from 'lucide-react';
import './TopBar.css';

interface FileItem {
  path: string;
  category: string;
  language: string;
  size: number;
  content: string;
  fileName: string;
}

interface TopBarProps {
  files: FileItem[];
  theme: 'runbook-dawn' | 'terminal-dusk';
  onThemeChange: (theme: 'runbook-dawn' | 'terminal-dusk') => void;
  onRandomFile: () => void;
  showSidebarToggle: boolean;
  isSidebarOpen: boolean;
  onSidebarToggle: () => void;
}

function useCountUp(target: number, duration = 900) {
  const [count, setCount] = useState(0);
  useEffect(() => {
    if (target === 0) { setCount(0); return; }
    let start: number | null = null;
    let raf: number;
    const step = (ts: number) => {
      if (!start) start = ts;
      const progress = Math.min((ts - start) / duration, 1);
      setCount(Math.round(progress * target));
      if (progress < 1) raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [target, duration]);
  return count;
}

export const TopBar: React.FC<TopBarProps> = ({
  files,
  theme,
  onThemeChange,
  onRandomFile,
  showSidebarToggle,
  isSidebarOpen,
  onSidebarToggle,
}) => {
  const stats = useMemo(() => {
    const categories = new Set(files.map((f) => f.path.split('/')[0])).size;
    const languages = new Set(files.map((f) => f.language)).size;
    return { templates: files.length, categories, languages };
  }, [files]);

  const templatesCount = useCountUp(stats.templates);
  const categoriesCount = useCountUp(stats.categories);
  const languagesCount = useCountUp(stats.languages);

  return (
    <header className="topbar">
      {/* Brand */}
      <div className="topbar-brand">
        <div className="topbar-icon-wrap">
          <img
            className="topbar-icon"
            src={`${import.meta.env.BASE_URL}devops.svg`}
            alt="devops playbook icon"
          />
          <div className="topbar-icon-glow" />
        </div>
        <div className="topbar-title-group">
          <span className="topbar-title">DevOps Playbook</span>
          <span className="topbar-badge">TEMPLATE LAB</span>
        </div>
      </div>

      {/* Stats */}
      <div className="topbar-stats">
        <div className="stat-chip">
          <span className="stat-num">{templatesCount}</span>
          <span className="stat-lbl">Templates</span>
        </div>
        <div className="stat-sep" />
        <div className="stat-chip">
          <span className="stat-num">{categoriesCount}</span>
          <span className="stat-lbl">Categories</span>
        </div>
        <div className="stat-sep" />
        <div className="stat-chip">
          <span className="stat-num">{languagesCount}</span>
          <span className="stat-lbl">Languages</span>
        </div>
      </div>

      {/* Actions */}
      <div className="topbar-actions">
        {showSidebarToggle && (
          <button
            className="topbar-btn topbar-btn--menu"
            onClick={onSidebarToggle}
            title={isSidebarOpen ? 'Hide file list' : 'Show file list'}
            type="button"
          >
            {isSidebarOpen ? <PanelLeftClose size={14} /> : <PanelLeftOpen size={14} />}
            <span>{isSidebarOpen ? 'Hide Files' : 'Show Files'}</span>
          </button>
        )}

        <button
          className="topbar-btn topbar-btn--random"
          onClick={onRandomFile}
          title="Open random template"
          type="button"
        >
          <Shuffle size={14} />
          <span>Random</span>
        </button>

        <a
          href="https://vivek-doshi.github.io/mlops-playbook/"
          target="_blank"
          rel="noopener noreferrer"
          className="topbar-btn topbar-btn--mlops"
          title="MLOps Playbook Template Lab"
        >
          <ExternalLink size={14} />
          <span>MLOps Playbook</span>
        </a>

        <button
          className="topbar-btn topbar-btn--theme"
          onClick={() =>
            onThemeChange(theme === 'runbook-dawn' ? 'terminal-dusk' : 'runbook-dawn')
          }
          title={`Switch to ${theme === 'runbook-dawn' ? 'Terminal Dusk' : 'Runbook Dawn'}`}
          type="button"
        >
          <span className="theme-icon-wrap">
            {theme === 'runbook-dawn' ? <Moon size={14} /> : <Sun size={14} />}
          </span>
          <span>{theme === 'runbook-dawn' ? 'Runbook Dawn' : 'Terminal Dusk'}</span>
        </button>
      </div>
    </header>
  );
};

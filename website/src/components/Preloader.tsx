import { useEffect, useState } from 'react';
import './Preloader.css';

const STAGES = [
  { id: 'source', label: 'Source' },
  { id: 'build',  label: 'Build'  },
  { id: 'test',   label: 'Test'   },
  { id: 'scan',   label: 'Scan'   },
  { id: 'deploy', label: 'Deploy' },
  { id: 'server', label: 'Server' },
];

const STATUS_LINES = [
  'Cloning repository\u2026',
  'Compiling modules\u2026',
  'Running test suite\u2026',
  'Scanning for CVEs\u2026',
  'Deploying artefacts\u2026',
  'Booting server\u2026',
];

const PACKETS = 3;
const STAGE_MS = 460;
const EXIT_MS  = 650;

export function Preloader({ theme, onDone }: { theme?: string; onDone?: () => void }) {
  const [activeStage, setActiveStage] = useState(0);
  const [done,        setDone]        = useState(false);
  const [exiting,     setExiting]     = useState(false);
  const [statusText,  setStatusText]  = useState(STATUS_LINES[0]);

  useEffect(() => {
    if (activeStage >= STAGES.length) {
      setDone(true);
      setExiting(true);
      const t = setTimeout(() => onDone?.(), EXIT_MS);
      return () => clearTimeout(t);
    }
    setStatusText(STATUS_LINES[activeStage]);
    const t = setTimeout(() => setActiveStage((s) => s + 1), STAGE_MS);
    return () => clearTimeout(t);
  }, [activeStage, onDone]);

  const isDusk = theme === 'terminal-dusk';

  return (
    <div
      className={[
        'preloader',
        isDusk  ? 'preloader--dusk'    : '',
        exiting ? 'preloader--exiting' : '',
      ].filter(Boolean).join(' ')}
    >
      <div className="pl-rings">
        <span /><span /><span />
      </div>

      <div className="pl-brand">
        <span className="pl-brand-hex">{'\u2b21'}</span>
        <span className="pl-brand-text">DevOps Playbook</span>
      </div>

      <div className="pl-pipeline">
        {STAGES.map((stage, idx) => {
          const isActive   = idx === activeStage;
          const isComplete = idx < activeStage;
          const isLast     = idx === STAGES.length - 1;
          const pipeActive = idx < activeStage;

          return (
            <div key={stage.id} className="pl-row-unit">
              <div className="pl-stage-wrap">
                <div
                  className={[
                    'pl-node',
                    isActive   ? 'pl-node--active'  : '',
                    isComplete ? 'pl-node--complete' : '',
                    isLast     ? 'pl-node--server'   : '',
                  ].filter(Boolean).join(' ')}
                >
                  {isComplete ? (
                    <svg viewBox="0 0 16 16" fill="none" className="pl-check">
                      <polyline
                        points="3,8 7,12 13,4"
                        strokeWidth="2.2"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        stroke="currentColor"
                      />
                    </svg>
                  ) : isLast ? (
                    <svg viewBox="0 0 24 24" fill="none" className="pl-server-icon">
                      <rect x="3" y="3"  width="18" height="7"  rx="2" stroke="currentColor" strokeWidth="1.6" />
                      <rect x="3" y="13" width="18" height="7"  rx="2" stroke="currentColor" strokeWidth="1.6" />
                      <circle cx="7"  cy="6.5"  r="1.1" fill="currentColor" />
                      <circle cx="7"  cy="16.5" r="1.1" fill="currentColor" />
                      <line x1="11" y1="6.5"  x2="17" y2="6.5"  stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
                      <line x1="11" y1="16.5" x2="17" y2="16.5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
                    </svg>
                  ) : (
                    <span className="pl-node-idx">{idx + 1}</span>
                  )}
                </div>
                <span className="pl-node-label">{stage.label}</span>
              </div>

              {!isLast && (
                <div className={`pl-pipe${pipeActive ? ' pl-pipe--active' : ''}`}>
                  {Array.from({ length: PACKETS }).map((_, pi) => (
                    <span
                      key={pi}
                      className={`pl-packet${pipeActive ? ' pl-packet--go' : ''}`}
                      style={{ animationDelay: `${pi * 0.18}s` }}
                    />
                  ))}
                </div>
              )}
            </div>
          );
        })}
      </div>

      <p className={`pl-status${done ? ' pl-status--done' : ''}`}>
        {done ? '\u2713 Ready' : statusText}
      </p>

      <div className="pl-bar-wrap">
        <div
          className="pl-bar-fill"
          style={{ width: `${Math.min((activeStage / STAGES.length) * 100, 100)}%` }}
        />
      </div>
    </div>
  );
}

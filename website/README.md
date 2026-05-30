# DevOps Playbook — Code Browser

An interactive browser for exploring the DevOps Playbook templates. Browse, search, and copy ready-to-use snippets for Docker, Kubernetes, CI/CD pipelines, Terraform, observability, and more — all served as a static site from GitHub Pages.

The UI ships with two named themes:

| Theme | Mode | Description |
|---|---|---|
| `Runbook Dawn` | Light | Warm, document-first palette |
| `Terminal Dusk` | Dark | High-contrast, tuned for code review |

## Prerequisites

- [Node.js](https://nodejs.org/) 18+
- npm 9+

## Quick Start

```bash
cd website
npm install
npm run dev      # Dev server at http://localhost:3000
```

The `dev` command runs `npm run index` first, which scans the repository and writes `public/index.json`, then starts the Vite dev server.

To produce a production build:

```bash
npm run build    # Outputs to dist/
```

## Project Structure

```
website/
├── public/
│   └── index.json          # Generated file index (do not edit manually)
├── scripts/
│   └── generate-index.js   # Repo scanner — produces public/index.json
├── src/
│   ├── components/
│   │   ├── Sidebar.tsx      # Category / file navigation
│   │   ├── CodeViewer.tsx   # Syntax-highlighted viewer + copy button
│   │   ├── Sidebar.css
│   │   └── CodeViewer.css
│   ├── hooks/
│   ├── utils/
│   ├── App.tsx
│   └── main.tsx
├── index.html
├── vite.config.ts
└── package.json
```

## How It Works

**Index generation** (`scripts/generate-index.js`):

- Recursively scans repo directories (skips `node_modules`, `.git`, `website`, `dist`)
- Skips files larger than 50 KB
- Extracts content, language, and category metadata
- Writes `public/index.json` consumed by the React app at runtime

**Frontend**:

- **Sidebar** — hierarchical browse: category → subcategory → file
- **Search** — full-text search across all indexed files
- **Viewer** — Prism.js syntax highlighting with a one-click copy button
- **GitHub link** — jumps to the source file in the repository

## Deployment

The site deploys automatically to GitHub Pages on every push to `main` via the included GitHub Actions workflow. The workflow:

1. Runs `npm run index` to regenerate the file index
2. Builds the React app with Vite
3. Publishes the `dist/` output to GitHub Pages

### First-time setup

1. Go to **Settings → Pages** in your repository.
2. Set **Source** to **GitHub Actions**.
3. Push to `main` — the workflow handles the rest.

After the first successful deployment your site is available at:

```
https://<YOUR_USERNAME>.github.io/devops-playbook/
```

> [!NOTE]
> The `base` path in `vite.config.ts` must match your repository name exactly.

## Configuration

### Update the repository base URL

`vite.config.ts`:

```typescript
base: '/devops-playbook/',  // Change to your repo name
```

`src/components/CodeViewer.tsx`:

```typescript
const gitHubUrl = `https://github.com/<YOUR_USERNAME>/devops-playbook/blob/main/${file.path}`;
```

### Exclude or include directories

Edit `EXCLUDE_PATTERNS` in `scripts/generate-index.js`:

```javascript
const EXCLUDE_PATTERNS = [
  'node_modules',
  '.git',
  'website',   // prevents the site from indexing itself
  // add paths to exclude
];
```

### Change the file size limit

Files larger than 50 KB are skipped by default. Adjust in `scripts/generate-index.js`:

```javascript
const maxSize = 1024 * 50;  // bytes — increase or decrease as needed
```

### Add syntax highlighting for a new language

1. Import the Prism language component in `src/components/CodeViewer.tsx`:

   ```typescript
   import 'prismjs/components/prism-<language>';
   ```

2. Add the file extension mapping in `scripts/generate-index.js`.

### Customise the visual theme

| File | Controls |
|---|---|
| `src/components/Sidebar.css` | Left navigation |
| `src/components/CodeViewer.css` | Code panel |
| `src/App.css` | Overall layout |
| `index.html` | `theme-color` meta (browser chrome), page title, OG tags |

## Adding Content

Update any file under the repo's top-level directories (`docker/`, `ci/`, `cd/`, etc.) and push to `main`. The GitHub Actions workflow detects the change, regenerates the index, rebuilds, and redeploys automatically.

```bash
git add docker/node/Dockerfile.production
git commit -m "chore: add production Node.js Dockerfile"
git push origin main
```

## Troubleshooting

> [!TIP]
> Run `npm run index` locally and inspect `public/index.json` to verify files are being picked up before investigating a deployment issue.

| Symptom | Likely cause | Fix |
|---|---|---|
| Blank page after deploy | Wrong base path | Verify `base` in `vite.config.ts` matches repo name |
| Files not appearing | Skipped by indexer | Check file size (< 50 KB) and extension support |
| Search not working | Stale `index.json` | Re-run `npm run index`; clear browser cache |

## Security

The site is fully static — no backend, no API keys, no credentials. All content is served from GitHub Pages and the repository is the source of truth.

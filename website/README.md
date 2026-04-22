# DevOps Playbook - Code Browser

An interactive code template browser for DevOps engineers. Browse, search, and copy templates for Docker, Kubernetes, CI/CD pipelines, and more.

## 🚀 Quick Start

### Local Development

```bash
cd website
npm install
npm run build    # Generates index.json from repo files
npm run dev      # Starts dev server at http://localhost:3000
```

### What happens during build?

1. `npm run index` scans your repository and generates `public/index.json`
2. Vite bundles the React app
3. Output goes to `dist/` folder

## 📦 Deployment

The site auto-deploys to GitHub Pages via GitHub Actions when you push to main.

### Setup GitHub Pages

1. Go to your repo **Settings** → **Pages**
2. Set source to **GitHub Actions**
3. Save

The GitHub Actions workflow automatically:
- Generates the file index
- Builds the React app  
- Deploys to GitHub Pages
- Updates your live site

### View your site

After first deployment, visit:
```
https://YOUR_USERNAME.github.io/devops-playbook/
```

## 🔧 Configuration

### Update GitHub URL

Edit `website/vite.config.ts`:
```typescript
base: '/devops-playbook/',  // ← Your repo name here
```

Edit `website/src/components/CodeViewer.tsx`:
```typescript
const gitHubUrl = `https://github.com/YOUR_USERNAME/devops-playbook/blob/main/${file.path}`;
//                                        ^^^^^^^^^^^^^^^
```

## 📝 Adding/Updating Content

Just update files in your main repo directories (docker/, ci/, kubernetes/, etc.) and push to main:

```bash
git add .
git commit -m "Add new Dockerfile template"
git push origin main
```

The GitHub Actions workflow will:
1. Detect changes
2. Regenerate the index with new files
3. Rebuild and deploy automatically

## 🎯 How It Works

**Index Generation** (`scripts/generate-index.js`):
- Scans repo for files < 50KB
- Extracts code content and metadata
- Groups by category and language
- Generates `public/index.json`

**Frontend**:
- **Sidebar**: Browse by category → subcategory → file
- **Search**: Full-text search across all files
- **Viewer**: Syntax-highlighted code with copy button
- **GitHub Link**: View original file in repo

## 🎨 Customization

### Add/Remove Categories

Edit the excluded patterns in `website/scripts/generate-index.js`:
```javascript
const EXCLUDE_PATTERNS = [
  'node_modules',
  '.git',
  'website',  // Don't index the website folder itself
  // Add more patterns here
];
```

### Change Colors/Theme

Edit CSS files in `website/src/components/`:
- `Sidebar.css` - Left navigation styling
- `CodeViewer.css` - Code display styling  
- `App.css` - Overall layout

### Add Supported Languages

Edit `website/src/components/CodeViewer.tsx`:
```typescript
import 'prismjs/components/prism-YOUR_LANGUAGE';
```

And update the language map in `website/scripts/generate-index.js`.

## 🚨 Troubleshooting

**Blank page after deploy?**
- Check GitHub Pages settings
- Verify base URL in `vite.config.ts` matches repo name

**Files not showing up?**
- Run `npm run index` locally to verify
- Check file size is < 50KB
- Verify file extension is supported

**Search not working?**
- Clear browser cache
- Ensure `public/index.json` was generated

## 📊 File Size Limits

By default, files > 50KB are skipped during indexing. Change in `website/scripts/generate-index.js`:
```javascript
} else if (stat.isFile() && stat.size < maxSize) {  // ← maxSize = 1024 * 50
```

## 🔐 Security

- No backend server needed
- All code is static - served directly from GitHub Pages
- No API keys or credentials stored
- Git history available on GitHub

## 📄 License

See LICENSE in repository root.

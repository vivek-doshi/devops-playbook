<!-- Note 1: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# DevOps Playbook - Code Browser

An interactive code template browser for DevOps engineers. Browse, search, and copy templates for Docker, Kubernetes, CI/CD pipelines, and more.

<!-- Note 2: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## 🚀 Quick Start

### Local Development

<!-- Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```bash
cd website
<!-- Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
npm install
npm run build    # Generates index.json from repo files
<!-- Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
npm run dev      # Starts dev server at http://localhost:3000
```

<!-- Note 6: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### What happens during build?

1. `npm run index` scans your repository and generates `public/index.json`
<!-- Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
2. Vite bundles the React app
3. Output goes to `dist/` folder

<!-- Note 8: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## 📦 Deployment

The site auto-deploys to GitHub Pages via GitHub Actions when you push to main.

<!-- Note 9: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### Setup GitHub Pages

1. Go to your repo **Settings** → **Pages**
<!-- Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
2. Set source to **GitHub Actions**
3. Save

<!-- Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
The GitHub Actions workflow automatically:
- Generates the file index
<!-- Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Builds the React app  
- Deploys to GitHub Pages
<!-- Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Updates your live site

### View your site

<!-- Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
After first deployment, visit:
```
<!-- Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
https://YOUR_USERNAME.github.io/devops-playbook/
```

<!-- Note 16: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## 🔧 Configuration

### Update GitHub URL

<!-- Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
Edit `website/vite.config.ts`:
```typescript
<!-- Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
base: '/devops-playbook/',  // ← Your repo name here
```

<!-- Note 19: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
Edit `website/src/components/CodeViewer.tsx`:
```typescript
<!-- Note 20: This declaration defines a reusable unit, which supports composition and makes behavior easier to test. -->
const gitHubUrl = `https://github.com/YOUR_USERNAME/devops-playbook/blob/main/${file.path}`;
//                                        ^^^^^^^^^^^^^^^
<!-- Note 21: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```

## 📝 Adding/Updating Content

<!-- Note 22: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
Just update files in your main repo directories (docker/, ci/, kubernetes/, etc.) and push to main:

```bash
<!-- Note 23: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
git add .
git commit -m "Add new Dockerfile template"
<!-- Note 24: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
git push origin main
```

<!-- Note 25: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
The GitHub Actions workflow will:
1. Detect changes
<!-- Note 26: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
2. Regenerate the index with new files
3. Rebuild and deploy automatically

<!-- Note 27: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## 🎯 How It Works

**Index Generation** (`scripts/generate-index.js`):
<!-- Note 28: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Scans repo for files < 50KB
- Extracts code content and metadata
<!-- Note 29: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Groups by category and language
- Generates `public/index.json`

<!-- Note 30: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
**Frontend**:
- **Sidebar**: Browse by category → subcategory → file
<!-- Note 31: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- **Search**: Full-text search across all files
- **Viewer**: Syntax-highlighted code with copy button
<!-- Note 32: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- **GitHub Link**: View original file in repo

## 🎨 Customization

<!-- Note 33: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### Add/Remove Categories

Edit the excluded patterns in `website/scripts/generate-index.js`:
<!-- Note 34: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```javascript
const EXCLUDE_PATTERNS = [
  <!-- Note 35: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  'node_modules',
  '.git',
  <!-- Note 36: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  'website',  // Don't index the website folder itself
  // Add more patterns here
<!-- Note 37: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
];
```

<!-- Note 38: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
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

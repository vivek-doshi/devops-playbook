# Setup Instructions

## Prerequisites
- Node.js 18+ 
- npm or yarn
- GitHub account with repo access

## Initial Setup (One-time)

### 1. Install Dependencies
```bash
cd website
npm install
```

### 2. Generate Initial Index
```bash
npm run index
```

This scans the repo and creates `public/index.json` with all your code files.

### 3. Test Locally
```bash
npm run dev
```

Open http://localhost:3000 and verify the browser works.

### 4. Configure GitHub Pages

Go to your repo:
1. **Settings** → **Pages**
2. **Source**: **GitHub Actions**
5. Click **Save**

### 5. Update Configuration Files

**Option A: If your repo is public and named `devops-playbook`:**
- No changes needed (defaults are already set)

**Option B: If using a different repo name:**

Edit `website/vite.config.ts`:
```typescript
base: '/YOUR_REPO_NAME/',
```

Edit `website/src/components/CodeViewer.tsx` (line ~48):
```typescript
const gitHubUrl = `https://github.com/YOUR_USERNAME/YOUR_REPO_NAME/blob/main/${file.path}`;
```

### 6. Push to Main

```bash
git add .github/ website/
git commit -m "Add code browser"
git push origin main
```

GitHub Actions will automatically:
- Build the site
- Deploy to GitHub Pages
- Your site goes live at: `https://YOUR_USERNAME.github.io/YOUR_REPO_NAME/`

## Daily Workflow

**When you update templates in the repo:**

```bash
# 1. Make changes to docker/, ci/, kubernetes/, etc.
git add docker/
git commit -m "Update Dockerfile templates"

# 2. Push to main
git push origin main

# GitHub Actions automatically:
# ✓ Regenerates index.json
# ✓ Rebuilds site
# ✓ Deploys to GitHub Pages
```

No manual build needed - it's all automated!

## Testing Before Push

```bash
cd website

# Generate index locally
npm run index

# Test locally
npm run dev

# Verify everything works, then push
git push
```

## Troubleshooting

### "I don't see my files"
1. Check `npm run index` output - should show file count by category
2. Verify files aren't in the exclude list (`website/scripts/generate-index.js`)
3. Check file size is < 50KB

### "Site shows blank page"
1. Check GitHub Pages is enabled
2. Verify `vite.config.ts` base URL matches your repo name
3. Check browser console for errors

### "Copy button doesn't work"  
1. Try different browser
2. Must use HTTPS (GitHub Pages is always HTTPS)
3. Check browser permissions for clipboard

### "Search doesn't work"
1. Clear browser cache
2. Verify `index.json` exists in deployed site
3. Check browser console for errors

## Updating the Browser UI

### Change sidebar width
Edit `website/src/components/Sidebar.css`:
```css
.sidebar {
  width: 280px;  /* ← Change this */
}
```

### Change colors/theme
All colors are defined in the `.css` files using hex codes (e.g., `#1e1e1e`).

### Add new languages
Edit `website/src/components/CodeViewer.tsx` and `website/scripts/generate-index.js`.

## Questions?

- Check [website/README.md](website/README.md) for technical details
- See repo issues for known problems
- File structure is in root [README.md](README.md)

<!-- Note 1: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# Setup Instructions

## Prerequisites
<!-- Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Node.js 18+ 
- npm or yarn
<!-- Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- GitHub account with repo access

## Initial Setup (One-time)

<!-- Note 4: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### 1. Install Dependencies
```bash
<!-- Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
cd website
npm install
<!-- Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```

### 2. Generate Initial Index
<!-- Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```bash
npm run index
<!-- Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```

This scans the repo and creates `public/index.json` with all your code files.

<!-- Note 9: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### 3. Test Locally
```bash
<!-- Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
npm run dev
```

<!-- Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
Open http://localhost:3000 and verify the browser works.

### 4. Configure GitHub Pages

<!-- Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
Go to your repo:
1. **Settings** → **Pages**
<!-- Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
2. **Source**: **GitHub Actions**
5. Click **Save**

<!-- Note 14: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### 5. Update Configuration Files

**Option A: If your repo is public and named `devops-playbook`:**
<!-- Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- No changes needed (defaults are already set)

**Option B: If using a different repo name:**

<!-- Note 16: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
Edit `website/vite.config.ts`:
```typescript
<!-- Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
base: '/YOUR_REPO_NAME/',
```

<!-- Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
Edit `website/src/components/CodeViewer.tsx` (line ~48):
```typescript
<!-- Note 19: This declaration defines a reusable unit, which supports composition and makes behavior easier to test. -->
const gitHubUrl = `https://github.com/YOUR_USERNAME/YOUR_REPO_NAME/blob/main/${file.path}`;
```

<!-- Note 20: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### 6. Push to Main

```bash
<!-- Note 21: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
git add .github/ website/
git commit -m "Add code browser"
<!-- Note 22: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
git push origin main
```

<!-- Note 23: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
GitHub Actions will automatically:
- Build the site
<!-- Note 24: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Deploy to GitHub Pages
- Your site goes live at: `https://YOUR_USERNAME.github.io/YOUR_REPO_NAME/`

<!-- Note 25: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Daily Workflow

**When you update templates in the repo:**

<!-- Note 26: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```bash
# 1. Make changes to docker/, ci/, kubernetes/, etc.
<!-- Note 27: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
git add docker/
git commit -m "Update Dockerfile templates"

<!-- Note 28: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# 2. Push to main
git push origin main

<!-- Note 29: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# GitHub Actions automatically:
# ✓ Regenerates index.json
<!-- Note 30: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# ✓ Rebuilds site
# ✓ Deploys to GitHub Pages
<!-- Note 31: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```

No manual build needed - it's all automated!

<!-- Note 32: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Testing Before Push

```bash
<!-- Note 33: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
cd website

# Generate index locally
<!-- Note 34: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
npm run index

# Test locally
<!-- Note 35: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
npm run dev

# Verify everything works, then push
<!-- Note 36: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
git push
```

<!-- Note 37: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
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

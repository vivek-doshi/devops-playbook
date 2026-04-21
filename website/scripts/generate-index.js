const fs = require('fs');
const path = require('path');

// Files and directories to exclude
const EXCLUDE_PATTERNS = [
  'node_modules',
  '.git',
  '.github',
  'dist',
  'website',
  '.next',
  '__pycache__',
  '.pytest_cache',
  '*.lock',
  '.DS_Store'
];

function shouldExclude(filePath) {
  return EXCLUDE_PATTERNS.some(pattern => {
    if (pattern.includes('*')) {
      const regex = new RegExp(pattern.replace(/\*/g, '.*'));
      return regex.test(filePath);
    }
    return filePath.includes(pattern);
  });
}

function getLanguageFromPath(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  const langMap = {
    '.yml': 'yaml',
    '.yaml': 'yaml',
    '.json': 'json',
    '.js': 'javascript',
    '.ts': 'typescript',
    '.tsx': 'typescript',
    '.jsx': 'jsx',
    '.py': 'python',
    '.java': 'java',
    '.go': 'go',
    '.rb': 'ruby',
    '.sh': 'bash',
    '.bash': 'bash',
    '.dockerfile': 'dockerfile',
    '': 'dockerfile' // Dockerfile without extension
  };

  // Handle Dockerfile specially
  if (filePath.endsWith('Dockerfile') || filePath.includes('Dockerfile.')) {
    return 'dockerfile';
  }

  return langMap[ext] || 'plain';
}

function getCategory(filePath) {
  const parts = filePath.split(path.sep);
  return parts[0] || 'root';
}

function scanDirectory(dir, baseDir = '', maxSize = 1024 * 50) {
  const files = [];

  try {
    const items = fs.readdirSync(dir);

    for (const item of items) {
      const fullPath = path.join(dir, item);
      const relPath = path.join(baseDir, item);

      if (shouldExclude(relPath)) continue;

      try {
        const stat = fs.statSync(fullPath);

        if (stat.isDirectory()) {
          files.push(...scanDirectory(fullPath, relPath));
        } else if (stat.isFile() && stat.size < maxSize) {
          try {
            const content = fs.readFileSync(fullPath, 'utf-8');
            files.push({
              path: relPath.replace(/\\/g, '/'),
              category: getCategory(relPath),
              language: getLanguageFromPath(relPath),
              size: stat.size,
              content: content,
              fileName: path.basename(relPath)
            });
          } catch (e) {
            console.warn(`Could not read file: ${relPath}`);
          }
        }
      } catch (e) {
        console.warn(`Could not process: ${relPath}`);
      }
    }
  } catch (e) {
    console.error(`Error scanning directory ${dir}:`, e.message);
  }

  return files;
}

function generateIndex() {
  const repoRoot = path.join(__dirname, '..');
  const websiteDir = path.join(repoRoot, 'website');
  const outputPath = path.join(websiteDir, 'public', 'index.json');

  console.log('Generating index.json...');
  console.log(`Scanning: ${repoRoot}`);

  const files = scanDirectory(repoRoot);

  // Sort by category then by path
  files.sort((a, b) => {
    if (a.category !== b.category) {
      return a.category.localeCompare(b.category);
    }
    return a.path.localeCompare(b.path);
  });

  // Write output
  fs.writeFileSync(outputPath, JSON.stringify(files, null, 2));

  console.log(`✓ Generated ${files.length} files`);
  console.log(`✓ Saved to ${outputPath}`);

  // Print summary by category
  const categorySummary = {};
  files.forEach(f => {
    categorySummary[f.category] = (categorySummary[f.category] || 0) + 1;
  });

  console.log('\nCategory breakdown:');
  Object.entries(categorySummary)
    .sort()
    .forEach(([cat, count]) => {
      console.log(`  ${cat}: ${count} files`);
    });
}

generateIndex();

// Note 1: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
const fs = require('fs');
const path = require('path');

// Files and directories to exclude
const EXCLUDE_PATTERNS = [
  // Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  'node_modules',
  '.git',
  '.github',
  // Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  'dist',
  'website',
  '.next',
  // Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  '__pycache__',
  '.pytest_cache',
  '*.lock',
  // Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  '.DS_Store'
];

const EXCLUDE_EXTENSIONS = ['.md', '.markdown', '.txt'];
// Note 6: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
const EXCLUDE_FILE_NAMES = ['license', 'readme', 'getting_started'];

function shouldExclude(filePath) {
  const normalizedPath = filePath.replace(/\\/g, '/').toLowerCase();
  // Note 7: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  const fileName = path.basename(normalizedPath);
  const ext = path.extname(normalizedPath);

  if (EXCLUDE_EXTENSIONS.includes(ext)) {
    // Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    return true;
  }

  if (EXCLUDE_FILE_NAMES.some(name => fileName.startsWith(name))) {
    // Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    return true;
  }

  return EXCLUDE_PATTERNS.some(pattern => {
    // Note 10: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting.
    if (pattern.includes('*')) {
      const regex = new RegExp(pattern.replace(/\*/g, '.*'));
      return regex.test(normalizedPath);
    // Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    }
    return normalizedPath.includes(pattern);
  });
// Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

function getLanguageFromPath(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  // Note 13: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  const langMap = {
    '.yml': 'yaml',
    '.yaml': 'yaml',
    // Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    '.json': 'json',
    '.js': 'javascript',
    '.ts': 'typescript',
    // Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    '.tsx': 'typescript',
    '.jsx': 'jsx',
    '.py': 'python',
    // Note 16: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    '.java': 'java',
    '.go': 'go',
    '.rb': 'ruby',
    // Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    '.sh': 'bash',
    '.bash': 'bash',
    '.dockerfile': 'dockerfile',
    // Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    '': 'dockerfile' // Dockerfile without extension
  };

  // Handle Dockerfile specially
  if (filePath.endsWith('Dockerfile') || filePath.includes('Dockerfile.')) {
    // Note 19: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    return 'dockerfile';
  }

  return langMap[ext] || 'plain';
// Note 20: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

function getCategory(filePath) {
  const parts = filePath.split(path.sep);
  // Note 21: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  return parts[0] || 'root';
}

function scanDirectory(dir, baseDir = '', maxSize = 1024 * 50) {
  // Note 22: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  const files = [];

  try {
    const items = fs.readdirSync(dir);

    // Note 23: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting.
    for (const item of items) {
      const fullPath = path.join(dir, item);
      const relPath = path.join(baseDir, item);

      // Note 24: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting.
      if (shouldExclude(relPath)) continue;

      try {
        const stat = fs.statSync(fullPath);

        // Note 25: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting.
        if (stat.isDirectory()) {
          files.push(...scanDirectory(fullPath, relPath));
        } else if (stat.isFile() && stat.size < maxSize) {
          // Note 26: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting.
          try {
            const content = fs.readFileSync(fullPath, 'utf-8');
            files.push({
              // Note 27: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
              path: relPath.replace(/\\/g, '/'),
              category: getCategory(relPath),
              language: getLanguageFromPath(relPath),
              // Note 28: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
              size: stat.size,
              content: content,
              fileName: path.basename(relPath)
            // Note 29: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
            });
          } catch (e) {
            console.warn(`Could not read file: ${relPath}`);
          // Note 30: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
          }
        }
      } catch (e) {
        // Note 31: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
        console.warn(`Could not process: ${relPath}`);
      }
    }
  // Note 32: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  } catch (e) {
    console.error(`Error scanning directory ${dir}:`, e.message);
  }

  // Note 33: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  return files;
}

function generateIndex() {
  // Note 34: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  const websiteDir = path.join(__dirname, '..');
  const repoRoot = path.join(websiteDir, '..');
  const outputPath = path.join(websiteDir, 'public', 'index.json');

  // Note 35: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  console.log('Generating index.json...');
  console.log(`Scanning: ${repoRoot}`);

  const files = scanDirectory(repoRoot);

  // Sort by category then by path
  // Note 36: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  files.sort((a, b) => {
    if (a.category !== b.category) {
      return a.category.localeCompare(b.category);
    // Note 37: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    }
    return a.path.localeCompare(b.path);
  });

  // Write output
  // Note 38: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  fs.writeFileSync(outputPath, JSON.stringify(files, null, 2));

  console.log(`✓ Generated ${files.length} files`);
  console.log(`✓ Saved to ${outputPath}`);

  // Print summary by category
  // Note 39: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  const categorySummary = {};
  files.forEach(f => {
    categorySummary[f.category] = (categorySummary[f.category] || 0) + 1;
  // Note 40: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  });

  console.log('\nCategory breakdown:');
  Object.entries(categorySummary)
    .sort()
    .forEach(([cat, count]) => {
      console.log(`  ${cat}: ${count} files`);
    });
}

generateIndex();

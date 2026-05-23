# Session Summary: Repo Map Generator

## Objective
Exclude selected folders from `.ai/context/repo_map.md` and add a reusable script to regenerate/update the map with configurable ignores.

## Changes Made
- Added PowerShell generator script: `scripts/generate-repo-map.ps1`
  - Generates `.ai/context/repo_map.md`
  - Reads ignore folders from `.ai/context/repo_map.ignore`
  - Supports extra ignores via `-IgnoreFolders`
  - Includes exclusions list in map header
- Added ignore config file: `.ai/context/repo_map.ignore`
  - `.ai`
  - `.kiro`
  - `.github/prompts`
  - `.github/skills`
- Regenerated `.ai/context/repo_map.md`.

## Verification
- Confirmed excluded folders no longer appear in generated tree output.
- Script and generated files return no diagnostics errors.

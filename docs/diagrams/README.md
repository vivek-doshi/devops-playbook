# Architecture Diagrams

This folder stores visual references for repository architecture and delivery flow.

## Current Artifacts

- `deployment-flow.svg`
- `deployment-flow.png`
- `pipeline-overview.svg`
- `pipeline-overview.drawio`

## Usage

- Use SVG assets in documentation where possible.
- Keep `.drawio` sources as editable canonical files.
- Export PNG only for contexts where SVG rendering is limited.

## Update Guidance

When updating a diagram:
1. Modify the `.drawio` source first.
2. Re-export SVG and PNG.
3. Keep naming stable unless the conceptual model changes.
4. Update related docs in `docs/golden-paths/` or `docs/guides/` if flow meaning changed.

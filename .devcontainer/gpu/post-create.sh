#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${repo_root}"

python3 -m pip install --upgrade pip
python3 -m pip install jupyterlab tensorboard ipykernel nvidia-ml-py3

if command -v nvidia-smi >/dev/null 2>&1; then
  echo "==> Verifying GPU visibility inside the devcontainer"
  nvidia-smi || true
fi

echo
echo "GPU devcontainer ready."
echo "Next steps:"
echo "  1. Create your project virtual environment or uv environment"
echo "  2. Install your ML framework build that matches the host CUDA driver"
echo "  3. Launch JupyterLab with: python3 -m jupyter lab --ip=0.0.0.0 --no-browser --NotebookApp.token=''"

# GPU Devcontainer

Use this template when you need local CUDA/GPU pass-through for model fine-tuning, notebook experiments, or validating inference images before pushing changes to cloud GPU clusters.

## Host prerequisites

- Docker with GPU support enabled
- NVIDIA drivers installed on the host
- Docker Desktop with WSL2 GPU support on Windows, or NVIDIA Container Toolkit on Linux
- VS Code Dev Containers extension

## Open it in VS Code

From the command palette, use `Dev Containers: Open Folder in Container...` and choose `.devcontainer/gpu/devcontainer.json`.

## What this template gives you

- CUDA 12.4 + cuDNN developer image
- `--gpus=all` pass-through and large shared memory settings
- Python 3.12, JupyterLab, TensorBoard, and NVIDIA telemetry bindings
- Ports exposed for JupyterLab on `8888` and TensorBoard on `6006`

## Verify GPU access

```bash
nvidia-smi
python3 - <<'PY'
import pynvml
pynvml.nvmlInit()
print(pynvml.nvmlDeviceGetCount())
PY
```

Install your framework-specific packages in a project virtual environment so you can choose the right PyTorch, TensorFlow, or JAX build for your driver stack.

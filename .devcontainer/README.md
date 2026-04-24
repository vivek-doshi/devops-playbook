# Dev Container

Open the repository in VS Code and choose **Reopen in Container** when prompted. In GitHub Codespaces, create a new codespace from the repository root and the same configuration will be used automatically.

The devcontainer pre-installs the tools this repository leans on most: Terraform and Pulumi for infrastructure examples, Kubernetes and Helm tooling for deployment manifests, secret and policy scanners for local security checks, cloud CLIs for AWS, Azure, and GCP targets, plus the formatter and editor extensions that match the existing quality configuration.

If you need project-specific tools, keep the shared Dockerfile stable and extend the post-create step instead. A common pattern is to add a personal or team-specific override that appends commands such as `bash .devcontainer/scripts/post-create.sh && npm install -g your-extra-cli` rather than editing the shared image definition for one-off needs.

Expect the first launch to take roughly 5 to 8 minutes while the container image is built and the tools are installed. After the first build, reopening the container is usually under 30 seconds because the image layers and VS Code server are already cached.
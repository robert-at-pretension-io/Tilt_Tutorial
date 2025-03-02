# Comprehensive Guide to Using Tilt for Kubernetes Development

Tilt is a powerful tool for developing applications in Kubernetes that improves the inner loop development experience. This guide will walk you through setting up and using Tilt for your Kubernetes projects.

## Table of Contents
- [What is Tilt?](#what-is-tilt)
- [Why Use Tilt?](#why-use-tilt)
- [Installation](#installation)
- [Getting Started with Tilt](#getting-started-with-tilt)
- [Tilt Concepts](#tilt-concepts)
- [Writing a Tiltfile](#writing-a-tiltfile)
- [Live Update: Fast Development Cycles](#live-update-fast-development-cycles)
- [Advanced Features](#advanced-features)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## What is Tilt?

Tilt is an open-source development tool that optimizes the workflow for developers working with Kubernetes. It automates the process of building, pushing, and deploying your application to a Kubernetes cluster, providing fast feedback when your code changes.

At its core, Tilt implements a control loop that:
1. Monitors your source code for changes
2. Rebuilds your application (container images, etc.)
3. Updates your Kubernetes resources
4. Provides immediate feedback through logs and UI

## Why Use Tilt?

Before Kubernetes, developing applications was simpler. But with microservices and containerization, developers now face challenges:

- Building container images
- Managing image versions
- Creating and updating Kubernetes manifests
- Deploying to a test cluster
- Gathering logs from multiple services

Tilt addresses these challenges by:

- **Automating the build-deploy cycle**: No more manual `docker build && kubectl apply` commands
- **Providing a unified view**: See all your services, builds, and logs in one place
- **Enabling fast updates**: Skip image rebuilds when possible with Live Update
- **Supporting multi-service applications**: Easily manage complex applications with dependencies
- **Offering real-time feedback**: Get immediate notifications about build and runtime errors

## Installation

### macOS/Linux
```bash
curl -fsSL https://raw.githubusercontent.com/tilt-dev/tilt/master/scripts/install.sh | bash
```

### Windows
```powershell
iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/tilt-dev/tilt/master/scripts/install.ps1'))
```

### Prerequisites
- Docker (or another container runtime)
- A Kubernetes cluster (local or remote)
- `kubectl` configured to access your cluster

## Getting Started with Tilt

### Quick Start with Demo

Tilt provides a demo command that sets up a temporary Kubernetes environment:

```bash
tilt demo
```

This command:
1. Creates a temporary local Kubernetes cluster in Docker
2. Clones the sample project (Tilt Avatars)
3. Launches a Tilt session for the project
4. Cleans everything up on exit

Press the spacebar when prompted to open the Tilt UI in your browser.

### Starting Tilt in Your Project

To use Tilt in your own project:

1. Navigate to your project directory
2. Create a `Tiltfile` (details in the next section)
3. Run `tilt up`
4. Press space to open the Tilt UI

To shut down your Tilt environment, run `tilt down` or press Ctrl+C in your terminal.

## Tilt Concepts

### The Tiltfile

A `Tiltfile` is the configuration file for Tilt. It's written in Starlark, a simplified dialect of Python, and defines how your application should be built and deployed.

### Resources

A "resource" in Tilt is a bundle of work that Tilt manages. For example, a resource might include:
- A Docker image to build
- A Kubernetes deployment to apply
- A port forward to set up

Tilt automatically groups related work into resources and shows their status in the UI.

### The Control Loop

Tilt operates using a control loop that:
1. Watches files for changes
2. Detects which resources need updating
3. Performs the necessary actions (build, deploy, etc.)
4. Shows the results in real-time

This loop continues running until you stop Tilt, providing continuous feedback.

## Writing a Tiltfile

A basic `Tiltfile` consists of three main parts: Deploy, Build, and Watch.

### Basic Tiltfile Example

```python
# Deploy: tell Tilt what YAML to deploy
k8s_yaml('app.yaml')

# Build: tell Tilt what images to build from which directories
docker_build('companyname/frontend', 'frontend')
docker_build('companyname/backend', 'backend')

# Watch: tell Tilt how to connect locally (optional)
k8s_resource('frontend', port_forwards=8080)
```

### Step 1: Deploy - Defining Kubernetes Resources

Tilt can deploy Kubernetes resources from various sources:

```python
# Single YAML file
k8s_yaml('app.yaml')

# Multiple YAML files
k8s_yaml(['service.yaml', 'deployment.yaml'])

# Generate YAML with an external command
k8s_yaml(local('gen_k8s_yaml.py'))

# Use Helm
k8s_yaml(helm('chart_dir'))

# Use Kustomize
k8s_yaml(kustomize('config_dir'))
```

### Step 2: Build - Defining Image Builds

Tell Tilt how to build your container images:

```python
# Basic Docker build
docker_build('image-name', '.')

# Specify a different Dockerfile
docker_build('image-name', '.', dockerfile='Dockerfile.dev')

# Only include specific files/directories
docker_build('image-name', '.', only=['src/', 'package.json'])

# Add build arguments
docker_build('image-name', '.', build_args={'ENV': 'development'})
```

### Step 3: Watch - Configure Resource Settings

Configure how Tilt interacts with your resources:

```python
# Set up a port forward
k8s_resource('frontend', port_forwards=8080)

# Set up multiple port forwards
k8s_resource('api', port_forwards=['8080:8080', '8081:8081'])

# Add resource dependencies
k8s_resource('frontend', resource_deps=['backend'])

# Add labels for organization
k8s_resource('frontend', labels=['ui'])
```

## Live Update: Fast Development Cycles

Live Update is a powerful Tilt feature that enables in-place updates to running containers without rebuilding images or redeploying pods.

### Basic Live Update Example

```python
docker_build(
    'my-image',
    '.',
    live_update=[
        # Sync local files to the container
        sync('./src', '/app/src'),
        
        # Run a command when specific files change
        run('npm install', trigger=['package.json']),
        
        # Restart the process after updates
        restart_container()
    ]
)
```

### Live Update Steps

1. **sync()**: Copy files from your local machine to the running container
   ```python
   sync('./local/path', '/container/path')
   ```

2. **run()**: Execute a command in the container
   ```python
   run('command to run')
   ```

3. **run() with triggers**: Run commands only when specific files change
   ```python
   run('pip install -r requirements.txt', trigger=['requirements.txt'])
   ```

4. **restart_container()**: Restart the container after updates (when hot reload isn't available)

### When to Use Live Update

- For interpreted languages (Python, JavaScript, etc.) where hot reloading is possible
- When you want to update dependency files without rebuilding images
- To avoid the overhead of container image builds during development

## Advanced Features

### Local Resource Development

Tilt can manage local processes alongside Kubernetes resources:

```python
# Run a local command once
local_resource('compile', 'make compile')

# Run a local server
local_resource(
    'start-dev-server',
    'npm start',
    serve_cmd='npm run serve',
    links=['http://localhost:3000']
)
```

### Working with Multiple Services/Repositories

For complex applications with multiple services:

```python
# Load Tiltfiles from other directories
load('path/to/other/Tiltfile', 'some_function')

# Include another Tiltfile
include('path/to/other/Tiltfile')
```

### Resource Dependencies

Manage dependencies between resources:

```python
k8s_resource('frontend', resource_deps=['backend', 'database'])
```

### Custom Triggers and Extensions

Extend Tilt with custom functionality:

```python
# Create a custom button in the UI
trigger_mode(TRIGGER_MODE_MANUAL)
cmd = 'echo "Button pressed!"'
local_resource('custom-action', cmd)
```

## Best Practices

1. **Organize your Tiltfile for large projects**
   - Split functionality into separate files
   - Use functions to reduce duplication

2. **Optimize build performance**
   - Use `only` to limit which files trigger rebuilds
   - Leverage Live Update whenever possible
   - Structure Dockerfiles for better layer caching

3. **Improve resource visibility**
   - Use descriptive resource names
   - Add labels to group related resources
   - Configure resource dependencies appropriately

4. **Use Tilt with your team**
   - Document your Tiltfile
   - Share Tilt configurations via version control
   - Consider creating a `.tiltignore` file

## Troubleshooting

### Common Issues

1. **Slow builds**
   - Check your Dockerfile for inefficient patterns
   - Use Live Update to avoid full rebuilds
   - Limit the context with `only`

2. **Resources not updating**
   - Verify that Tilt is watching the correct directories
   - Check for errors in the Tilt UI
   - Run `tilt logs` to see detailed logs

3. **Kubernetes errors**
   - Check cluster connectivity with `kubectl get pods`
   - Verify that your YAML is valid
   - Look for errors in the Tilt UI

### Debugging Tilt

1. **Tiltfile debugging**
   - Use `print()` statements to debug your Tiltfile
   - Run `tilt doctor` to check your Tilt installation
   - Check the Tiltfile resource in the Tilt UI

2. **Log collection**
   - Use `tilt logs` to see combined logs
   - Filter logs in the Tilt UI
   - Export logs for sharing with `tilt dump`

---

Tilt provides a powerful environment for Kubernetes development that can significantly improve developer productivity. By automating the build-deploy cycle and providing immediate feedback, it allows developers to focus on writing code rather than managing infrastructure.

For more information, visit the [official Tilt documentation](https://docs.tilt.dev/).
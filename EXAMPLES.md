# Comprehensive Guide to Modern Tiltfiles (2025)

This guide provides a collection of practical Tiltfile examples for different use cases, reflecting the latest best practices for 2025. Tilt is a powerful tool that allows developers to efficiently work with microservices on Kubernetes by automating the build, push, and deploy processes.

## Table of Contents

1. [Basic Tiltfile Concepts](#basic-tiltfile-concepts)
2. [Simple Go Microservice](#simple-go-microservice)
3. [Multi-Service Application](#multi-service-application)
4. [Advanced Configuration Options](#advanced-configuration-options)
5. [Live Update for Fast Development](#live-update-for-fast-development)
6. [Resource Configuration](#resource-configuration)
7. [Kubernetes and Docker Compose Integration](#kubernetes-and-docker-compose-integration)
8. [Using Extensions](#using-extensions)
9. [Conditional Logic and Environment-Specific Configuration](#conditional-logic-and-environment-specific-configuration)
10. [Complex Real-World Example](#complex-real-world-example)

## Basic Tiltfile Concepts

Tiltfile is written in [Starlark](https://github.com/bazelbuild/starlark), a Python-like language. Here's a basic template that covers the fundamental components:

```python
# Deploy: tell Tilt what YAML to deploy
k8s_yaml('kubernetes.yaml')

# Build: tell Tilt what images to build from which directories
docker_build('example-image', '.')

# Watch: tell Tilt how to connect locally (optional)
k8s_resource('example-deployment', port_forwards=8000)
```

## Simple Go Microservice

This example demonstrates a typical Tiltfile for a Go service:

```python
# Build the Go binary
local_resource(
  'go-compile',
  'CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o build/app .',
  deps=['./main.go', 'go.mod', 'go.sum', './pkg'],
)

# Build the Docker image with the binary
docker_build(
  'example-go-image',
  '.',
  dockerfile='Dockerfile',
  only=['./build', './config'],
  live_update=[
    sync('./build', '/app/build'),
    sync('./config', '/app/config'),
  ],
)

# Deploy to Kubernetes
k8s_yaml('kubernetes.yaml')

# Configure resource, port forwarding, and dependencies
k8s_resource(
  'example-go',
  port_forwards=8080,
  resource_deps=['go-compile']
)
```

## Multi-Service Application

When working with multiple services, you can structure your Tiltfile to handle each service individually:

```python
# Define a function to set up each service
def setup_service(name, context_dir):
    # Build Docker image
    docker_build(
        'example-' + name,
        context_dir,
        dockerfile=context_dir + '/Dockerfile',
        live_update=[
            sync(context_dir + '/src', '/app/src'),
            run('cd /app && npm install', trigger=['./package.json']),
            restart_container(),
        ],
    )
    
    # Deploy Kubernetes YAML
    k8s_yaml(context_dir + '/kubernetes.yaml')
    
    # Configure resource with appropriate labels and port forwards
    k8s_resource(
        'example-' + name,
        port_forwards=8000,
        labels=[name]
    )

# Set up each service
setup_service('frontend', './frontend')
setup_service('backend', './backend')
setup_service('database', './database')

# Define dependencies between services
k8s_resource('example-frontend', resource_deps=['example-backend'])
k8s_resource('example-backend', resource_deps=['example-database'])
```

## Advanced Configuration Options

Tilt offers advanced configuration options to customize your development environment:

```python
# Set update settings
update_settings(
    max_parallel_updates=3,
    k8s_upsert_timeout_secs=60,
)

# Configure version settings
version_settings(
    check_updates=True,
    constraint=">0.30.0",
)

# Configure default registry for images
default_registry('gcr.io/my-project')

# Set allowed Kubernetes contexts for safety
allow_k8s_contexts(['dev-cluster', 'minikube', 'docker-desktop'])

# Set trigger mode for all resources
trigger_mode(TRIGGER_MODE_MANUAL)
```

## Live Update for Fast Development

Live Update allows for faster development cycles by updating code without rebuilding containers:

```python
# Node.js application with hot reloading
docker_build(
    'frontend-image',
    './frontend',
    live_update=[
        # Sync source code files
        sync('./frontend/src', '/app/src'),
        
        # Run npm install when package.json changes
        run('cd /app && npm install', trigger=['./frontend/package.json']),
        
        # Restart the process when certain files change
        run('cd /app && npm run build', trigger=['./frontend/webpack.config.js']),
        
        # Restart the container for other file changes
        restart_container(),
    ],
)

# Go application with binary replacement
local_resource(
    'backend-compile',
    'cd backend && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o bin/backend .',
    deps=['./backend/main.go', './backend/pkg'],
)

docker_build(
    'backend-image',
    './backend',
    dockerfile='./backend/Dockerfile',
    live_update=[
        sync('./backend/bin/backend', '/app/backend'),
        sync('./backend/config', '/app/config'),
        restart_container(),
    ],
)
```

## Resource Configuration

You can configure Kubernetes resources with labels, port forwards, and dependencies:

```python
# Deploy multiple Kubernetes YAML files
k8s_yaml(['frontend.yaml', 'backend.yaml', 'database.yaml'])

# Configure frontend resource
k8s_resource(
    'frontend',
    port_forwards=[
        # Format: 'local_port:container_port'
        '8080:80',
        # Named port forward for UI link
        port_forward(8081, 8081, name='Frontend UI'),
    ],
    labels=['frontend', 'web'],
    resource_deps=['backend'],
)

# Configure backend resource
k8s_resource(
    'backend',
    port_forwards=[
        '8000:8000',
        port_forward(9000, 9000, name='API Docs'),
    ],
    labels=['backend', 'api'],
    resource_deps=['database'],
)

# Configure database with pod readiness check
k8s_resource(
    'database',
    port_forwards='5432:5432',
    labels=['database', 'storage'],
    pod_readiness='wait',
)

# Add custom links to resources
k8s_resource(
    'frontend',
    links=[
        link('http://localhost:8080', 'Frontend'),
        link('http://localhost:8081/metrics', 'Metrics'),
    ],
)
```

## Kubernetes and Docker Compose Integration

Tilt supports both Kubernetes and Docker Compose:

```python
# Kubernetes configuration
k8s_yaml('kubernetes.yaml')

# Docker Compose configuration
docker_compose('docker-compose.yml')

# Configure Docker Compose resource
dc_resource(
    'web',
    port_forwards=8080,
    labels=['frontend'],
)

# Configure resource that spans both K8s and Docker Compose
k8s_resource(
    'api',
    port_forwards=3000,
    resource_deps=['web'],
)
```

## Using Extensions

Tilt extensions provide reusable functionality:

```python
# Load extensions
load('ext://restart_process', 'docker_build_with_restart')
load('ext://helm_remote', 'helm_remote')
load('ext://namespace', 'namespace_create', 'namespace_inject')
load('ext://configmap', 'configmap_create')

# Use restart_process extension for more efficient rebuilds
docker_build_with_restart(
    'backend-image',
    './backend',
    entrypoint=['/app/backend'],
    live_update=[
        sync('./backend/bin/backend', '/app/backend'),
    ],
)

# Use helm_remote to install dependencies
helm_remote(
    'redis',
    repo_name='bitnami',
    repo_url='https://charts.bitnami.com/bitnami',
    release_name='redis',
    namespace='redis',
    values=['./redis-values.yaml'],
)

# Create and inject namespace
namespace = 'my-app'
namespace_create(namespace)
k8s_yaml(namespace_inject(read_file('kubernetes.yaml'), namespace))

# Create ConfigMap from files
configmap_create(
    'app-config',
    from_file=['config.json', 'settings.yaml'],
    namespace=namespace,
)
```

## Conditional Logic and Environment-Specific Configuration

You can use conditional logic to adapt to different environments:

```python
# Load environment-specific settings
settings = {}
if os.path.exists('./tilt-settings.json'):
    settings = read_json('./tilt-settings.json')
else:
    settings = {
        'default_registry': '',
        'enable_feature_x': False,
        'environment': 'development',
    }

# Configure based on settings
if settings.get('default_registry', '') != '':
    default_registry(settings.get('default_registry'))

# Enable features conditionally
if settings.get('enable_feature_x', False):
    k8s_yaml('feature-x.yaml')
    k8s_resource('feature-x', labels=['experimental'])

# Environment-specific configuration
environment = settings.get('environment', 'development')
if environment == 'development':
    # Development-specific settings
    local_resource(
        'dev-setup',
        'scripts/dev-setup.sh',
        auto_init=True,
    )
elif environment == 'staging':
    # Staging-specific settings
    k8s_yaml('staging-extras.yaml')
    k8s_resource('staging-gateway', labels=['staging'])

# OS-specific commands
if os.name == 'nt':  # Windows
    compile_cmd = 'build.bat'
else:  # Unix-like (Linux, macOS)
    compile_cmd = './build.sh'

local_resource('compile', compile_cmd, deps=['./src'])

# Check for required tools
if str(local('command -v kubectl || true', quiet=True)) == '':
    fail('kubectl is required but not found')
```

## Complex Real-World Example

This example integrates multiple concepts for a complex microservices application:

```python
# -*- mode: Python -*-

# Load configuration
config_file = './tilt-config.json'
if os.path.exists(config_file):
    config = read_json(config_file)
else:
    config = {}

# Set default values
environment = config.get('environment', 'development')
default_reg = config.get('default_registry', '')
namespace = config.get('namespace', 'default')
enable_observability = config.get('enable_observability', False)
services_to_run = config.get('services', ['api', 'web', 'worker', 'auth'])

# Configure registry if provided
if default_reg:
    default_registry(default_reg)

# Allowed Kubernetes contexts for safety
allow_k8s_contexts(['minikube', 'docker-desktop', 'dev-cluster', 'kind-kind'])

# Create namespace if needed
if namespace != 'default':
    k8s_resource(
        new_name='namespace',
        objects=[
            'namespace:' + namespace,
        ],
        labels=['infra'],
    )

# Set up observability stack if enabled
if enable_observability:
    # Prometheus and Grafana
    helm_remote(
        'prometheus',
        repo_name='prometheus-community',
        repo_url='https://prometheus-community.github.io/helm-charts',
        namespace=namespace,
        release_name='prometheus',
        values=['./observability/prometheus-values.yaml'],
    )
    
    k8s_resource(
        'prometheus-server',
        port_forwards='9090:9090',
        labels=['observability'],
    )
    
    helm_remote(
        'grafana',
        repo_name='grafana',
        repo_url='https://grafana.github.io/helm-charts',
        namespace=namespace,
        release_name='grafana',
        values=['./observability/grafana-values.yaml'],
    )
    
    k8s_resource(
        'grafana',
        port_forwards='3000:3000',
        labels=['observability'],
    )

# Function to set up each service
def setup_service(name, path):
    if name not in services_to_run:
        return
    
    # Service-specific settings
    settings = config.get('service_settings', {}).get(name, {})
    
    # Build image with live update
    if name in ['api', 'worker']:
        # Go service
        local_resource(
            name + '-compile',
            'cd ' + path + ' && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o bin/' + name + ' .',
            deps=[path + '/main.go', path + '/pkg'],
            labels=[name, 'build'],
        )
        
        docker_build(
            name + '-image',
            path,
            dockerfile=path + '/Dockerfile',
            live_update=[
                sync(path + '/bin/' + name, '/app/' + name),
                sync(path + '/config', '/app/config'),
                restart_container(),
            ],
        )
    elif name == 'web':
        # Node.js service
        docker_build(
            name + '-image',
            path,
            dockerfile=path + '/Dockerfile',
            live_update=[
                sync(path + '/src', '/app/src'),
                run('cd /app && npm install', trigger=[path + '/package.json']),
                run('cd /app && npm run build', trigger=[path + '/webpack.config.js']),
                restart_container(),
            ],
        )
    elif name == 'auth':
        # Python service
        docker_build(
            name + '-image',
            path,
            dockerfile=path + '/Dockerfile',
            live_update=[
                sync(path + '/app', '/app'),
                run('pip install -r requirements.txt', trigger=[path + '/requirements.txt']),
                restart_container(),
            ],
        )
    
    # Deploy Kubernetes manifests
    yaml_path = path + '/kubernetes/' + environment + '.yaml'
    if not os.path.exists(yaml_path):
        yaml_path = path + '/kubernetes/deployment.yaml'
    
    k8s_yaml(yaml_path)
    
    # Configure resource
    k8s_resource(
        name,
        port_forwards=settings.get('port_forwards', []),
        labels=[name, settings.get('type', 'service')],
        resource_deps=settings.get('deps', []),
    )

# Set up each service
setup_service('api', './services/api')
setup_service('web', './services/web')
setup_service('worker', './services/worker')
setup_service('auth', './services/auth')

# Set dependencies between services
if 'api' in services_to_run and 'auth' in services_to_run:
    k8s_resource('api', resource_deps=['auth'])
if 'web' in services_to_run and 'api' in services_to_run:
    k8s_resource('web', resource_deps=['api'])

# Deploy database if needed
if 'database' in services_to_run:
    # Use local_resource for database migrations if needed
    local_resource(
        'db-migrations',
        './scripts/run-migrations.sh',
        deps=['./migrations'],
        resource_deps=['database'],
        auto_init=True,
    )
    
    k8s_yaml('./services/database/kubernetes/deployment.yaml')
    k8s_resource(
        'database',
        port_forwards='5432:5432',
        labels=['database', 'storage'],
        pod_readiness='wait',
    )

# Deploy Redis if needed
if 'redis' in services_to_run:
    helm_remote(
        'redis',
        repo_name='bitnami',
        repo_url='https://charts.bitnami.com/bitnami',
        release_name='redis',
        namespace=namespace,
        values=['./services/redis/values.yaml'],
    )
    
    k8s_resource(
        'redis-master',
        port_forwards='6379:6379',
        labels=['redis', 'cache'],
    )

# Set up local development tools
local_resource(
    'dev-tools',
    'scripts/setup-dev-tools.sh',
    auto_init=False,
    trigger_mode=TRIGGER_MODE_MANUAL,
    labels=['tools'],
)

# Create a health-check resource
local_resource(
    'health-check',
    'scripts/health-check.sh',
    auto_init=False,
    trigger_mode=TRIGGER_MODE_MANUAL,
    labels=['tools'],
)

# Print helpful information
local('echo "Tilt configuration loaded for environment: ' + environment + '"')
local('echo "Services enabled: ' + ', '.join(services_to_run) + '"')
```

## Bonus: Testing and CI Integration

This example shows how to integrate testing and CI workflows with Tilt:

```python
# Run tests whenever source files change
local_resource(
    'unit-tests',
    'cd ./src && go test ./...',
    deps=['./src'],
    trigger_mode=TRIGGER_MODE_AUTO,
    labels=['tests'],
)

# Configure continuous integration settings
ci_settings(
    k8s_grace_period='2m',
    timeout='30m',
)

# Run integration tests manually
local_resource(
    'integration-tests',
    'cd ./tests && ./run-integration-tests.sh',
    trigger_mode=TRIGGER_MODE_MANUAL,
    auto_init=False,
    labels=['tests'],
)

# Lint code
local_resource(
    'lint',
    'cd ./src && golangci-lint run',
    deps=['./src'],
    trigger_mode=TRIGGER_MODE_MANUAL,
    auto_init=False,
    labels=['tests'],
)

# Security scan
local_resource(
    'security-scan',
    'cd ./src && gosec ./...',
    deps=['./src'],
    trigger_mode=TRIGGER_MODE_MANUAL,
    auto_init=False,
    labels=['security'],
)
```

These examples provide a comprehensive overview of modern Tiltfile configuration options and best practices for 2025. By adapting these patterns to your specific use case, you can create an efficient and productive development environment for your microservices applications.
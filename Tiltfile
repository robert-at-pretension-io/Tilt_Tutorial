
# Allow for longer timeouts since Istio can take time to install
update_settings()
k8s_kind('AuthorizationPolicy', api_version='security.istio.io/v1beta1')
k8s_kind('RequestAuthentication', api_version='security.istio.io/v1beta1')
k8s_kind('Gateway', api_version='networking.istio.io/v1beta1')
k8s_kind('VirtualService', api_version='networking.istio.io/v1beta1')

# Function to install Istio using Helm
def install_istio():
    # Add Istio helm repository
    local('helm repo add istio https://istio-release.storage.googleapis.com/charts')
    local('helm repo update')

    # Create namespaces if they don't exist
    local('kubectl create namespace istio-system --dry-run=client -o yaml | kubectl apply -f -')
    local('kubectl create namespace istio-ingress --dry-run=client -o yaml | kubectl apply -f -')
    local('kubectl create namespace keycloak --dry-run=client -o yaml | kubectl apply -f -')
    
    # Install Istio CRDs first
    local('kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.17/manifests/charts/base/crds/crd-all.gen.yaml')
    
    # Install Istio base
    istio_base_yaml = local(
        'helm template istio-base istio/base --namespace istio-system --version 1.17.1 -f manifests/istio/base-values.yaml',
        quiet=True
    )
    k8s_yaml(istio_base_yaml)

    # Install Istio discovery (istiod)
    istiod_yaml = local(
        'helm template istiod istio/istiod --namespace istio-system --version 1.17.1 -f manifests/istio/istiod-values.yaml',
        quiet=True
    )
    k8s_yaml(istiod_yaml)

    # Install Istio ingress gateway
    istio_ingress_yaml = local(
        'helm template istio-ingress istio/gateway --namespace istio-ingress --version 1.17.1 -f manifests/istio/gateway-values.yaml',
        quiet=True
    )
    k8s_yaml(istio_ingress_yaml)

    # Set resource dependencies for proper order
    k8s_resource('istiod', resource_deps=['istio-base'], labels=['istio', 'setup'])
    k8s_resource('istio-ingress', resource_deps=['istiod'], labels=['istio', 'setup'])


# Install Istio
install_istio()

# Function to install Keycloak using Helm
def install_keycloak():
    # Add Bitnami repository (contains Keycloak chart)
    local('helm repo add bitnami https://charts.bitnami.com/bitnami')
    local('helm repo update')

    # Install Keycloak
    # Install Keycloak
    k8s_yaml(local(
        'helm template keycloak bitnami/keycloak --namespace keycloak -f manifests/keycloak/values-override.yaml',
        quiet=True
    ))

    # Configure Keycloak resource in Tilt
    k8s_resource(
        'keycloak',
        port_forwards=['8080:8080'],  # Forward Keycloak admin console
        resource_deps=['istio-ingress'],  # Ensure Istio is ready first
        labels=['auth']
    )

# Install Keycloak
install_keycloak()

# Add Istio authentication configuration for Keycloak
def configure_auth():
    # Create authentication policy
    k8s_yaml('manifests/auth/request-authentication.yaml')
    k8s_yaml('manifests/auth/authorization-policy.yaml')
    
    # Create Istio Gateway and VirtualService for your applications
    k8s_yaml('manifests/auth/gateway.yaml')
    
    # Configure resources with their names from the YAML files
    k8s_resource(
        'auth-policy',
        resource_deps=['jwt-auth'],
        labels=['auth', 'istio']
    )
    
    k8s_resource(
        'jwt-auth',
        labels=['auth', 'istio']
    )
    
    k8s_resource(
        'app-gateway',
        labels=['auth', 'istio']
    )
    
    # Also reference the VirtualService
    k8s_resource(
        'keycloak-vs',
        labels=['auth', 'istio']
    )

# Configure authentication
configure_auth()

# Build and deploy a sample application
docker_build('sample-app', './services/sample-app')
k8s_yaml('services/sample-app/k8s/deployment.yaml')

# Configure the sample app resource
k8s_resource(
    'sample-app',
    port_forwards=['3000:3000'],
    resource_deps=['jwt-auth', 'auth-policy', 'app-gateway'],
    labels=['app']
)

# Set up Keycloak configuration
local_resource(
    'setup-keycloak',
    cmd='./scripts/setup-keycloak.sh',
    resource_deps=['keycloak'],
    auto_init=False,  # Manual trigger is safer for this setup
    labels=['auth', 'setup']
)

# Group resources for better organization in the Tilt UI
config.define_string_list("resource_group", args=True)
cfg = config.parse()
resource_group = cfg.get('resource_group', [])

if len(resource_group) > 0:
    print("Showing resource group: " + str(resource_group))
    config.set_enabled_resources(resource_group)

#!/bin/bash

# Interactive Setup Script for New Linux VM
# This script lets you choose which components to install

set -e  # Exit on error

# Color codes for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Installation mode: missing, fresh, or update
INSTALL_MODE="missing"

# Installation flags
INSTALL_DOCKER=false
INSTALL_CLAUDE=false
INSTALL_CODERABBIT=false
INSTALL_GIT=false
INSTALL_NODEJS=false
INSTALL_PYTHON=false
INSTALL_GOLANG=false
INSTALL_K8S_TOOLS=false
INSTALL_TERRAFORM=false
INSTALL_BUILD_TOOLS=false
INSTALL_CLI_UTILS=false
INSTALL_AZURE_CLI=false
INSTALL_AWS_CLI=false
INSTALL_GCP_CLI=false

# Helper function to ask yes/no questions
ask_yes_no() {
    local prompt="$1"
    local response
    while true; do
        read -p "$prompt [Y/n]: " response
        response=${response,,}  # Convert to lowercase
        if [[ -z "$response" || "$response" == "y" || "$response" == "yes" ]]; then
            return 0
        elif [[ "$response" == "n" || "$response" == "no" ]]; then
            return 1
        else
            echo "Please answer Y or n"
        fi
    done
}

# Function to select installation mode
select_install_mode() {
    if command -v whiptail &> /dev/null; then
        # Use whiptail for mode selection
        MODE_CHOICE=$(whiptail --title "Installation Mode" --menu \
            "Choose how to handle existing installations:" 20 78 3 \
            "1" "Install Missing Only - Skip already installed tools (Recommended)" \
            "2" "Fresh Install - Uninstall and reinstall all selected components" \
            "3" "Update Existing - Update installed tools to latest versions" \
            3>&1 1>&2 2>&3)

        if [ $? -eq 0 ]; then
            case $MODE_CHOICE in
                1)
                    INSTALL_MODE="missing"
                    echo -e "${GREEN}Mode: Install Missing Only${NC}"
                    ;;
                2)
                    INSTALL_MODE="fresh"
                    echo -e "${YELLOW}Mode: Fresh Install (will uninstall existing)${NC}"
                    ;;
                3)
                    INSTALL_MODE="update"
                    echo -e "${BLUE}Mode: Update Existing + Install Missing${NC}"
                    ;;
            esac
        else
            echo "Installation cancelled."
            exit 0
        fi
    else
        # Fallback to text-based mode selection
        echo ""
        echo "=========================================="
        echo "Select Installation Mode"
        echo "=========================================="
        echo ""
        echo "1) Install Missing Only (default)"
        echo "   - Skip already installed tools"
        echo "   - Only install what's missing"
        echo "   - Fastest, safest option"
        echo ""
        echo "2) Fresh Install (Reinstall All)"
        echo "   - Uninstall existing versions first"
        echo "   - Clean install of selected components"
        echo "   - Useful for fixing broken installations"
        echo ""
        echo "3) Update Existing + Install Missing"
        echo "   - Update already installed tools"
        echo "   - Install missing components"
        echo "   - Best for keeping system current"
        echo ""

        while true; do
            read -p "Enter your choice [1-3] (default: 1): " mode_choice
            mode_choice=${mode_choice:-1}

            case $mode_choice in
                1)
                    INSTALL_MODE="missing"
                    echo -e "${GREEN}Mode: Install Missing Only${NC}"
                    break
                    ;;
                2)
                    INSTALL_MODE="fresh"
                    echo -e "${YELLOW}Mode: Fresh Install (will uninstall existing)${NC}"
                    break
                    ;;
                3)
                    INSTALL_MODE="update"
                    echo -e "${BLUE}Mode: Update Existing + Install Missing${NC}"
                    break
                    ;;
                *)
                    echo "Invalid choice. Please enter 1, 2, or 3."
                    ;;
            esac
        done
    fi
}

# Uninstall functions
uninstall_docker() {
    echo "Uninstalling Docker..."
    sudo systemctl stop docker 2>/dev/null || true
    sudo apt-get remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
    sudo rm -rf /var/lib/docker /etc/docker
    sudo groupdel docker 2>/dev/null || true
}

uninstall_nodejs() {
    echo "Uninstalling Node.js..."
    sudo apt-get remove -y nodejs 2>/dev/null || true
    sudo rm -rf /etc/apt/sources.list.d/nodesource.list /usr/share/keyrings/nodesource.gpg
}

uninstall_python() {
    echo "Uninstalling Python (user-installed packages only)..."
    # Don't remove system python, just user packages
    pip3 uninstall -y -r <(pip3 freeze) 2>/dev/null || true
}

uninstall_golang() {
    echo "Uninstalling Go..."
    sudo rm -rf /usr/local/go
    # Remove PATH entries from bashrc (user will need to do manually or we preserve them)
}

uninstall_kubectl() {
    echo "Uninstalling kubectl..."
    sudo rm -f /usr/local/bin/kubectl
}

uninstall_helm() {
    echo "Uninstalling Helm..."
    sudo rm -f /usr/local/bin/helm
}

uninstall_k9s() {
    echo "Uninstalling k9s..."
    sudo rm -f /usr/local/bin/k9s
}

uninstall_terraform() {
    echo "Uninstalling Terraform..."
    sudo apt-get remove -y terraform 2>/dev/null || true
    sudo rm -f /etc/apt/sources.list.d/hashicorp.list /usr/share/keyrings/hashicorp-archive-keyring.gpg
}

uninstall_azure_cli() {
    echo "Uninstalling Azure CLI..."
    sudo apt-get remove -y azure-cli 2>/dev/null || true
}

uninstall_aws_cli() {
    echo "Uninstalling AWS CLI..."
    sudo rm -rf /usr/local/aws-cli /usr/local/bin/aws /usr/local/bin/aws_completer
}

uninstall_gcp_cli() {
    echo "Uninstalling Google Cloud SDK..."
    sudo apt-get remove -y google-cloud-cli 2>/dev/null || true
    sudo rm -f /etc/apt/sources.list.d/google-cloud-sdk.list /usr/share/keyrings/cloud.google.gpg
}

uninstall_git() {
    echo "Uninstalling Git and GitHub CLI..."
    sudo apt-get remove -y git gh 2>/dev/null || true
}

# Update functions
update_docker() {
    echo "Updating Docker..."
    sudo apt-get update
    sudo apt-get install --only-upgrade -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

update_nodejs() {
    echo "Updating Node.js..."
    # Re-run NodeSource setup to get latest LTS
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install --only-upgrade -y nodejs
}

update_python() {
    echo "Updating Python..."
    sudo apt-get update
    sudo apt-get install --only-upgrade -y python3 python3-pip python3-venv
}

update_golang() {
    echo "Updating Go..."
    # Get latest version
    GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n 1)
    if [[ -z "$GO_VERSION" ]]; then
        echo "Could not fetch latest Go version"
        return 1
    fi

    CURRENT_VERSION=$(/usr/local/go/bin/go version 2>/dev/null | awk '{print $3}')
    if [[ "$CURRENT_VERSION" == "$GO_VERSION" ]]; then
        echo "Go is already at latest version ($GO_VERSION)"
        return 0
    fi

    # Reinstall with latest version
    GO_TARBALL="${GO_VERSION}.linux-amd64.tar.gz"
    curl -LO "https://go.dev/dl/${GO_TARBALL}"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "${GO_TARBALL}"
    rm "${GO_TARBALL}"
    echo "Go updated to $GO_VERSION"
}

update_kubectl() {
    echo "Updating kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
}

update_helm() {
    echo "Updating Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
}

update_k9s() {
    echo "Updating k9s..."
    K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    if [[ -z "$K9S_VERSION" ]]; then
        K9S_VERSION="v0.32.4"
    fi
    curl -sL https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz | sudo tar xvz -C /usr/local/bin k9s
}

update_terraform() {
    echo "Updating Terraform..."
    sudo apt-get update
    sudo apt-get install --only-upgrade -y terraform
}

update_azure_cli() {
    echo "Updating Azure CLI..."
    sudo apt-get update
    sudo apt-get install --only-upgrade -y azure-cli
}

update_aws_cli() {
    echo "Updating AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install --update
    rm -rf aws awscliv2.zip
}

update_gcp_cli() {
    echo "Updating Google Cloud SDK..."
    sudo apt-get update
    sudo apt-get install --only-upgrade -y google-cloud-cli
}

update_git() {
    echo "Updating Git and GitHub CLI..."
    sudo apt-get update
    sudo apt-get install --only-upgrade -y git gh
}

echo "=========================================="
echo "Interactive VM Setup"
echo "=========================================="
echo ""

# Check if running with sudo privileges
if ! sudo -n true 2>/dev/null; then
    echo "This script requires sudo privileges."
    echo "Please run: sudo -v"
    echo "Then run this script again."
    exit 1
fi

# Check internet connectivity
if ! ping -c 1 8.8.8.8 &> /dev/null && ! ping -c 1 1.1.1.1 &> /dev/null; then
    echo -e "${YELLOW}Warning: Internet connectivity check failed.${NC}"
    echo "This script requires internet access to download packages."
    if ! ask_yes_no "Continue anyway?"; then
        exit 1
    fi
fi

# Check available disk space (need at least 5GB free)
AVAILABLE_SPACE=$(df / | tail -1 | awk '{print $4}')
REQUIRED_SPACE=$((5 * 1024 * 1024))  # 5GB in KB
if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
    echo -e "${YELLOW}Warning: Low disk space detected.${NC}"
    echo "Available: $(($AVAILABLE_SPACE / 1024 / 1024))GB, Recommended: 5GB+"
    if ! ask_yes_no "Continue anyway?"; then
        exit 1
    fi
fi

echo "This script will help you set up your development environment."
echo ""

# Install whiptail for better UI if not already installed
if ! command -v whiptail &> /dev/null; then
    echo "Installing whiptail for interactive UI..."
    sudo apt-get install -y whiptail >/dev/null 2>&1
fi

# Select installation mode
select_install_mode

echo ""
echo "Please select which components you want to install."
echo ""

# Use whiptail for component selection if available
if command -v whiptail &> /dev/null; then
    # Build checklist options
    CHOICES=$(whiptail --title "Component Selection" --checklist \
        "Use SPACE to select/deselect, ARROW keys to navigate, ENTER to confirm" 20 78 13 \
        "DOCKER" "Docker (docker-ce, docker-compose, buildx)" OFF \
        "CLAUDE" "Claude CLI" OFF \
        "CODERABBIT" "CodeRabbit CLI" OFF \
        "GIT" "Git + GitHub CLI (gh)" OFF \
        "NODEJS" "Node.js + npm (LTS version)" OFF \
        "PYTHON" "Python 3 + pip + venv" OFF \
        "GOLANG" "Go (latest stable version)" OFF \
        "K8S_TOOLS" "Kubernetes tools (kubectl, helm, k9s)" OFF \
        "TERRAFORM" "Terraform (latest stable version)" OFF \
        "AZURE_CLI" "Azure CLI (az)" OFF \
        "AWS_CLI" "AWS CLI v2" OFF \
        "GCP_CLI" "Google Cloud SDK (gcloud)" OFF \
        "BUILD_TOOLS" "Build essentials (gcc, make, build-essential)" OFF \
        "CLI_UTILS" "CLI utilities (wget, tree, jq, htop, vim)" OFF \
        3>&1 1>&2 2>&3)

    # Check if user cancelled
    if [ $? -eq 0 ]; then
        # Parse selections
        [[ $CHOICES == *"DOCKER"* ]] && INSTALL_DOCKER=true
        [[ $CHOICES == *"CLAUDE"* ]] && INSTALL_CLAUDE=true
        [[ $CHOICES == *"CODERABBIT"* ]] && INSTALL_CODERABBIT=true
        [[ $CHOICES == *"GIT"* ]] && INSTALL_GIT=true
        [[ $CHOICES == *"NODEJS"* ]] && INSTALL_NODEJS=true
        [[ $CHOICES == *"PYTHON"* ]] && INSTALL_PYTHON=true
        [[ $CHOICES == *"GOLANG"* ]] && INSTALL_GOLANG=true
        [[ $CHOICES == *"K8S_TOOLS"* ]] && INSTALL_K8S_TOOLS=true
        [[ $CHOICES == *"TERRAFORM"* ]] && INSTALL_TERRAFORM=true
        [[ $CHOICES == *"AZURE_CLI"* ]] && INSTALL_AZURE_CLI=true
        [[ $CHOICES == *"AWS_CLI"* ]] && INSTALL_AWS_CLI=true
        [[ $CHOICES == *"GCP_CLI"* ]] && INSTALL_GCP_CLI=true
        [[ $CHOICES == *"BUILD_TOOLS"* ]] && INSTALL_BUILD_TOOLS=true
        [[ $CHOICES == *"CLI_UTILS"* ]] && INSTALL_CLI_UTILS=true
    else
        echo "Installation cancelled."
        exit 0
    fi
else
    # Fallback to text-based prompts if whiptail is not available
    echo -e "${BLUE}=== Core Development Tools ===${NC}"
    if ask_yes_no "Install Docker (docker-ce, docker-compose, buildx)?"; then
        INSTALL_DOCKER=true
    fi

    if ask_yes_no "Install Claude CLI?"; then
        INSTALL_CLAUDE=true
    fi

    if ask_yes_no "Install CodeRabbit CLI?"; then
        INSTALL_CODERABBIT=true
    fi

    echo ""
    echo -e "${BLUE}=== Version Control ===${NC}"
    if ask_yes_no "Install Git + GitHub CLI (gh)?"; then
        INSTALL_GIT=true
    fi

    echo ""
    echo -e "${BLUE}=== Programming Languages & Runtimes ===${NC}"
    if ask_yes_no "Install Node.js + npm (LTS version)?"; then
        INSTALL_NODEJS=true
    fi

    if ask_yes_no "Install Python 3 + pip + venv?"; then
        INSTALL_PYTHON=true
    fi

    if ask_yes_no "Install Go (latest stable version)?"; then
        INSTALL_GOLANG=true
    fi

    echo ""
    echo -e "${BLUE}=== Kubernetes & Container Tools ===${NC}"
    if ask_yes_no "Install Kubernetes tools (kubectl, helm, k9s)?"; then
        INSTALL_K8S_TOOLS=true
    fi

    echo ""
    echo -e "${BLUE}=== Infrastructure as Code ===${NC}"
    if ask_yes_no "Install Terraform (latest stable version)?"; then
        INSTALL_TERRAFORM=true
    fi

    echo ""
    echo -e "${BLUE}=== Cloud Provider Tools ===${NC}"
    if ask_yes_no "Install Azure CLI (az)?"; then
        INSTALL_AZURE_CLI=true
    fi

    if ask_yes_no "Install AWS CLI v2?"; then
        INSTALL_AWS_CLI=true
    fi

    if ask_yes_no "Install Google Cloud SDK (gcloud)?"; then
        INSTALL_GCP_CLI=true
    fi

    echo ""
    echo -e "${BLUE}=== Build & Development Utilities ===${NC}"
    if ask_yes_no "Install build essentials (gcc, make, build-essential)?"; then
        INSTALL_BUILD_TOOLS=true
    fi

    if ask_yes_no "Install CLI utilities (wget, tree, jq, htop, vim)?"; then
        INSTALL_CLI_UTILS=true
    fi
fi

# Show summary
echo ""
echo "=========================================="
echo "Installation Summary"
echo "=========================================="
echo ""

# Build summary list
SUMMARY="The following will be installed:\n\n"
SUMMARY+="  - System updates (always)\n"
SUMMARY+="  - Basic dependencies\n"
[[ $INSTALL_DOCKER == true ]] && SUMMARY+="  - Docker + Docker Compose\n"
[[ $INSTALL_CLAUDE == true ]] && SUMMARY+="  - Claude CLI\n"
[[ $INSTALL_CODERABBIT == true ]] && SUMMARY+="  - CodeRabbit CLI\n"
[[ $INSTALL_GIT == true ]] && SUMMARY+="  - Git + GitHub CLI\n"
[[ $INSTALL_NODEJS == true ]] && SUMMARY+="  - Node.js + npm\n"
[[ $INSTALL_PYTHON == true ]] && SUMMARY+="  - Python 3 + pip + venv\n"
[[ $INSTALL_GOLANG == true ]] && SUMMARY+="  - Go (latest stable)\n"
[[ $INSTALL_K8S_TOOLS == true ]] && SUMMARY+="  - Kubernetes tools (kubectl, helm, k9s)\n"
[[ $INSTALL_TERRAFORM == true ]] && SUMMARY+="  - Terraform (latest stable)\n"
[[ $INSTALL_AZURE_CLI == true ]] && SUMMARY+="  - Azure CLI\n"
[[ $INSTALL_AWS_CLI == true ]] && SUMMARY+="  - AWS CLI v2\n"
[[ $INSTALL_GCP_CLI == true ]] && SUMMARY+="  - Google Cloud SDK\n"
[[ $INSTALL_BUILD_TOOLS == true ]] && SUMMARY+="  - Build essentials\n"
[[ $INSTALL_CLI_UTILS == true ]] && SUMMARY+="  - CLI utilities\n"

# Display summary and confirm
if command -v whiptail &> /dev/null; then
    if ! whiptail --title "Installation Summary" --yesno "$SUMMARY\nProceed with installation?" 20 78; then
        echo "Installation cancelled."
        exit 0
    fi
else
    echo -e "$SUMMARY"
    if ! ask_yes_no "Proceed with installation?"; then
        echo "Installation cancelled."
        exit 0
    fi
fi

# Start installation
echo ""
echo "=========================================="
echo "Starting Installation"
echo "=========================================="

STEP=1
TOTAL_STEPS=2  # Base steps (update + dependencies)
[[ $INSTALL_DOCKER == true ]] && ((TOTAL_STEPS++))
[[ $INSTALL_CLAUDE == true ]] && ((TOTAL_STEPS++))
[[ $INSTALL_CODERABBIT == true ]] && ((TOTAL_STEPS++))
[[ $INSTALL_GIT == true ]] && ((TOTAL_STEPS++))
[[ $INSTALL_NODEJS == true ]] && ((TOTAL_STEPS++))
[[ $INSTALL_PYTHON == true ]] && ((TOTAL_STEPS++))
[[ $INSTALL_GOLANG == true ]] && ((TOTAL_STEPS++))
[[ $INSTALL_K8S_TOOLS == true ]] && ((TOTAL_STEPS++))
[[ $INSTALL_TERRAFORM == true ]] && ((TOTAL_STEPS++))
[[ $INSTALL_AZURE_CLI == true ]] && ((TOTAL_STEPS++))
[[ $INSTALL_AWS_CLI == true ]] && ((TOTAL_STEPS++))
[[ $INSTALL_GCP_CLI == true ]] && ((TOTAL_STEPS++))
[[ $INSTALL_BUILD_TOOLS == true ]] && ((TOTAL_STEPS++))
[[ $INSTALL_CLI_UTILS == true ]] && ((TOTAL_STEPS++))

# Update system packages
echo ""
echo -e "${GREEN}[$STEP/$TOTAL_STEPS] Updating system packages...${NC}"
((STEP++))
sudo apt-get update
sudo apt-get upgrade -y

# Install base dependencies
echo ""
echo -e "${GREEN}[$STEP/$TOTAL_STEPS] Installing base dependencies...${NC}"
((STEP++))
sudo apt-get install -y ca-certificates curl unzip tar gpg sed wget apt-transport-https gnupg lsb-release whiptail

# Install Docker
if [[ $INSTALL_DOCKER == true ]]; then
    echo ""
    echo -e "${GREEN}[$STEP/$TOTAL_STEPS] Installing Docker...${NC}"
    ((STEP++))

    if command -v docker &> /dev/null; then
        # Docker is already installed
        if [[ $INSTALL_MODE == "fresh" ]]; then
            uninstall_docker
        elif [[ $INSTALL_MODE == "update" ]]; then
            update_docker
            echo "Docker updated to $(docker --version)"
            ((STEP++))
            continue
        else
            echo "Docker is already installed ($(docker --version)), skipping"
            continue
        fi
    fi

    # Install Docker (fresh install or after uninstall)
    # Uninstall conflicting packages
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
        sudo apt-get remove -y $pkg 2>/dev/null || true
    done

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update

    # Install Docker packages
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker

    # Add user to docker group
    sudo usermod -aG docker $USER

    echo "Docker installed successfully"
    echo -e "${YELLOW}Note: You've been added to the 'docker' group${NC}"
fi

# Install Claude CLI
if [[ $INSTALL_CLAUDE == true ]]; then
    echo ""
    echo -e "${GREEN}[$STEP/$TOTAL_STEPS] Installing Claude CLI...${NC}"
    ((STEP++))

    if ! command -v claude &> /dev/null; then
        curl -fsSL https://claude.ai/install.sh | bash
        source ~/.bashrc
        echo "Claude CLI installed successfully"
    else
        echo "Claude CLI is already installed"
    fi
fi

# Install CodeRabbit CLI
if [[ $INSTALL_CODERABBIT == true ]]; then
    echo ""
    echo -e "${GREEN}[$STEP/$TOTAL_STEPS] Installing CodeRabbit CLI...${NC}"
    ((STEP++))

    if ! command -v coderabbit &> /dev/null; then
        curl -fsSL https://cli.coderabbit.ai/install.sh | sh
        echo "CodeRabbit CLI installed successfully"
    else
        echo "CodeRabbit CLI is already installed"
    fi
fi

# Install Git + GitHub CLI
if [[ $INSTALL_GIT == true ]]; then
    echo ""
    echo -e "${GREEN}[$STEP/$TOTAL_STEPS] Installing Git + GitHub CLI...${NC}"
    ((STEP++))

    # Install Git
    sudo apt-get install -y git

    # Install GitHub CLI
    if ! command -v gh &> /dev/null; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y gh
        echo "Git and GitHub CLI installed successfully"
    else
        echo "Git and GitHub CLI are already installed"
    fi
fi

# Install build tools (before Node.js to support native module compilation)
if [[ $INSTALL_BUILD_TOOLS == true ]]; then
    echo ""
    echo -e "${GREEN}[$STEP/$TOTAL_STEPS] Installing build essentials...${NC}"
    ((STEP++))

    sudo apt-get install -y build-essential gcc make
    echo "Build tools installed successfully"
fi

# Install Node.js
if [[ $INSTALL_NODEJS == true ]]; then
    echo ""
    echo -e "${GREEN}[$STEP/$TOTAL_STEPS] Installing Node.js + npm...${NC}"
    ((STEP++))

    if command -v node &> /dev/null; then
        # Node.js is already installed
        if [[ $INSTALL_MODE == "fresh" ]]; then
            uninstall_nodejs
        elif [[ $INSTALL_MODE == "update" ]]; then
            update_nodejs
            echo "Node.js updated to $(node --version)"
        else
            echo "Node.js is already installed ($(node --version)), skipping"
        fi
    fi

    # Install Node.js if not installed or after fresh uninstall
    if ! command -v node &> /dev/null || [[ $INSTALL_MODE == "fresh" ]]; then
        # Install Node.js LTS via NodeSource
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
        echo "Node.js $(node --version) and npm $(npm --version) installed successfully"

        # Install pnpm globally
        echo "Installing pnpm..."
        npm install -g pnpm
        echo "pnpm $(pnpm --version) installed successfully"
    elif command -v node &> /dev/null && ! command -v pnpm &> /dev/null; then
        # Node.js exists but pnpm doesn't - install pnpm
        echo "Installing pnpm..."
        npm install -g pnpm
        echo "pnpm $(pnpm --version) installed successfully"
    fi
fi

# Install Python
if [[ $INSTALL_PYTHON == true ]]; then
    echo ""
    echo -e "${GREEN}[$STEP/$TOTAL_STEPS] Installing Python 3 + pip + venv...${NC}"
    ((STEP++))

    if command -v python3 &> /dev/null && dpkg -l | grep -q python3-pip; then
        # Python is already installed
        if [[ $INSTALL_MODE == "update" ]]; then
            update_python
            echo "Python updated to $(python3 --version)"
        else
            echo "Python is already installed ($(python3 --version)), skipping"
        fi
    else
        sudo apt-get install -y python3 python3-pip python3-venv
        echo "Python $(python3 --version) installed successfully"
    fi
fi

# Install Go
if [[ $INSTALL_GOLANG == true ]]; then
    echo ""
    echo -e "${GREEN}[$STEP/$TOTAL_STEPS] Installing Go...${NC}"
    ((STEP++))

    if command -v go &> /dev/null; then
        # Go is already installed
        if [[ $INSTALL_MODE == "fresh" ]]; then
            uninstall_golang
        elif [[ $INSTALL_MODE == "update" ]]; then
            update_golang
        else
            echo "Go is already installed ($(go version | awk '{print $3}'))), skipping"
        fi
    fi

    # Install Go if not installed or after fresh uninstall
    if ! command -v go &> /dev/null || [[ $INSTALL_MODE == "fresh" ]]; then
        # Get the latest stable Go version
        GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n 1)

        # Fallback to a known stable version if API fails
        if [[ -z "$GO_VERSION" ]]; then
            GO_VERSION="go1.23.1"
            echo "Warning: Could not fetch latest Go version, using ${GO_VERSION}"
        fi

        GO_TARBALL="${GO_VERSION}.linux-amd64.tar.gz"

        # Download and install Go
        curl -LO "https://go.dev/dl/${GO_TARBALL}"
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "${GO_TARBALL}"
        rm "${GO_TARBALL}"

        # Add Go to PATH in .bashrc if not already there
        if ! grep -q '/usr/local/go/bin' ~/.bashrc; then
            echo '' >> ~/.bashrc
            echo '# Go language' >> ~/.bashrc
            echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
            echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
        fi

        export PATH=$PATH:/usr/local/go/bin
        echo "Go $(/usr/local/go/bin/go version | awk '{print $3}') installed successfully"
    fi
fi

# Install Kubernetes tools
if [[ $INSTALL_K8S_TOOLS == true ]]; then
    echo ""
    echo -e "${GREEN}[$STEP/$TOTAL_STEPS] Installing Kubernetes tools...${NC}"
    ((STEP++))

    # Install kubectl
    if ! command -v kubectl &> /dev/null; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
        echo "kubectl installed successfully"
    else
        echo "kubectl is already installed"
    fi

    # Install Helm
    if ! command -v helm &> /dev/null; then
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        echo "Helm installed successfully"
    else
        echo "Helm is already installed"
    fi

    # Install k9s
    if ! command -v k9s &> /dev/null; then
        K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

        # Fallback to a known stable version if API fails
        if [[ -z "$K9S_VERSION" ]]; then
            K9S_VERSION="v0.32.4"
            echo "Warning: Could not fetch latest k9s version, using ${K9S_VERSION}"
        fi

        curl -sL https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz | sudo tar xvz -C /usr/local/bin k9s
        echo "k9s installed successfully"
    else
        echo "k9s is already installed"
    fi
fi

# Install Terraform
if [[ $INSTALL_TERRAFORM == true ]]; then
    echo ""
    echo -e "${GREEN}[$STEP/$TOTAL_STEPS] Installing Terraform...${NC}"
    ((STEP++))

    if command -v terraform &> /dev/null; then
        # Terraform is already installed
        if [[ $INSTALL_MODE == "fresh" ]]; then
            uninstall_terraform
        elif [[ $INSTALL_MODE == "update" ]]; then
            update_terraform
            echo "Terraform updated to $(terraform --version | head -n 1 | awk '{print $2}')"
        else
            echo "Terraform is already installed ($(terraform --version | head -n 1 | awk '{print $2}'))), skipping"
        fi
    fi

    # Install Terraform if not installed or after fresh uninstall
    if ! command -v terraform &> /dev/null || [[ $INSTALL_MODE == "fresh" ]]; then
        # Add HashiCorp GPG key
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

        # Add HashiCorp repository
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

        # Update and install Terraform
        sudo apt-get update
        sudo apt-get install -y terraform

        echo "Terraform $(terraform --version | head -n 1 | awk '{print $2}') installed successfully"
    fi
fi

# Install Azure CLI
if [[ $INSTALL_AZURE_CLI == true ]]; then
    echo ""
    echo -e "${GREEN}[$STEP/$TOTAL_STEPS] Installing Azure CLI...${NC}"
    ((STEP++))

    if ! command -v az &> /dev/null; then
        # Install Azure CLI via Microsoft's official repository
        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
        echo "Azure CLI installed successfully"
    else
        echo "Azure CLI is already installed ($(az version --output tsv --query '\"azure-cli\"' 2>/dev/null || echo 'installed'))"
    fi
fi

# Install AWS CLI
if [[ $INSTALL_AWS_CLI == true ]]; then
    echo ""
    echo -e "${GREEN}[$STEP/$TOTAL_STEPS] Installing AWS CLI v2...${NC}"
    ((STEP++))

    if ! command -v aws &> /dev/null; then
        # Download and install AWS CLI v2
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip -q awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
        echo "AWS CLI v2 installed successfully"
    else
        echo "AWS CLI is already installed ($(aws --version))"
    fi
fi

# Install Google Cloud SDK
if [[ $INSTALL_GCP_CLI == true ]]; then
    echo ""
    echo -e "${GREEN}[$STEP/$TOTAL_STEPS] Installing Google Cloud SDK...${NC}"
    ((STEP++))

    if ! command -v gcloud &> /dev/null; then
        # Install Google Cloud SDK via official repository
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
        sudo apt-get update
        sudo apt-get install -y google-cloud-cli
        echo "Google Cloud SDK installed successfully"
    else
        echo "Google Cloud SDK is already installed ($(gcloud version --format='value(version)' 2>/dev/null || echo 'installed'))"
    fi
fi

# Install CLI utilities
if [[ $INSTALL_CLI_UTILS == true ]]; then
    echo ""
    echo -e "${GREEN}[$STEP/$TOTAL_STEPS] Installing CLI utilities...${NC}"
    ((STEP++))

    sudo apt-get install -y wget tree jq htop vim
    echo "CLI utilities installed successfully"
fi

# Verify Docker installation
if [[ $INSTALL_DOCKER == true ]] && command -v docker &> /dev/null; then
    echo ""
    echo -e "${YELLOW}Verifying Docker installation...${NC}"
    sudo docker run --rm hello-world
fi

# Final system update and cleanup
echo ""
echo "=========================================="
echo "Final System Update & Cleanup"
echo "=========================================="
echo ""
echo -e "${GREEN}Performing final system update...${NC}"
sudo apt-get update
sudo apt-get upgrade -y

echo ""
echo -e "${GREEN}Cleaning up unused packages...${NC}"
sudo apt-get autoremove -y
sudo apt-get autoclean

# Update snap packages if snap is installed
if command -v snap &> /dev/null; then
    echo ""
    echo -e "${GREEN}Updating snap packages...${NC}"
    sudo snap refresh 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}System update and cleanup complete!${NC}"

# Final summary
echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""

# Show manual steps if needed
MANUAL_STEPS=()
[[ $INSTALL_CLAUDE == true ]] && MANUAL_STEPS+=("Configure Claude: code ~/.claude/settings.json")
[[ $INSTALL_CODERABBIT == true ]] && MANUAL_STEPS+=("Login to CodeRabbit: coderabbit auth login")
[[ $INSTALL_GIT == true ]] && MANUAL_STEPS+=("Configure Git: git config --global user.name 'Your Name' && git config --global user.email 'your@email.com'")
[[ $INSTALL_GIT == true ]] && MANUAL_STEPS+=("Login to GitHub CLI: gh auth login")
[[ $INSTALL_AZURE_CLI == true ]] && MANUAL_STEPS+=("Login to Azure: az login")
[[ $INSTALL_AWS_CLI == true ]] && MANUAL_STEPS+=("Configure AWS: aws configure")
[[ $INSTALL_GCP_CLI == true ]] && MANUAL_STEPS+=("Login to Google Cloud: gcloud init")

if [ ${#MANUAL_STEPS[@]} -gt 0 ]; then
    echo "Manual steps still required:"
    for i in "${!MANUAL_STEPS[@]}"; do
        echo "$((i+1)). ${MANUAL_STEPS[$i]}"
    done
    echo ""
fi

# Installation recap with version checks
echo "=========================================="
echo "Installation Recap"
echo "=========================================="
echo ""
echo "Installed components and their versions:"
echo ""

INSTALLED_COMPONENTS=()

if [[ $INSTALL_DOCKER == true ]] && command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version 2>/dev/null)
    echo "✓ Docker: $DOCKER_VERSION"
    INSTALLED_COMPONENTS+=("Docker")
fi

if [[ $INSTALL_CLAUDE == true ]] && command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "installed")
    echo "✓ Claude CLI: $CLAUDE_VERSION"
    INSTALLED_COMPONENTS+=("Claude CLI")
fi

if [[ $INSTALL_CODERABBIT == true ]] && command -v coderabbit &> /dev/null; then
    echo "✓ CodeRabbit CLI: installed"
    INSTALLED_COMPONENTS+=("CodeRabbit CLI")
fi

if [[ $INSTALL_GIT == true ]] && command -v git &> /dev/null; then
    GIT_VERSION=$(git --version 2>/dev/null)
    echo "✓ Git: $GIT_VERSION"
    INSTALLED_COMPONENTS+=("Git")
fi

if [[ $INSTALL_GIT == true ]] && command -v gh &> /dev/null; then
    GH_VERSION=$(gh --version 2>/dev/null | head -n 1)
    echo "✓ GitHub CLI: $GH_VERSION"
    INSTALLED_COMPONENTS+=("GitHub CLI")
fi

if [[ $INSTALL_NODEJS == true ]] && command -v node &> /dev/null; then
    NODE_VERSION=$(node --version 2>/dev/null)
    NPM_VERSION=$(npm --version 2>/dev/null)
    if command -v pnpm &> /dev/null; then
        PNPM_VERSION=$(pnpm --version 2>/dev/null)
        echo "✓ Node.js: $NODE_VERSION (npm: $NPM_VERSION, pnpm: $PNPM_VERSION)"
    else
        echo "✓ Node.js: $NODE_VERSION (npm: $NPM_VERSION)"
    fi
    INSTALLED_COMPONENTS+=("Node.js")
fi

if [[ $INSTALL_PYTHON == true ]] && command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>/dev/null)
    PIP_VERSION=$(pip3 --version 2>/dev/null | awk '{print $2}')
    echo "✓ Python: $PYTHON_VERSION (pip: $PIP_VERSION)"
    INSTALLED_COMPONENTS+=("Python")
fi

if [[ $INSTALL_GOLANG == true ]] && command -v go &> /dev/null; then
    GO_VERSION=$(go version 2>/dev/null | awk '{print $3}')
    echo "✓ Go: $GO_VERSION"
    INSTALLED_COMPONENTS+=("Go")
fi

if [[ $INSTALL_K8S_TOOLS == true ]]; then
    if command -v kubectl &> /dev/null; then
        KUBECTL_VERSION=$(kubectl version --client 2>/dev/null | grep -oP 'v\d+\.\d+\.\d+' | head -n 1 || echo "installed")
        echo "✓ kubectl: $KUBECTL_VERSION"
        INSTALLED_COMPONENTS+=("kubectl")
    fi

    if command -v helm &> /dev/null; then
        HELM_VERSION=$(helm version --short 2>/dev/null)
        echo "✓ Helm: $HELM_VERSION"
        INSTALLED_COMPONENTS+=("Helm")
    fi

    if command -v k9s &> /dev/null; then
        K9S_VERSION=$(k9s version 2>/dev/null | grep "Version" | awk '{print $2}' || echo "installed")
        echo "✓ k9s: $K9S_VERSION"
        INSTALLED_COMPONENTS+=("k9s")
    fi
fi

if [[ $INSTALL_TERRAFORM == true ]] && command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform --version 2>/dev/null | head -n 1)
    echo "✓ Terraform: $TERRAFORM_VERSION"
    INSTALLED_COMPONENTS+=("Terraform")
fi

if [[ $INSTALL_AZURE_CLI == true ]] && command -v az &> /dev/null; then
    AZ_VERSION=$(az version --output tsv --query '"azure-cli"' 2>/dev/null || echo "installed")
    echo "✓ Azure CLI: $AZ_VERSION"
    INSTALLED_COMPONENTS+=("Azure CLI")
fi

if [[ $INSTALL_AWS_CLI == true ]] && command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>/dev/null)
    echo "✓ AWS CLI: $AWS_VERSION"
    INSTALLED_COMPONENTS+=("AWS CLI")
fi

if [[ $INSTALL_GCP_CLI == true ]] && command -v gcloud &> /dev/null; then
    GCLOUD_VERSION=$(gcloud version 2>/dev/null | head -n 1 | awk '{print $NF}')
    echo "✓ Google Cloud SDK: $GCLOUD_VERSION"
    INSTALLED_COMPONENTS+=("Google Cloud SDK")
fi

if [[ $INSTALL_BUILD_TOOLS == true ]] && command -v gcc &> /dev/null; then
    GCC_VERSION=$(gcc -dumpversion 2>/dev/null)
    MAKE_VERSION=$(make --version 2>/dev/null | head -n 1 | grep -oP '\d+\.\d+' | head -n 1)
    echo "✓ Build Tools: gcc $GCC_VERSION, make $MAKE_VERSION"
    INSTALLED_COMPONENTS+=("Build Tools")
fi

if [[ $INSTALL_CLI_UTILS == true ]]; then
    echo "✓ CLI Utilities: wget, tree, jq, htop, vim"
    INSTALLED_COMPONENTS+=("CLI Utilities")
fi

echo ""
echo "Total installed: ${#INSTALLED_COMPONENTS[@]} component(s)"
echo ""

# Important next steps
if [[ $INSTALL_DOCKER == true ]] && command -v docker &> /dev/null; then
    echo "=========================================="
    echo "Important: Docker Group Permissions"
    echo "=========================================="
    echo ""
    echo -e "${YELLOW}To use Docker without sudo, reconnect your SSH session:${NC}"
    echo "  exit"
    echo "  # Then SSH back in"
    echo ""
    echo "After reconnecting, verify Docker works:"
    echo "  docker run hello-world"
    echo ""
fi

echo -e "${GREEN}Setup complete! Happy coding!${NC}"

#!/usr/bin/env bash
#
# Sigil Installer
# curl -fsSL https://sigil.dev/install | sh
#
# Interactive installer for Sigil memory format
#

set -e

VERSION="1.0.0"
INSTALL_URL="https://raw.githubusercontent.com/khaosdoctor/sigil/main"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# Platforms
PLATFORMS=(
    "Claude Code"
    "Forge"
    "Agent Codex (Coming Soon)"
    "Antigravity (Coming Soon)"
)

print_banner() {
    cat << 'EOF'

    ____  __  ____  ____  ____  __  ____
   / __ \/ / / /\ \/ / / / __ \/ / / __ \
  / /_/ / /_/ /  \  / / / /_/ / / / /_/ /
 /_____/\____/   /_/ /_/\____/_/ /_____/

 Token-Compressed Memory Format for Agents
 Version: VERSION_PLACEHOLDER

EOF
}

print_step() {
    echo -e "${BOLD}${BLUE}==>${RESET} $1"
}

print_success() {
    echo -e "${GREEN}✓${RESET} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${RESET} $1"
}

print_error() {
    echo -e "${RED}✗${RESET} $1"
}

select_platform() {
    echo -e "${BOLD}Select your agent:${RESET}"
    echo ""
    for i in "${!PLATFORMS[@]}"; do
        num=$((i+1))
        echo -e "  ${BOLD}$num)${RESET} ${PLATFORMS[$i]}"
    done
    echo ""

    while true; do
        read -p "Enter selection [1-${#PLATFORMS[@]}]: " selection

        if [[ "$selection" =~ ^[0-9]+$ ]] && \
           [ "$selection" -ge 1 ] && \
           [ "$selection" -le ${#PLATFORMS[@]} ]; then
            idx=$((selection-1))

            if [[ "${PLATFORMS[$idx]}" == *"(Coming Soon)"* ]]; then
                print_warning "${PLATFORMS[$idx]} - not available yet"
                continue
            fi

            echo "${PLATFORMS[$idx]}"
            return 0
        fi

        print_error "Invalid selection"
    done
}

select_location() {
    local platform="$1"
    local default_dir=""

    case "$platform" in
        "Claude Code")
            default_dir="$HOME/.claude"
            ;;
        "Forge")
            default_dir="$HOME/forge"
            ;;
    esac

    echo ""
    echo -e "${BOLD}Installation directory:${RESET}"
    read -p "Path [default: $default_dir]: " custom_dir

    if [ -z "$custom_dir" ]; then
        echo "$default_dir"
    else
        echo "$custom_dir"
    fi
}

install_commands() {
    local target_dir="$1"

    print_step "Installing commands..."
    mkdir -p "$target_dir/commands/sigil"

    # Download commands
    curl -fsSL "$INSTALL_URL/commands/init.md" -o "$target_dir/commands/sigil/init.md" 2>/dev/null || {
        print_warning "Could not download init.md command"
    }
    curl -fsSL "$INSTALL_URL/commands/remember.md" -o "$target_dir/commands/sigil/remember.md" 2>/dev/null || {
        print_warning "Could not download remember.md command"
    }

    print_success "Commands installed"
}

install_skills() {
    local target_dir="$1"

    print_step "Installing skills..."
    mkdir -p "$target_dir/skills/remember/references"

    curl -fsSL "$INSTALL_URL/skills/remember/SKILL.md" -o "$target_dir/skills/remember/SKILL.md" 2>/dev/null || {
        print_warning "Could not download remember skill"
    }
    curl -fsSL "$INSTALL_URL/skills/remember/references/sigil-syntax.md" -o "$target_dir/skills/remember/references/sigil-syntax.md" 2>/dev/null || {
        print_warning "Could not download syntax reference"
    }

    print_success "Skills installed"
}

install_hooks() {
    local target_dir="$1"
    local hooks_src="$INSTALL_URL/hooks"

    print_step "Installing hooks..."

    mkdir -p "$target_dir/hooks"

    curl -fsSL "$hooks_src/hooks.json" -o "$target_dir/hooks/hooks.json" 2>/dev/null || {
        print_warning "Could not download hooks.json"
    }
    curl -fsSL "$hooks_src/precompact.sh" -o "$target_dir/hooks/precompact.sh" 2>/dev/null && \
        chmod +x "$target_dir/hooks/precompact.sh" || {
        print_warning "Could not download precompact.sh"
    }
    curl -fsSL "$hooks_src/precommit.sh" -o "$target_dir/hooks/precommit.sh" 2>/dev/null && \
        chmod +x "$target_dir/hooks/precommit.sh" || {
        print_warning "Could not download precommit.sh"
    }
    curl -fsSL "$hooks_src/sigil-checkpoint.sh" -o "$target_dir/hooks/sigil-checkpoint.sh" 2>/dev/null && \
        chmod +x "$target_dir/hooks/sigil-checkpoint.sh" || {
        print_warning "Could not download sigil-checkpoint.sh"
    }

    print_success "Hooks installed"
}

install_bin() {
    local target_dir="$1"

    print_step "Installing bin scripts..."

    mkdir -p "$target_dir/bin"

    curl -fsSL "$INSTALL_URL/bin/session-start.sh" -o "$target_dir/bin/session-start.sh" 2>/dev/null && \
        chmod +x "$target_dir/bin/session-start.sh" || {
        print_warning "Could not download session-start.sh"
    }
    curl -fsSL "$INSTALL_URL/bin/recall.sh" -o "$target_dir/bin/recall.sh" 2>/dev/null && \
        chmod +x "$target_dir/bin/recall.sh" || {
        print_warning "Could not download recall.sh"
    }
    curl -fsSL "$INSTALL_URL/bin/wrap-up.sh" -o "$target_dir/bin/wrap-up.sh" 2>/dev/null && \
        chmod +x "$target_dir/bin/wrap-up.sh" || {
        print_warning "Could not download wrap-up.sh"
    }

    print_success "Bin scripts installed"
}

create_memory_dir() {
    local target_dir="$1"
    local platform="$2"

    print_step "Creating memory directory..."

    local memory_dir=""
    case "$platform" in
        "Claude Code")
            memory_dir="$target_dir/memory"
            ;;
        "Forge")
            memory_dir="$target_dir/memory"
            ;;
    esac

    mkdir -p "$memory_dir"

    if [ ! -f "$memory_dir/MEMORY.md" ]; then
        cat > "$memory_dir/MEMORY.md" << 'EOF'
# Sigil Memory

Legend: 🚫=never, ▸=prefer-over

EOF
        print_success "Created MEMORY.md"
    else
        print_warning "MEMORY.md already exists"
    fi
}

install_plugin_manifest() {
    local target_dir="$1"

    print_step "Installing plugin manifest..."

    mkdir -p "$target_dir/.claude-plugin"
    curl -fsSL "$INSTALL_URL/.claude-plugin/plugin.json" -o "$target_dir/.claude-plugin/plugin.json" 2>/dev/null || {
        print_warning "Could not download plugin.json"
    }

    print_success "Plugin manifest installed"
}

run_init() {
    local platform="$1"

    echo ""
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}  Initialize Sigil?${RESET}"
    echo ""
    echo "  This will migrate existing memories to Sigil format."
    echo ""
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════════════════${RESET}"
    echo ""

    read -p "Run /sigil:init now? [Y/n]: " run_init

    if [[ "$run_init" =~ ^[Nn]$ ]]; then
        print_warning "Skipped init. Run /sigil:init manually when ready."
        return 0
    fi

    print_step "Running Sigil init..."
    echo ""

    case "$platform" in
        "Claude Code")
            echo -e "${BLUE}In Claude Code, run:${RESET}"
            echo -e "  ${BOLD}/sigil:init${RESET}"
            ;;
        "Forge")
            echo -e "${BLUE}In Forge, run:${RESET}"
            echo -e "  ${BOLD}/sigil:init${RESET}"
            ;;
    esac

    echo ""
    print_warning "Manual init required - open your agent to run /sigil:init"
}

print_summary() {
    local platform="$1"
    local target_dir="$2"

    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════${RESET}"
    echo -e "${GREEN}  ✓ Installation Complete!${RESET}"
    echo -e "${GREEN}════════════════════════════════════════════════════${RESET}"
    echo ""
    echo -e "  ${BOLD}Platform:${RESET} $platform"
    echo -e "  ${BOLD}Installed to:${RESET} $target_dir"
    echo ""
    echo -e "  ${BOLD}Next steps:${RESET}"
    echo "    1. Restart your agent (Claude Code / Forge)"
    echo "    2. Run /sigil:init to migrate existing memories"
    echo "    3. Run /sigil:remember to save your first memory"
    echo ""
    echo -e "  ${BOLD}Commands available:${RESET}"
    echo "    /sigil:remember  — save a memory in Sigil format"
    echo "    /sigil:init      — migrate memories to Sigil format"
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════${RESET}"
    echo ""
}

main() {
    # Replace version in banner
    print_banner | sed "s/VERSION_PLACEHOLDER/$VERSION/"

    echo -e "${BOLD}Welcome to Sigil installer!${RESET}"
    echo ""

    # Check dependencies
    if ! command -v curl &> /dev/null; then
        print_error "curl is required but not installed"
        exit 1
    fi

    # Select platform
    platform=$(select_platform)

    # Select location
    target_dir=$(select_location "$platform")

    echo ""
    echo -e "${BOLD}${BLUE}Installing Sigil for $platform...${RESET}"
    echo ""

    # Install components
    install_commands "$target_dir"
    install_skills "$target_dir"
    install_hooks "$target_dir"
    install_bin "$target_dir"
    install_plugin_manifest "$target_dir"
    create_memory_dir "$target_dir" "$platform"

    # Init prompt
    run_init "$platform"

    # Summary
    print_summary "$platform" "$target_dir"
}

# Run
main "$@"

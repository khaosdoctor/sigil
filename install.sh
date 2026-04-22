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
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

print_banner() {
    cat << 'EOF'

  _____ _____ _____ _____ _ 
 |/ ____|_   _/ ____|_   _| |
 | (___   | || |  __  | | | |
  \___ \  | || | |_ | | | | |
  ____) |_| || |__| |_| |_| |____
 |_____/|_____\_____|_____|______|

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

# Check if Sigil is installed for a given platform
check_installed() {
    local platform="$1"

    case "$platform" in
        "Claude Code")
            [ -d "$HOME/.claude/skills/sigil" ] || [ -d "$HOME/.claude/skills/remember" ]
            ;;
        "Forge")
            [ -d "$HOME/forge/skills/sigil" ] || [ -d "$HOME/forge/skills/remember" ]
            ;;
        *)
            return 1
            ;;
    esac
}

select_platform() {
    echo -e "${BOLD}Select your agent:${RESET}"
    echo ""

    # Define all platforms
    local platforms=("Claude Code" "Forge" "Agent Codex" "Antigravity")
    local statuses=("available" "available" "coming-soon" "coming-soon")

    for i in "${!platforms[@]}"; do
        local num=$((i+1))
        local platform="${platforms[$i]}"
        local status="${statuses[$i]}"

        if check_installed "$platform" 2>/dev/null; then
            # Installed
            echo -e "  ${BOLD}$num)${RESET} ${GREEN}✓${RESET} ${BOLD}$platform${RESET} ${GREEN}[installed]${RESET}"
        elif [ "$status" = "coming-soon" ]; then
            # Coming soon - disabled
            echo -e "  ${DIM}$num) ○ $platform (Coming Soon)${RESET}"
        else
            # Available
            echo -e "  ${BOLD}$num)${RESET} ${CYAN}○${RESET} ${BOLD}$platform${RESET} ${DIM}[not installed]${RESET}"
        fi
    done

    echo ""
    echo -e "${DIM}Legend:${RESET}"
    echo -e "  ${GREEN}✓${RESET} installed    ${CYAN}○${RESET} available    ${DIM}○ (Coming Soon)${RESET}"
    echo ""

    while true; do
        read -p "Enter selection: " selection

        if [[ ! "$selection" =~ ^[0-9]+$ ]]; then
            print_error "Please enter a number"
            continue
        fi

        local max_choice=${#platforms[@]}
        if [ "$selection" -lt 1 ] || [ "$selection" -gt $max_choice ]; then
            print_error "Invalid selection (must be 1-$max_choice)"
            continue
        fi

        local selected_platform="${platforms[$((selection-1))]}"
        local status="${statuses[$((selection-1))]}"

        if [ "$status" = "coming-soon" ]; then
            print_warning "$selected_platform is not available yet"
            continue
        fi

        if check_installed "$selected_platform" 2>/dev/null; then
            echo ""
            echo -e "${YELLOW}$selected_platform is already installed!${RESET}"
            read -p "Reinstall? [y/N]: " reinstall
            if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
                print_warning "Skipping..."
                continue
            fi
        fi

        echo "$selected_platform"
        return 0
    done
}

select_location() {
    local platform="$1"
    local default_dir=""

    echo ""
    echo -e "${BOLD}Installation directory:${RESET}"
    echo -e "${DIM}Leave empty for default location${RESET}"
    echo ""

    case "$platform" in
        "Claude Code")
            default_dir="$HOME/.claude"
            ;;
        "Forge")
            default_dir="$HOME/forge"
            ;;
    esac

    read -p "Path [$default_dir]: " custom_dir

    if [ -z "$custom_dir" ]; then
        echo "$default_dir"
    else
        echo "$custom_dir"
    fi
}

install_component() {
    local src="$1"
    local dest="$2"
    local name="$3"
    local executable="${4:-false}"

    local dest_dir=$(dirname "$dest")
    mkdir -p "$dest_dir"

    if curl -fsSL "$INSTALL_URL/$src" -o "$dest" 2>/dev/null; then
        [ "$executable" = "true" ] && chmod +x "$dest"
        print_success "Installed $name"
    else
        print_warning "Could not download $name"
    fi
}

install_for_platform() {
    local platform="$1"
    local target_dir="$2"

    print_step "Installing for $platform..."

    # Commands
    print_step "Commands..."
    mkdir -p "$target_dir/commands/sigil"
    install_component "commands/sigil/init.md" "$target_dir/commands/sigil/init.md" "init command"
    install_component "commands/sigil/remember.md" "$target_dir/commands/sigil/remember.md" "remember command"

    # Skills
    print_step "Skills..."
    mkdir -p "$target_dir/skills/remember/references"
    install_component "skills/remember/SKILL.md" "$target_dir/skills/remember/SKILL.md" "remember skill"
    install_component "skills/remember/references/sigil-syntax.md" "$target_dir/skills/remember/references/sigil-syntax.md" "syntax reference"

    # Hooks
    print_step "Hooks..."
    mkdir -p "$target_dir/hooks"
    install_component "hooks/hooks.json" "$target_dir/hooks/hooks.json" "hooks.json"
    install_component "hooks/precompact.sh" "$target_dir/hooks/precompact.sh" "precompact hook" "true"
    install_component "hooks/precommit.sh" "$target_dir/hooks/precommit.sh" "precommit hook" "true"
    install_component "hooks/sigil-checkpoint.sh" "$target_dir/hooks/sigil-checkpoint.sh" "checkpoint hook" "true"

    # Bin scripts
    print_step "Bin scripts..."
    mkdir -p "$target_dir/bin"
    install_component "bin/session-start.sh" "$target_dir/bin/session-start.sh" "session-start" "true"
    install_component "bin/recall.sh" "$target_dir/bin/recall.sh" "recall" "true"
    install_component "bin/wrap-up.sh" "$target_dir/bin/wrap-up.sh" "wrap-up" "true"

    # Plugin manifest
    print_step "Plugin manifest..."
    mkdir -p "$target_dir/.claude-plugin"
    install_component ".claude-plugin/plugin.json" "$target_dir/.claude-plugin/plugin.json" "plugin.json"

    # Memory setup
    print_step "Memory setup..."
    local memory_dir="$target_dir/memory"
    mkdir -p "$memory_dir"

    if [ ! -f "$memory_dir/MEMORY.md" ]; then
        cat > "$memory_dir/MEMORY.md" << 'EOF'
# Sigil Memory

Legend: 🚫=never, ▸=prefer-over

## Rules

EOF
        print_success "Created MEMORY.md"
    else
        print_warning "MEMORY.md already exists, skipping"
    fi
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
        print_warning "Skipped. Run /sigil:init manually when ready."
        return 0
    fi

    echo ""
    echo -e "${BLUE}In your $platform session, run:${RESET}"
    echo -e "  ${BOLD}/sigil:init${RESET}"
}

print_summary() {
    local platform="$1"
    local target_dir="$2"

    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════${RESET}"
    echo -e "${GREEN}  ✓ Sigil Installed Successfully!${RESET}"
    echo -e "${GREEN}════════════════════════════════════════════════════${RESET}"
    echo ""
    echo -e "  ${BOLD}Platform:${RESET} $platform"
    echo -e "  ${BOLD}Location:${RESET} $target_dir"
    echo ""
    echo -e "  ${BOLD}Next Steps:${RESET}"
    echo "    1. Restart $platform"
    echo "    2. Run /sigil:init to migrate memories"
    echo "    3. Run /sigil:remember to save your first memory"
    echo ""
    echo -e "  ${BOLD}Commands:${RESET}"
    echo "    /sigil:remember  — save memory in Sigil format"
    echo "    /sigil:init      — migrate to Sigil format"
    echo ""
}

main() {
    # Show banner
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

    # Install
    install_for_platform "$platform" "$target_dir"

    # Init prompt
    run_init "$platform"

    # Summary
    print_summary "$platform" "$target_dir"
}

# Run
main "$@"

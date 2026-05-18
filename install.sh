#!/usr/bin/env bash
# Sigil installer — interactive bash + gum.
# Usage:
#   ./install.sh                                                   (install)
#   ./install.sh uninstall                                          (remove)
#   curl -fsSL https://raw.githubusercontent.com/khaosdoctor/sigil/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/khaosdoctor/sigil/main/install.sh | bash -s -- uninstall

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────

REPO_RAW="https://raw.githubusercontent.com/khaosdoctor/sigil/main"
PLUGIN_JSON_URL="$REPO_RAW/.claude-plugin/plugin.json"

# Files copied into each selected harness. Suffix `:exec` marks +x scripts.
# Slash commands are NOT shipped as commands/* — each user-invocable SKILL.md
# already exposes its own slash command, so a separate commands/ dir would
# duplicate the surface.
COMPONENTS=(
  "skills/remember/SKILL.md"
  "skills/remember/references/sigil-syntax.md"
  "skills/init/SKILL.md"
  "skills/doctor/SKILL.md"
  "skills/purge/SKILL.md"
  "skills/encode/SKILL.md"
  "skills/decode/SKILL.md"
  "skills/wrap-up/SKILL.md"
  "hooks/hooks.json"
  "hooks/precompact.sh:exec"
  "hooks/sigil-checkpoint.sh:exec"
  "bin/session-start.sh:exec"
  "bin/recall.sh:exec"
  "bin/wrap-up.sh:exec"
  "src/doctor.ts"
  "src/purge.ts"
)

# Paths removed on uninstall.
# Includes commands/sigil for backwards-compatible cleanup of installs from
# previous Sigil versions that shipped duplicate command stubs.
UNINSTALL_PATHS=(
  "skills/remember"
  "skills/init"
  "skills/doctor"
  "skills/purge"
  "skills/encode"
  "skills/decode"
  "skills/wrap-up"
  "commands/sigil"
  "hooks/precompact.sh"
  "hooks/sigil-checkpoint.sh"
  "bin/session-start.sh"
  "bin/recall.sh"
  "bin/wrap-up.sh"
  "src/doctor.ts"
  "src/purge.ts"
)

# Harness registry: key|display name|root dir
HARNESSES=(
  "claude-code|Claude Code|$HOME/.claude"
  "opencode|OpenCode|$HOME/.config/opencode"
  "kilo|Kilo Code|$HOME/.kilocode"
  "pi-agent|Pi Agent|$HOME/.pi"
  "cursor|Cursor|$HOME/.cursor"
  "windsurf|Windsurf|$HOME/.codeium/windsurf"
  "gemini-cli|Gemini CLI|$HOME/.gemini"
  "codex|Codex|$HOME/.codex"
  "goose|Goose|$HOME/.config/goose"
)

# Harnesses with full support today. Only these are selectable in the picker.
SUPPORTED_HARNESSES=(
  "claude-code"
)

# Harnesses listed as "coming soon" — visible in the overview but not selectable
# yet. Move keys from WIP to SUPPORTED as each integration lands.
WIP_HARNESSES=(
  "opencode"
  "kilo"
  "pi-agent"
  "cursor"
  "windsurf"
  "gemini-cli"
  "codex"
  "goose"
)

# ── Dracula palette ──────────────────────────────────────────────────────────
# https://draculatheme.com/contribute#color-palette
DC_BG="#282a36"
DC_FG="#f8f8f2"
DC_COMMENT="#6272a4"
DC_CYAN="#8be9fd"
DC_GREEN="#50fa7b"
DC_ORANGE="#ffb86c"
DC_PINK="#ff79c6"
DC_PURPLE="#bd93f9"
DC_RED="#ff5555"
DC_YELLOW="#f1fa8c"

# ── Helpers ───────────────────────────────────────────────────────────────────

# Log functions detect gum dynamically so they keep working before/after
# ensure_gum() puts a bootstrapped binary on PATH.
err() {
  if command -v gum >/dev/null 2>&1; then
    gum style --foreground "$DC_RED" "$*" >&2
  else
    printf '\033[31m%s\033[0m\n' "$*" >&2
  fi
}
ok() {
  if command -v gum >/dev/null 2>&1; then
    gum style --foreground "$DC_GREEN" "$*"
  else
    printf '\033[32m%s\033[0m\n' "$*"
  fi
}
dim() {
  if command -v gum >/dev/null 2>&1; then
    gum style --foreground "$DC_COMMENT" "$*"
  else
    printf '\033[2m%s\033[0m\n' "$*"
  fi
}

require() {
  command -v "$1" >/dev/null 2>&1 && return 0
  err "$1 is required but not installed"
  [ -n "${2:-}" ] && err "  install: $2"
  exit 1
}

# Pinned gum version used when bootstrapping. Bump as needed.
GUM_VERSION="0.14.5"
GUM_TMP=""

cleanup_gum_tmp() {
  [ -n "$GUM_TMP" ] && [ -d "$GUM_TMP" ] && rm -rf "$GUM_TMP"
}

# Auto-bootstrap gum into a temp dir if not on PATH. Keeps the host clean.
ensure_gum() {
  command -v gum >/dev/null 2>&1 && return 0

  local os arch
  os=$(uname -s)
  arch=$(uname -m)
  case "$arch" in
    x86_64|amd64)   arch="x86_64" ;;
    arm64|aarch64)  arch="arm64"  ;;
    *) err "Unsupported architecture: $arch"; exit 1 ;;
  esac
  case "$os" in
    Darwin|Linux) ;;
    *) err "Unsupported OS: $os (only Darwin and Linux are supported)"; exit 1 ;;
  esac

  dim "gum not found — bootstrapping v$GUM_VERSION into a temp dir..."

  local url="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_${os}_${arch}.tar.gz"

  GUM_TMP=$(mktemp -d "${TMPDIR:-/tmp}/sigil-gum.XXXXXX")
  trap cleanup_gum_tmp EXIT INT TERM

  if ! curl -fsSL "$url" | tar -xz -C "$GUM_TMP" 2>/dev/null; then
    err "Failed to download gum from $url"
    err "  install manually: https://github.com/charmbracelet/gum#installation"
    exit 1
  fi

  local gum_bin
  gum_bin=$(find "$GUM_TMP" -name gum -type f -perm -u+x 2>/dev/null | head -1)
  [ -z "$gum_bin" ] && gum_bin=$(find "$GUM_TMP" -name gum -type f 2>/dev/null | head -1)
  if [ -z "$gum_bin" ]; then
    err "gum binary not found in downloaded archive"
    exit 1
  fi

  chmod +x "$gum_bin"
  PATH="$(dirname "$gum_bin"):$PATH"
  ok "gum v$GUM_VERSION ready (temporary, will be cleaned on exit)"
}

harness_name() {
  for h in "${HARNESSES[@]}"; do
    IFS='|' read -r k name _ <<< "$h"
    [ "$k" = "$1" ] && { echo "$name"; return; }
  done
}

harness_dir() {
  for h in "${HARNESSES[@]}"; do
    IFS='|' read -r k _ dir <<< "$h"
    [ "$k" = "$1" ] && { echo "$dir"; return; }
  done
}

is_detected()        { [ -d "$(harness_dir "$1")" ]; }
is_sigil_installed() {
  local d; d=$(harness_dir "$1")
  [ -d "$d/skills/remember" ]
}

read_version() {
  curl -fsSL "$PLUGIN_JSON_URL" 2>/dev/null \
    | grep '"version"' | head -1 | cut -d'"' -f4 \
    || echo "unknown"
}

print_banner() {
  clear
  gum style \
    --border double --align center \
    --width 60 --margin "1 2" --padding "1 2" \
    --foreground "$DC_PURPLE" --border-foreground "$DC_PURPLE" \
    "Sigil" \
    "$(gum style --foreground "$DC_CYAN" 'Token-Compressed Memory Format')" \
    "$(gum style --foreground "$DC_GREEN" 'Up to 33× lossless compression · 100% decode accuracy')" \
    "$(gum style --foreground "$DC_COMMENT" "v$(read_version)")"
}

# Map gum-choose output (display labels) back to harness keys.
labels_to_keys() {
  local labels="$1"
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    for h in "${HARNESSES[@]}"; do
      IFS='|' read -r key name _ <<< "$h"
      [[ "$line" == "$name"* ]] && { echo "$key"; break; }
    done
  done <<< "$labels"
}

install_into() {
  local key="$1"
  local target; target=$(harness_dir "$key")

  for entry in "${COMPONENTS[@]}"; do
    local src="${entry%:*}"
    local is_exec=""
    [[ "$entry" == *:exec ]] && is_exec="1"

    local dest="$target/$src"
    mkdir -p "$(dirname "$dest")"
    if ! curl -fsSL "$REPO_RAW/$src" -o "$dest"; then
      err "  failed: $src"
      return 1
    fi
    [ -n "$is_exec" ] && chmod +x "$dest"
  done

  local memory="$target/memory/MEMORY.md"
  if [ ! -f "$memory" ]; then
    mkdir -p "$(dirname "$memory")"
    cat > "$memory" <<'EOF'
# Sigil Memory

Legend: 🚫=never, ▸=prefer-over

## Rules

EOF
  fi
}

uninstall_from() {
  local key="$1"
  local target; target=$(harness_dir "$key")
  for p in "${UNINSTALL_PATHS[@]}"; do
    rm -rf "$target/$p"
  done
}

# ── Subcommands ───────────────────────────────────────────────────────────────

print_harness_overview() {
  echo
  gum style --bold --foreground "$DC_GREEN" "Supported"
  for k in "${SUPPORTED_HARNESSES[@]}"; do
    local name; name=$(harness_name "$k")
    if is_sigil_installed "$k"; then
      printf '  %s %-20s %s\n' \
        "$(gum style --foreground "$DC_GREEN" '•')" \
        "$name" \
        "$(gum style --foreground "$DC_CYAN" '[installed]')"
    else
      printf '  %s %-20s %s\n' \
        "$(gum style --foreground "$DC_GREEN" '•')" \
        "$name" \
        "$(gum style --foreground "$DC_COMMENT" '[not installed]')"
    fi
  done

  echo
  gum style --bold --foreground "$DC_ORANGE" "Coming soon"
  for k in "${WIP_HARNESSES[@]}"; do
    local name; name=$(harness_name "$k")
    printf '  %s %s %s\n' \
      "$(gum style --foreground "$DC_COMMENT" '·')" \
      "$(gum style --foreground "$DC_COMMENT" "$(printf '%-20s' "$name")")" \
      "$(gum style --foreground "$DC_YELLOW" '[in progress]')"
  done
  echo
}

cmd_install() {
  print_banner
  print_harness_overview

  # Build picker options from SUPPORTED_HARNESSES only.
  local options=()
  for k in "${SUPPORTED_HARNESSES[@]}"; do
    local name; name=$(harness_name "$k")
    if is_sigil_installed "$k"; then
      options+=("$name  [reinstall]")
    else
      options+=("$name")
    fi
  done

  local selected
  if [ ${#options[@]} -eq 1 ]; then
    # Single supported harness: a confirm is friendlier than a 1-item picker.
    local k="${SUPPORTED_HARNESSES[0]}"
    local name; name=$(harness_name "$k")
    if is_sigil_installed "$k"; then
      gum confirm "Reinstall Sigil for $name?" || { dim "Cancelled."; exit 0; }
    else
      gum confirm "Install Sigil for $name?" || { dim "Cancelled."; exit 0; }
    fi
    selected="$name"
  else
    selected=$(gum choose --no-limit \
      --header "Select harnesses (space to toggle, enter to confirm):" \
      "${options[@]}" || true)
    if [ -z "$selected" ]; then
      dim "Nothing selected. Bye."
      exit 0
    fi
  fi

  local keys
  keys=$(labels_to_keys "$selected")

  echo
  while IFS= read -r key; do
    [ -z "$key" ] && continue
    local name; name=$(harness_name "$key")
    gum style --bold --foreground "$DC_PURPLE" "→ $name"
    if install_into "$key"; then
      ok "  ✓ done"
    else
      err "  ✗ failed"
    fi
  done <<< "$keys"

  echo
  gum style --bold --foreground "$DC_GREEN" "Sigil installed."
  gum format <<'EOF'
Try one of these slash commands in your harness:

- `/sigil:remember <text>` — save a memory in compressed format
- `/sigil:init` — migrate existing memories to Sigil
- `/sigil:doctor` — diagnose memory health
EOF
}

cmd_uninstall() {
  print_banner

  # Only supported harnesses are eligible for uninstall.
  local options=()
  for k in "${SUPPORTED_HARNESSES[@]}"; do
    if is_sigil_installed "$k"; then
      options+=("$(harness_name "$k")")
    fi
  done

  if [ ${#options[@]} -eq 0 ]; then
    dim "No Sigil installations detected. Nothing to do."
    exit 0
  fi

  local selected
  if [ ${#options[@]} -eq 1 ]; then
    local k="${SUPPORTED_HARNESSES[0]}"
    local name; name=$(harness_name "$k")
    gum confirm "Remove Sigil from $name? This cannot be undone." \
      || { dim "Cancelled."; exit 0; }
    selected="$name"
  else
    selected=$(gum choose --no-limit \
      --header "Select harnesses to remove Sigil from:" \
      "${options[@]}" || true)
    if [ -z "$selected" ]; then
      dim "Nothing selected. Bye."
      exit 0
    fi
    gum confirm "Remove Sigil from selected harnesses? This cannot be undone." \
      || { dim "Cancelled."; exit 0; }
  fi

  local keys
  keys=$(labels_to_keys "$selected")

  echo
  while IFS= read -r key; do
    [ -z "$key" ] && continue
    local name; name=$(harness_name "$key")
    gum style --bold --foreground "$DC_PURPLE" "→ $name"
    uninstall_from "$key"
    ok "  ✓ removed"
  done <<< "$keys"

  echo
  gum style --bold --foreground "$DC_GREEN" "Sigil uninstalled."
}

# ── Main ──────────────────────────────────────────────────────────────────────

case "${1:-install}" in
  -h|--help|help)
    cat <<EOF
Sigil installer

Usage:
  ./install.sh             Install Sigil into selected harnesses (default)
  ./install.sh uninstall   Remove Sigil from selected harnesses

Requirements: curl. gum is auto-bootstrapped to a temp dir if missing.
EOF
    exit 0
    ;;
esac

require curl
ensure_gum

case "${1:-install}" in
  install)   cmd_install ;;
  uninstall) cmd_uninstall ;;
  *) err "Unknown command: $1"; exit 2 ;;
esac

#!/usr/bin/env bash
# Environment setup for cloud coding agents (Jules). Paste into Jules's
# "environment setup" box or run directly. Idempotent: safe to re-run.
# NOTE: not yet tested against Jules's current base image. Each step is
# independent, so one failure does not stop the others.
set -u

log() { printf '\n== %s ==\n' "$*"; }

log "System packages (headless display, Electron runtime libs, Tauri build deps)"
if command -v apt-get >/dev/null 2>&1; then
  SUDO=""
  if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi
  $SUDO apt-get update -y || echo "WARN: apt-get update failed"
  # Installed one at a time: a single unknown package name must not abort the rest.
  # Package names differ between Debian/Ubuntu releases (for example libasound2 vs libasound2t64),
  # so for those we try the alternatives.
  for pkg in xvfb xauth libgtk-3-0 libnss3 libgbm1 libxss1 libxtst6 \
             build-essential curl wget file pkg-config libssl-dev \
             libwebkit2gtk-4.1-dev libxdo-dev libayatana-appindicator3-dev librsvg2-dev; do
    $SUDO apt-get install -y --no-install-recommends "$pkg" >/dev/null 2>&1 \
      || echo "WARN: could not install $pkg"
  done
  $SUDO apt-get install -y --no-install-recommends libasound2t64 >/dev/null 2>&1 \
    || $SUDO apt-get install -y --no-install-recommends libasound2 >/dev/null 2>&1 \
    || echo "WARN: could not install libasound2 / libasound2t64"
else
  echo "WARN: apt-get not found; skipping system packages"
fi

log "Bun"
if ! command -v bun >/dev/null 2>&1; then
  curl -fsSL https://bun.sh/install | bash || echo "WARN: bun install failed"
fi
export PATH="$HOME/.bun/bin:$PATH"

log "Rust toolchain (rustup, minimal profile + rustfmt + clippy)"
if ! command -v rustup >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal \
    || echo "WARN: rustup install failed"
fi
export PATH="$HOME/.cargo/bin:$PATH"
if command -v rustup >/dev/null 2>&1; then
  rustup component add rustfmt clippy || echo "WARN: could not add rustfmt/clippy"
fi

log "Versions"
for tool in node npm bun cargo rustc xvfb-run; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf '%s: ' "$tool"
    case "$tool" in
      xvfb-run) echo "present" ;;
      *) "$tool" --version 2>&1 | head -n1 ;;
    esac
  else
    echo "$tool: MISSING"
  fi
done

echo
echo "Setup finished. Persist PATH for later shells with:"
echo '  export PATH="$HOME/.bun/bin:$HOME/.cargo/bin:$PATH"'

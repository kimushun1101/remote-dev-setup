#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# setup.sh — Tailscale + GitHub CLI + VS Code Tunnel セットアップ
# 対象: Ubuntu/Debian 系
#
# 使い方:
#   1. ローカルLAN経由で開発機に scp で転送
#   2. SSH でログインして実行: ./setup.sh
#   3. 表示されるURLをホストのブラウザで開いて認証
# =============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ---------------------------------------------------------------------------
# 前提チェック
# ---------------------------------------------------------------------------
check_prerequisites() {
  info "前提条件をチェック中..."

  if ! command -v curl &>/dev/null; then
    error "curl が見つかりません。先に sudo apt install curl を実行してください。"
  fi

  if ! command -v git &>/dev/null; then
    error "git が見つかりません。先に sudo apt install git を実行してください。"
  fi

  info "前提条件 OK"
}

# ---------------------------------------------------------------------------
# Tailscale インストール＆認証
# ---------------------------------------------------------------------------
setup_tailscale() {
  if command -v tailscale &>/dev/null; then
    local status
    status=$(tailscale status --json 2>/dev/null | grep -o '"BackendState":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
    if [[ "$status" == "Running" ]]; then
      warn "Tailscale は既に稼働中。スキップします。"
      tailscale status
      return 0
    else
      warn "Tailscale はインストール済みですが未接続 (${status})。接続を試みます。"
    fi
  else
    info "Tailscale をインストール中..."
    curl -fsSL https://tailscale.com/install.sh | sh
    info "Tailscale インストール完了"
  fi

  local default_hostname
  default_hostname=$(hostname)
  read -rp "  Tailnet 上のホスト名 [${default_hostname}]: " ts_hostname
  ts_hostname="${ts_hostname:-$default_hostname}"

  echo ""
  info "Tailscale 認証を開始します"
  echo "  表示されるURLをホストPCのブラウザで開いてください。"
  echo ""

  sudo tailscale up --ssh --hostname="${ts_hostname}"

  echo ""
  info "Tailscale 接続完了"
  tailscale status

  local ts_ip
  ts_ip=$(tailscale ip -4 2>/dev/null || echo "取得失敗")
  info "この端末の Tailscale IP: ${ts_ip}"
  echo ""
}

# ---------------------------------------------------------------------------
# GitHub CLI インストール＆認証
# ---------------------------------------------------------------------------
setup_gh() {
  # インストール
  if command -v gh &>/dev/null; then
    local ver
    ver=$(gh --version 2>/dev/null | head -1)
    warn "GitHub CLI は既にインストール済み (${ver})。"
  else
    info "GitHub CLI をインストール中..."

    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

    sudo apt update -qq
    sudo apt install -y gh

    info "GitHub CLI インストール完了: $(gh --version | head -1)"
  fi

  # 認証
  if gh auth status &>/dev/null; then
    warn "GitHub CLI は既に認証済み。スキップします。"
    gh auth status
    return 0
  fi

  echo ""
  info "GitHub 認証を開始します"
  echo "  表示されるURLとコードをホストPCのブラウザで入力してください。"
  echo ""

  gh auth login --web --git-protocol https
  info "GitHub 認証完了"
}

# ---------------------------------------------------------------------------
# VS Code Tunnel インストール＆認証
# ---------------------------------------------------------------------------
setup_vscode_tunnel() {
  # インストール
  if command -v code &>/dev/null; then
    warn "VS Code CLI は既にインストール済み。"
  else
    info "VS Code CLI をインストール中..."

    local arch os_arch
    arch=$(uname -m)
    case "$arch" in
      x86_64)  os_arch="cli-alpine-x64" ;;
      aarch64) os_arch="cli-alpine-arm64" ;;
      *)       error "未対応のアーキテクチャ: ${arch}" ;;
    esac

    local tmp_dir
    tmp_dir=$(mktemp -d)
    curl -Lk "https://code.visualstudio.com/sha/download?build=stable&os=${os_arch}" \
      --output "${tmp_dir}/vscode_cli.tar.gz"
    tar -xzf "${tmp_dir}/vscode_cli.tar.gz" -C "${tmp_dir}"
    sudo install "${tmp_dir}/code" /usr/local/bin/code
    rm -rf "${tmp_dir}"

    info "VS Code CLI インストール完了"
  fi

  # サービスが既に稼働中ならスキップ
  if systemctl --user is-active code-tunnel.service &>/dev/null 2>&1; then
    warn "VS Code Tunnel は既にサービスとして稼働中。スキップします。"
    return 0
  fi

  # 認証
  echo ""
  info "VS Code Tunnel 認証を開始します"
  echo "  表示されるURLとコードをホストPCのブラウザで入力してください。"
  echo ""

  code tunnel user login --provider github

  info "VS Code Tunnel 認証完了"

  # トンネル名の設定 & サービス登録
  local default_tunnel_name
  default_tunnel_name=$(hostname)
  read -rp "  Tunnel 名 [${default_tunnel_name}]: " tunnel_name
  tunnel_name="${tunnel_name:-$default_tunnel_name}"

  echo ""
  code tunnel service install --accept-server-license-terms --name "${tunnel_name}"

  echo ""
  info "VS Code Tunnel サービス登録完了（自動起動有効）"
  echo "  ホストPCの VS Code で Remote - Tunnels 拡張機能から接続できます。"
  echo ""
}

# ---------------------------------------------------------------------------
# メイン
# ---------------------------------------------------------------------------
main() {
  echo ""
  echo "================================================"
  echo "  開発環境セットアップ"
  echo "  Tailscale + GitHub CLI + VS Code Tunnel"
  echo "================================================"
  echo ""

  check_prerequisites
  setup_tailscale
  setup_gh
  setup_vscode_tunnel

  echo ""
  echo "================================================"
  info "セットアップ完了！"
  echo ""
  local ts_name
  ts_name=$(tailscale dns name 2>/dev/null | sed 's/\.$//' || tailscale ip -4 2>/dev/null || echo "<Tailscale IP>")
  echo "  SSH で接続:"
  echo "    ssh $(whoami)@${ts_name}"
  echo ""
  echo "  VS Code で接続:"
  echo "    Remote - Tunnels 拡張機能 → トンネル一覧から選択"
  echo ""
  echo "  作業終了後は ./cleanup.sh を実行してください。"
  echo "================================================"
  echo ""
}

main "$@"

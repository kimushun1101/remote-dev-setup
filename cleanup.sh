#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# cleanup.sh — 認証情報・キャッシュの削除
# 共有マシンから退出する前に実行
#
# オプション:
#   --uninstall         ツール自体もアンインストール
#   --remove-tailscale  Tailscale も削除
# =============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

DO_UNINSTALL=false
KEEP_TAILSCALE=true
for arg in "$@"; do
  case "$arg" in
    --uninstall)        DO_UNINSTALL=true ;;
    --remove-tailscale) KEEP_TAILSCALE=false ;;
  esac
done

# ---------------------------------------------------------------------------
# GitHub CLI クリーンアップ
# ---------------------------------------------------------------------------
cleanup_gh() {
  info "GitHub CLI の認証情報をクリーンアップ中..."

  if command -v gh &>/dev/null; then
    gh auth logout 2>/dev/null || true
  fi

  if [[ -d "${HOME}/.config/gh" ]]; then
    rm -rf "${HOME}/.config/gh"
    info "  削除: ~/.config/gh"
  fi

  git config --global --unset credential.helper 2>/dev/null || true
  git config --global --unset credential.https://github.com.helper 2>/dev/null || true
  info "  Git credential helper を解除"

  if $DO_UNINSTALL; then
    if command -v gh &>/dev/null; then
      info "GitHub CLI をアンインストール中..."
      sudo apt remove -y gh 2>/dev/null || true
      sudo rm -f /etc/apt/sources.list.d/github-cli.list
      sudo rm -f /etc/apt/keyrings/githubcli-archive-keyring.gpg
      info "  GitHub CLI アンインストール完了"
    fi
  fi

  info "GitHub CLI クリーンアップ完了"
}

# ---------------------------------------------------------------------------
# Git 設定のクリーンアップ
# ---------------------------------------------------------------------------
cleanup_git_config() {
  info "Git のユーザー設定をクリーンアップ中..."

  local git_name git_email
  git_name=$(git config --global user.name 2>/dev/null || echo "")
  git_email=$(git config --global user.email 2>/dev/null || echo "")

  if [[ -n "$git_name" || -n "$git_email" ]]; then
    echo ""
    warn "グローバル Git 設定が見つかりました:"
    [[ -n "$git_name" ]]  && echo "  user.name  = $git_name"
    [[ -n "$git_email" ]] && echo "  user.email = $git_email"
    echo ""
    read -rp "これらも削除しますか？ [y/N]: " do_remove
    if [[ "$do_remove" =~ ^[Yy]$ ]]; then
      git config --global --unset user.name 2>/dev/null || true
      git config --global --unset user.email 2>/dev/null || true
      info "  Git ユーザー設定を削除"
    fi
  fi
}

# ---------------------------------------------------------------------------
# シェル履歴のクリーンアップ
# ---------------------------------------------------------------------------
cleanup_shell_history() {
  info "シェル履歴からトークン/キーの痕跡を確認中..."

  local histfile="${HISTFILE:-${HOME}/.bash_history}"
  if [[ -f "$histfile" ]]; then
    local suspicious
    suspicious=$(grep -cE '(ghp_|GH_TOKEN|GITHUB_TOKEN)' "$histfile" 2>/dev/null || echo "0")
    if [[ "$suspicious" -gt 0 ]]; then
      warn "シェル履歴にトークンらしき文字列が ${suspicious} 件見つかりました。"
      read -rp "履歴を全消去しますか？ [y/N]: " do_clear
      if [[ "$do_clear" =~ ^[Yy]$ ]]; then
        > "$histfile"
        history -c 2>/dev/null || true
        info "  シェル履歴を消去"
      fi
    else
      info "  シェル履歴に機密情報は見つかりませんでした"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Tailscale クリーンアップ（明示的に指定した場合のみ）
# ---------------------------------------------------------------------------
cleanup_tailscale() {
  if ! $KEEP_TAILSCALE; then
    info "Tailscale をクリーンアップ中..."

    if command -v tailscale &>/dev/null; then
      sudo tailscale down 2>/dev/null || true
      sudo tailscale logout 2>/dev/null || true
      info "  Tailnet から離脱"

      if $DO_UNINSTALL; then
        sudo apt remove -y tailscale 2>/dev/null || true
        sudo rm -f /etc/apt/sources.list.d/tailscale.list
        sudo rm -f /usr/share/keyrings/tailscale-archive-keyring.gpg
        info "  Tailscale アンインストール完了"
      fi
    fi
  else
    info "Tailscale: 保持（--remove-tailscale で削除可能）"
  fi
}

# ---------------------------------------------------------------------------
# 最終確認
# ---------------------------------------------------------------------------
verify_cleanup() {
  echo ""
  echo "================================================"
  echo "  クリーンアップ確認"
  echo "================================================"
  echo ""

  if [[ -d "${HOME}/.config/gh" ]]; then
    warn "GitHub CLI: 残留ファイルあり"
  else
    info "GitHub CLI: クリーン"
  fi

  if ! $KEEP_TAILSCALE; then
    if command -v tailscale &>/dev/null && tailscale status &>/dev/null; then
      warn "Tailscale: まだ接続中"
    else
      info "Tailscale: クリーン"
    fi
  fi

  echo ""
  info "クリーンアップ完了。"
  if $DO_UNINSTALL; then
    info "ツールのアンインストールも完了しました。"
  fi
  echo ""
}

# ---------------------------------------------------------------------------
# メイン
# ---------------------------------------------------------------------------
main() {
  echo ""
  echo "================================================"
  echo "  クリーンアップ（認証情報削除）"
  if $DO_UNINSTALL; then
    echo "  + ツールのアンインストール"
  fi
  echo "================================================"
  echo ""

  read -rp "クリーンアップを実行しますか？ [y/N]: " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "キャンセルしました。"
    exit 0
  fi

  cleanup_gh
  cleanup_git_config
  cleanup_tailscale
  cleanup_shell_history
  verify_cleanup
}

main "$@"

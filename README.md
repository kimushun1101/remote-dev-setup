# remote-dev-setup

リモート開発機に Tailscale + GitHub CLI をセットアップするスクリプト。
認証は全てホストPCのブラウザから行えるため、開発機にブラウザは不要。

## ファイル

| ファイル | 用途 |
| --- | --- |
| `setup.sh` | Tailscale + GitHub CLI のインストールと認証 |
| `cleanup.sh` | 認証情報の削除（+ オプションでアンインストール） |

## 事前準備

### Tailscale アカウント

https://login.tailscale.com でアカウントを作成しておく。
（Google / Microsoft / GitHub アカウントでログイン可能）

### GitHub アカウント

ブラウザで GitHub にログインできれば OK。
セットアップ中に `gh auth login` の認証が始まると、以下の流れで進みます:

1. `? Authenticate Git with your GitHub credentials?` → **Y** (Enter)
2. ワンタイムコードと URL が表示される
3. ホスト PC のブラウザで URL を開き、コードを入力して認証

## セットアップ手順

```bash
# 1. リモート開発機に SSH でログイン
ssh user@192.168.x.x
```

```bash
# 2. リポジトリをクローンして実行（フォークした場合にはURLを適宜変更すること）
git clone https://github.com/kimushun1101/remote-dev-setup.git
cd remote-dev-setup
chmod +x *.sh
./setup.sh
```

スクリプト実行中に以下の操作が求められます:

1. **Tailscale ホスト名** — Tailnet 上のホスト名を入力（Enter でデフォルト）
2. **Tailscale 認証** — 表示される URL をブラウザで開いてログイン
3. **GitHub CLI 認証**
   - `? Authenticate Git with your GitHub credentials?` → **Y** (Enter)
   - ワンタイムコードと URL が表示される → ブラウザで URL を開きコードを入力

## 作業終了時

```bash
./cleanup.sh                                    # 認証情報を削除（Tailscale含む）
./cleanup.sh --keep-tailscale                   # Tailscale は残す
./cleanup.sh --uninstall                        # 認証削除 + ツールもアンインストール
```

> **注意**: `cleanup.sh` は Tailscale のローカル認証を無効化しますが、
> [Tailscale 管理画面](https://login.tailscale.com/admin/machines) からマシンのエントリは自動削除されません。
> クリーンアップ後に管理画面から手動で削除してください。
>
> **補足**: 管理画面の **Settings → Device management → Auto-remove inactive devices** を
> 有効にすると、一定期間非アクティブなデバイスが自動で削除されます。

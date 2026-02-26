# remote-dev-setup

リモート開発機に Tailscale + GitHub CLI をセットアップするスクリプト。
初回のローカルネットワーク SSH だけで設定すれば、以降はどこからでも開発機に接続できます。

## 特徴

- **セットアップ後はどこからでも接続可能** — 初回セットアップはローカルネットワーク経由の SSH が必要ですが、Tailscale 設定後はインターネット越しにどこからでも SSH 接続できます
- **SSH 鍵の管理が不要** — Tailscale SSH（`--ssh`）を利用するため、SSH 鍵の生成・配置・管理が不要です
- **VS Code Tunnel にも対応** — `--with-vscode` オプションで VS Code Tunnel もセットアップ可能。ホスト PC の VS Code からいつでも接続できます
- **開発機にブラウザ不要** — すべての認証はホスト PC のブラウザで完結します
- **共有マシンでも安全** — `cleanup.sh` が認証情報・Git 設定・シェル履歴まで丁寧にクリーンアップします
- **再実行しても安全** — インストール済み・認証済みの項目は自動でスキップされます

## ファイル

| ファイル | 用途 |
| --- | --- |
| `setup.sh` | Tailscale + GitHub CLI のインストールと認証（`--with-vscode` で VS Code Tunnel も追加） |
| `other-tools.md` | その他のツールの参考情報 |
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

リポジトリをクローンして実行（フォークした場合にはURLを適宜変更すること）

```bash
git clone https://github.com/kimushun1101/remote-dev-setup.git
cd remote-dev-setup
```

基本セットアップ（Tailscale + GitHub CLI）

```bash
./setup.sh
```

VS Code Tunnel も追加したい場合

```bash
./setup.sh --with-vscode
```

スクリプト実行中に以下の操作が求められます:

1. **Tailscale ホスト名** — Tailnet 上のホスト名を入力（Enter でデフォルト）
2. **Tailscale 認証** — 表示される URL をブラウザで開いてログイン
3. **GitHub CLI 認証**
   - `? Authenticate Git with your GitHub credentials?` → **Y** (Enter)
   - ワンタイムコードと URL が表示される → ブラウザで URL を開きコードを入力

`--with-vscode` を指定した場合はさらに:

1. **VS Code Tunnel 認証** — 表示されるコードと URL をブラウザで入力（GitHub アカウントで認証）
2. **VS Code Tunnel 名** — トンネル名を入力（Enter でホスト名がデフォルト）

## 作業終了時

```bash
./cleanup.sh                                    # 認証情報を全て削除
./cleanup.sh --keep-tailscale                   # Tailscale は残す
./cleanup.sh --keep-vscode                      # VS Code Tunnel は残す
./cleanup.sh --uninstall                        # 認証削除 + ツールもアンインストール
```

> **注意**: `cleanup.sh` は Tailscale のローカル認証を無効化しますが、
> [Tailscale 管理画面](https://login.tailscale.com/admin/machines) からマシンのエントリは自動削除されません。
> クリーンアップ後に管理画面から手動で削除してください。
>
> **補足**: 管理画面の **Settings → Device management → Auto-remove inactive devices** を
> 有効にすると、一定期間非アクティブなデバイスが自動で削除されます。

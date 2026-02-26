# remote-dev-setup

リモート開発機に Tailscale + GitHub CLI をセットアップするスクリプト。
認証は全てホストPCのブラウザから行えるため、開発機にブラウザは不要。

## ファイル

| ファイル | 用途 |
|---|---|
| `setup.sh` | Tailscale + GitHub CLI のインストールと認証 |
| `cleanup.sh` | 認証情報の削除（+ オプションでアンインストール） |

## 事前準備

### Tailscale アカウント

https://login.tailscale.com でアカウントを作成しておく。
（Google / Microsoft / GitHub アカウントでログイン可能）

### GitHub Personal Access Token の作成

`gh auth login` はブラウザ認証を使うため、トークンの手動作成は不要です。
ブラウザで GitHub にログインできれば OK。

> **補足: トークンを手動で作成したい場合**
>
> 1. https://github.com/settings/tokens?type=beta にアクセス
> 2. 「Generate new token」をクリック
> 3. 設定:
>    - **Token name**: 分かりやすい名前（例: `dev-pc2`）
>    - **Expiration**: 短めに設定（7日 や 30日 を推奨）
>    - **Repository access**: 必要なリポジトリを選択
>    - **Permissions**: `Contents` (Read and write), `Metadata` (Read-only)
> 4. 「Generate token」で発行し、表示されたトークンをコピー
>
> 手動トークンを使う場合は `gh auth login --with-token` で認証できます:
> ```bash
> echo "ghp_xxxxxxxxxxxx" | gh auth login --with-token
> ```

## セットアップ手順

```bash
# 1. リモート開発機に SSH でログイン
ssh user@192.168.x.x

# 2. リポジトリをクローンして実行
git clone https://github.com/<user>/remote-dev-setup.git
cd remote-dev-setup
chmod +x *.sh
./setup.sh

# 3. 表示されるURLをホストPCのブラウザで開いて認証
#    - Tailscale: ログインURLが表示される → ブラウザで承認
#    - GitHub CLI: URLとコードが表示される → ブラウザで入力
```

## 作業終了時

```bash
./cleanup.sh                                    # 認証情報のみ削除
./cleanup.sh --uninstall                        # gh もアンインストール
./cleanup.sh --uninstall --remove-tailscale     # 全部削除
```

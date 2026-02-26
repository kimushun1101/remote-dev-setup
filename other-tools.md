# その他のツール参考情報

`setup.sh` に含まれていないツールのうち、リモート開発機で認証しておくと便利なものをまとめます。
いずれもホスト PC のブラウザでデバイスコード認証が可能です。

## クラウド CLI

| ツール | インストール | 認証コマンド |
| --- | --- | --- |
| AWS CLI | [公式手順](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | `aws sso login` |
| Google Cloud CLI | [公式手順](https://cloud.google.com/sdk/docs/install) | `gcloud auth login --no-launch-browser` |
| Azure CLI | [公式手順](https://learn.microsoft.com/cli/azure/install-azure-cli-linux) | `az login --use-device-code` |

### AWS CLI の例

```bash
# インストール
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# SSO 認証（ブラウザでデバイスコードを入力）
aws configure sso
aws sso login
```

### Google Cloud CLI の例

```bash
# インストール
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# 認証（--no-launch-browser でデバイスコード方式になる）
gcloud auth login --no-launch-browser
```

### Azure CLI の例

```bash
# インストール
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# 認証（--use-device-code でデバイスコード方式になる）
az login --use-device-code
```

## コンテナ

### Docker Hub

```bash
# Docker がインストール済みの場合
# Personal Access Token を使用（https://hub.docker.com/settings/security で作成）
docker login -u <ユーザー名>
```

> Docker Hub はブラウザ認証に対応していないため、事前にアクセストークンを作成しておく必要があります。

## AI アシスタント（契約が必要）

| ツール | 必要な契約 | 認証方法 |
| --- | --- | --- |
| Claude Code | Anthropic Max / API プラン | `claude` 初回実行時にブラウザ認証 |
| GitHub Copilot CLI | GitHub Copilot サブスクリプション | `gh copilot` 初回実行時に認証 |

### Claude Code の例

```bash
# インストール
npm install -g @anthropic-ai/claude-code

# 初回実行時にブラウザ認証
claude
```

### GitHub Copilot CLI の例

```bash
# GitHub CLI の拡張機能としてインストール（gh は setup.sh でインストール済み）
gh extension install github/gh-copilot

# 初回実行時に認証
gh copilot
```

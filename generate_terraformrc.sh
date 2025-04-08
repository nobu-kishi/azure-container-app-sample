#!/bin/bash

# 実行ユーザーのホームディレクトリ
HOME_DIR="$HOME"
TERRAFORM_CONFIG_FILE=""
PLUGIN_CACHE_DIR=""

# OS判定
OS="$(uname -s)"

case "$OS" in
    Linux*)
        TERRAFORM_CONFIG_FILE="$HOME_DIR/.terraformrc"
        PLUGIN_CACHE_DIR="$HOME_DIR/.terraform.d/plugin-cache"
        ;;
    Darwin*) # macOS
        TERRAFORM_CONFIG_FILE="$HOME_DIR/.terraformrc"
        PLUGIN_CACHE_DIR="$HOME_DIR/.terraform.d/plugin-cache"
        ;;
    MINGW*|MSYS*|CYGWIN*) # Windows (Git Bash など)
        TERRAFORM_CONFIG_FILE="$APPDATA/terraform.rc"
        PLUGIN_CACHE_DIR="$APPDATA/terraform.d/plugin-cache"
        ;;
    *)
        echo "対応していないOSです: $OS"
        exit 1
        ;;
esac

# キャッシュディレクトリを作成
mkdir -p "$PLUGIN_CACHE_DIR"

# .terraformrcファイルを作成
echo "plugin_cache_dir = \"$PLUGIN_CACHE_DIR\"" > "$TERRAFORM_CONFIG_FILE"

echo "Terraform RCファイルを生成しました:"
echo "  設定ファイル: $TERRAFORM_CONFIG_FILE"
echo "  プラグインキャッシュ: $PLUGIN_CACHE_DIR"
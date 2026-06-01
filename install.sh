#!/bin/bash

# エラーが起きたら停止
set -e

# 【重要】このスクリプトが存在するディレクトリに強制移動する
cd "$(dirname "$0")"
DOT_DIRECTORY=$(pwd)

echo "🔗 シンボリックリンクの自動作成を開始します..."

# dotfilesフォルダ内の隠しファイルだけを安全にループ処理
for f in .??*; do
    [ "$f" = ".git" ] && continue
    [ "$f" = ".gitignore" ] && continue
    
    # リンクを張る
    ln -snfv "$DOT_DIRECTORY/$f" "$HOME/$f"
done

echo "✅ すべてのリンク作成が完了しました！"

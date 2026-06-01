#!/bin/bash

# エラーが起きたらスクリプトを終了する
set -e

# dotfilesフォルダのパス
DOT_DIRECTORY="$HOME/dotfiles"

echo "🔗 シンボリックリンクの自動作成を開始します..."

# フォルダ内の「.」から始まるファイル名をすべてループ処理する
for f in .??*; do
    # 無視するファイル（Gitの管理ファイルなど）を除外
    [ "$f" = ".git" ] && continue
    [ "$f" = ".gitignore" ] && continue

    # ln -snfv コマンドで、古いリンクを安全に上書きしながら作成
    ln -snfv "$DOT_DIRECTORY/$f" "$HOME/$f"
done

echo "✅ すべてのリンク作成が完了しました！"

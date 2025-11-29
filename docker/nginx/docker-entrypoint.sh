#!/bin/sh
set -e

# 環境変数が設定されているか確認
if [ -z "$LARAVEL_SERVER_NAME" ]; then
    echo "Error: LARAVEL_SERVER_NAME is not set"
    exit 1
fi

if [ -z "$NEXTJS_SERVER_NAME" ]; then
    echo "Error: NEXTJS_SERVER_NAME is not set"
    exit 1
fi

# テンプレートから設定ファイルを生成
echo "Generating nginx configuration from template..."
envsubst '${LARAVEL_SERVER_NAME} ${NEXTJS_SERVER_NAME}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

echo "Nginx configuration generated successfully:"
echo "  LARAVEL_SERVER_NAME: $LARAVEL_SERVER_NAME"
echo "  NEXTJS_SERVER_NAME: $NEXTJS_SERVER_NAME"

# 設定ファイルの構文チェック
nginx -t

# Nginxを起動
echo "Starting nginx..."
exec nginx -g 'daemon off;'

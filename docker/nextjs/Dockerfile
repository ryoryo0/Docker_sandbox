FROM node:20-alpine

WORKDIR /app

# ポート3000を公開
EXPOSE 3000

# 起動時に依存関係をインストールしてから開発サーバーを起動
CMD ["sh", "-c", "npm install && npm run dev"]

# Laravel12 × Next.js プロジェクト

Laravel 12（PHP 8.3）をバックエンド、Next.js 15（React 19）をフロントエンドとした商品管理・顧客向け販売プラットフォームです。

---

## システム全体像

```
ブラウザ (顧客)           ブラウザ (管理者)
     │                        │
     ▼                        ▼
┌──────────────────────────────────────┐
│           Nginx 1.27 (リバースプロキシ)          │
│  nextjs.local:443   laravel12.local:443  │
└───────────┬──────────────┬───────────┘
            │              │
            ▼              ▼
     ┌──────────┐   ┌──────────────┐
     │ Next.js  │   │  PHP-FPM 8.3 │
     │  (3000)  │   │  (Laravel12) │
     └────┬─────┘   └──────┬───────┘
          │                │
          │ REST API        ├── MySQL 8.0
          └────────────────┤
                           ├── Redis (キャッシュ/セッション)
                           └── Mailpit (メール 開発用)
```

### 役割分担

| コンポーネント | 役割 | アクセス先 |
|---|---|---|
| Next.js | 顧客向け商品一覧・詳細・検索ページ | `https://nextjs.local` |
| Laravel (管理画面) | 商品・カテゴリ・イベント・在庫の管理 | `https://laravel12.local/admin` |
| Laravel (API) | Next.js へ商品データを提供する REST API | `https://laravel12.local/api/v1` |
| Mailpit | 開発用メール確認 | `http://localhost:8025` |

---

## 技術スタック

| レイヤー | 技術 | バージョン |
|---|---|---|
| バックエンド | Laravel | 12.x |
| 言語 | PHP | 8.3 |
| フロントエンド (顧客) | Next.js / React | 15.x / 19.x |
| 言語 | TypeScript | 5.x |
| 管理画面 UI | Blade + Tailwind CSS + Alpine.js | - |
| リバースプロキシ | Nginx | 1.27 |
| データベース | MySQL | 8.0.37 |
| キャッシュ / セッション | Redis | Alpine |
| メール (開発) | Mailpit | v1.8 |
| コンテナ | Docker / Docker Compose | - |
| 認証・権限管理 | Spatie Laravel Permission | ^6.18 |
| ビルドツール | Vite | 6.2.4 |

---

## ディレクトリ構成

```
laravel12/
├── Compose.yml              # Docker Compose 設定
├── .env                     # ルート環境変数（Docker用）
├── .env.example             # 環境変数テンプレート
├── README.md
├── docker/
│   ├── php/
│   │   ├── Dockerfile       # PHP-FPM 8.3 コンテナ
│   │   └── php.ini          # アップロード上限256MB等
│   ├── nginx/
│   │   ├── Dockerfile       # Nginx 1.27 コンテナ
│   │   ├── default.conf.template  # Nginx設定テンプレート
│   │   ├── docker-entrypoint.sh   # 環境変数で設定を動的生成
│   │   └── mkcerts/         # SSL自己署名証明書
│   ├── nextjs/
│   │   └── Dockerfile       # Node.js 20 Alpine コンテナ
│   └── mysql/               # MySQL データ永続化ディレクトリ
├── src-laravel/             # Laravel アプリケーション
│   ├── app/
│   │   ├── Models/          # Eloquent モデル
│   │   ├── Http/
│   │   │   ├── Controllers/ # Admin / Api / Customer コントローラー
│   │   │   ├── Requests/    # バリデーション
│   │   │   └── Resources/   # API レスポンス整形
│   │   ├── Services/
│   │   └── Mail/
│   ├── routes/
│   │   ├── api.php          # 公開 API (v1)
│   │   ├── admin.php        # 管理画面
│   │   ├── customer.php     # 顧客向け
│   │   └── web.php
│   ├── database/
│   │   ├── migrations/      # 16ファイル
│   │   ├── factories/
│   │   └── seeders/
│   ├── resources/views/     # Blade テンプレート
│   ├── ER.md                # DB設計ドキュメント
│   └── vite.config.js       # Vite (HTTPS対応 HMR)
└── src-next/                # Next.js アプリケーション
    └── src/
        ├── app/             # App Router
        │   ├── page.tsx     # トップ（商品一覧）
        │   ├── product/[id]/page.tsx  # 商品詳細
        │   └── search/page.tsx        # 検索
        ├── components/
        │   ├── layout/      # Header / Footer
        │   ├── product/     # ProductCard / Badge
        │   └── search/      # SearchForm / SearchModal
        ├── lib/api/         # API 通信ロジック
        └── types/           # TypeScript 型定義
```

---

## アーキテクチャ詳細

### API 通信フロー

Next.js は Laravel の REST API を経由して商品データを取得します。

```
SSR (サーバーサイド):
  Next.js コンテナ → http://nginx → Laravel

クライアントサイド:
  ブラウザ → https://laravel12.local/api/v1 → Laravel
```

環境変数で切り替え:
```bash
API_URL=http://nginx                          # SSR用（コンテナ内通信）
NEXT_PUBLIC_API_URL=https://laravel12.local   # ブラウザ用
```

### 公開 API エンドポイント

```
GET /api/v1/products           商品一覧（ページネーション付き）
GET /api/v1/products/featured  おすすめ商品一覧
GET /api/v1/products/{id}      商品詳細
```

### データベース設計（主要テーブル）

```
管理者系
  admins, admin_password_reset_tokens, admin_sessions

顧客系
  customers, customers_password_reset_tokens, customers_sessions

商品・カテゴリ系
  categories, products, product_images, product_variants
  category_product（多対多）

イベント・キャンペーン系
  events, event_images, event_product（多対多）

システム系
  cache, jobs, permission_tables, temporary_images, admin_invitations
```

詳細は `src-laravel/ER.md` を参照してください。

### Nginx 構成

環境変数でドメインを動的に切り替え可能（`docker-entrypoint.sh` が `envsubst` でテンプレートを展開）。

| バーチャルホスト | ポート | 内容 |
|---|---|---|
| `laravel12.local` | 443 | Laravel（PHP-FPM へ転送、静的ファイル配信） |
| `laravel12.local` | 80 | HTTPS へリダイレクト（`/api/` 等は除外） |
| `nextjs.local` | 443 | Next.js（`nextjs:3000` へプロキシ、WebSocket対応） |
| `nextjs.local` | 80 | HTTPS へリダイレクト |

**セキュリティヘッダー:** HSTS / CSP / X-Frame-Options / X-Content-Type-Options / Permissions-Policy
**パフォーマンス:** Gzip 圧縮 / FastCGI バッファ最適化 / 静的ファイル 1年キャッシュ
**レート制限:** API 10r/s、一般 30r/s

---

## 環境構築手順

### 前提条件

- Docker / Docker Compose がインストール済みであること
- ローカルの `/etc/hosts` にドメインを追加していること

```
127.0.0.1  laravel12.local
127.0.0.1  nextjs.local
```
※ IPを解放している場合は任意のIPアドレスを指定いただいて問題ございません


### 1. 環境変数の設定

```bash
cp .env.example .env
```

`.env` を編集して各値を設定します:

```bash
# MySQL
MYSQL_ROOT_PASSWORD=your_password
MYSQL_DATABASE=database

# Nginx ドメイン
LARAVEL_SERVER_NAME=laravel12.local
NEXTJS_SERVER_NAME=nextjs.local

# API URL
API_URL=http://nginx
NEXT_PUBLIC_API_URL=https://laravel12.local
```

### 2. Laravel 環境変数の設定

```bash
cp src-laravel/.env.example src-laravel/.env
```

最低限以下を設定:

```bash
APP_KEY=                          # 後述の artisan コマンドで生成
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=database
DB_USERNAME=root
DB_PASSWORD=your_password

SESSION_DRIVER=database
SESSION_TABLE=admin_sessions

REDIS_HOST=redis
REDIS_PORT=6379
```

### 3. Docker コンテナのビルド・起動

```bash
docker compose -f Compose.yml up --build
```

### 4. Laravel 初期化

```bash
# アプリケーションキー生成
docker compose exec laravel php artisan key:generate

# マイグレーション実行
docker compose exec laravel php artisan migrate

# (オプション) シーダー実行
docker compose exec laravel php artisan db:seed
```

### 5. アクセス確認

| 用途 | URL |
|---|---|
| 顧客サイト (Next.js) | `https://nextjs.local` |
| 管理画面 (Laravel) | `https://laravel12.local/admin` |
| API | `https://laravel12.local/api/v1/products` |
| メール確認 | `http://localhost:8025` |

> **注意:** 自己署名証明書を使用しているため、ブラウザでセキュリティ警告が表示されます。開発環境では無視して進めてください。

---

## 開発コマンド

### Laravel

```bash
# 開発サーバー起動（artisan serve + queue + Vite を同時起動）
docker compose exec laravel composer run dev

# テスト実行
docker compose exec laravel composer run test

# コードフォーマット
docker compose exec laravel ./vendor/bin/pint

# マイグレーション
docker compose exec laravel php artisan migrate

# Tinker（REPL）
docker compose exec laravel php artisan tinker
```

### Next.js

```bash
# 開発サーバー起動（Turbopack）
docker compose exec nextjs npm run dev

# 本番ビルド
docker compose exec nextjs npm run build
```

### Docker

```bash
# コンテナ起動
docker compose -f Compose.yml up

# コンテナ停止
docker compose -f Compose.yml down

# ログ確認
docker compose -f Compose.yml logs -f laravel
docker compose -f Compose.yml logs -f nginx
```

---

## Docker コンテナ一覧

| コンテナ名 | イメージ | ポート | 役割 |
|---|---|---|---|
| `nginx` | nginx:1.27 | 80, 443 | リバースプロキシ / SSL終端 |
| `laravel` | php:8.3-fpm | 5173 (Vite HMR) | Laravel アプリ / PHP-FPM |
| `nextjs` | node:20-alpine | 3000 | Next.js アプリ |
| `mysql` | mysql:8.0.37 | 3306 | データベース |
| `redis` | redis:alpine | 16379 | キャッシュ / セッション |
| `mailpit` | mailpit:v1.8 | 8025 (UI), 1025 (SMTP) | 開発用メール |

---

## 権限・ロール管理

Spatie Laravel Permission を使用して管理者の権限を管理しています。

```php
// ロール付与例
$admin->assignRole('super-admin');

// パーミッション確認例
$admin->can('manage-products');
```

---

## 関連ドキュメント

- `src-laravel/ER.md` - データベース ER 図・テーブル設計詳細

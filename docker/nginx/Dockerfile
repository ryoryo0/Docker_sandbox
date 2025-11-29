FROM nginx:1.27

# テンプレートファイルとentrypointスクリプトをコピー
COPY ./default.conf.template /etc/nginx/conf.d/default.conf.template
COPY ./docker-entrypoint.sh /docker-entrypoint.sh

# entrypointスクリプトに実行権限を付与
RUN chmod +x /docker-entrypoint.sh

# entrypointを設定
ENTRYPOINT ["/docker-entrypoint.sh"]

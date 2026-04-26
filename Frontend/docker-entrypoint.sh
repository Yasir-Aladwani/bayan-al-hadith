#!/bin/sh
set -e
PORT="${PORT:-80}"
sed -i "s/NGINX_PORT_PLACEHOLDER/${PORT}/g" /etc/nginx/conf.d/default.conf
exec nginx -g "daemon off;"

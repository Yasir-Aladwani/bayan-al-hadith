#!/bin/sh
set -e
NGINX_PORT="${PORT:-80}"
sed -i "s/NGINX_PORT_PLACEHOLDER/${NGINX_PORT}/g" /etc/nginx/conf.d/default.conf
exec nginx -g "daemon off;"

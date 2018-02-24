#!/bin/bash
INDENT=4
INDENT=$(($INDENT))
TOUR_FPM="
_IS_DEV=True
APP_NAME=Tour
APP_ENV=local
APP_KEY=base64:R4IVDazNA3o7KOfmwD5UEd0Y3+Gg/7EJMfbmy4ZAGTY=
APP_DEBUG=true
APP_LOG_LEVEL=debug
APP_URL=http://localhost

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=root
DB_USERNAME=root
DB_PASSWORD=root

BROADCAST_DRIVER=log
CACHE_DRIVER=file
SESSION_DRIVER=file
SESSION_LIFETIME=120
QUEUE_DRIVER=sync

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_DRIVER=smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null

PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=
"

env_generator() {
        for line in $@; do
                echo "`printf '%*s' "$INDENT"`- `echo $line | cut -d"=" -f1`=`echo $line | cut -d"=" -f2`"
        done
}

cat > docker-compose.yaml << EOL
version: '2'
services:

  db:
    restart: always
    image: percona
    environment:
    - MYSQL_USER=root
    - MYSQL_PASSWORD=root
    - MYSQL_DATABASE=root
    - MYSQL_ROOT_PASSWORD=root

  redis:
    image: redis:alpine
    restart: always

  fpm:
    build: .
    restart: always
    environment:
`env_generator $TOUR_FPM`
    links:
      - redis
      - db
    ports:
      - 6985:80
    command: "php-fpm"


  scheduler:
    build: .
    restart: always
    environment:
`env_generator $TOUR_FPM`
    links:
      - redis
      - db
    command: "schedule"

  queue:
    build: .
    restart: always
    environment:
`env_generator $TOUR_FPM`
    links:
      - redis
      - db
    command: "schedule"
EOL
docker-compose up --build -d $@

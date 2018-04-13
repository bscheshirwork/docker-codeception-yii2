# Codeception

Based at :whale:[official images](https://hub.docker.com/r/codeception/codeception/) 
and expand it.

Supported tags and respective `Dockerfile` links
================================================


## for yii2 

- `php7.2.4-fpm-yii2`, `php-fpm-yii2` ([Dockerfile](./Dockerfile))

FROM `bscheshir/php:fpm-4yii2-xdebug` [bscheshir/docker-php](https://github.com/bscheshirwork/docker-php)

tag: `php{sourceref}-fpm-yii2`

`docker pull bscheshir/codeception:php7.2.4-fpm-yii2`


## How to create it
> Note: for https://github.com/Codeception/Codeception.git `master` is deprecated. Use last tag instead (2.4)
```sh
cd /home/dev/projects/docker-codeception-yii2/build/
git checkout build
git pull parent 2.4
cp ../Dockerfile ../composer.json ./ 
docker pull bscheshir/php:fpm-alpine-4yii2-xdebug
docker build --pull --no-cache -t bscheshir/codeception:php7.2.4-fpm-alpine-yii2 -t bscheshir/codeception:php-fpm-alpine-yii2 -- .
docker push bscheshir/codeception:php7.2.4-fpm-alpine-yii2
docker push bscheshir/codeception:php-fpm-alpine-yii2
git checkout -- .
```

Where
`Dockerfile`: based on php7 for Yii2 docker image
```sh
sed -i -e "s/^FROM.*/FROM bscheshir\/php:7.2.4-fpm-4yii2/" Dockerfile
```

`composer.json`: require `codeception/specify`, `codeception/verify`

```json
    "require": {
...
        "codeception/specify": "*",
        "codeception/verify": "*"
    }
```

> Note: change workdir from `/project` to `/var/www/html`. 
This workdir is same in `php` and `nginx` container (in other yii2-based projects).
Can be use acceptance tests with same absolute path and merged "local" and "c3.php local" codecoverage. 

## codecept.phar
This repo can't modify `codecept.phar`. Origin link for PHP 7.x: `wget http://codeception.com/codecept.phar`

If you need you changes in "mothership" part of c3.php on "remote" server 
use [robo](http://robo.li/) like this (set `php.ini` option `phar.readonly = false`)
```sh
docker-compose -f ~/projects/docker-yii2-app-advanced-rbac/docker-codeception-run/docker-compose.yml run --rm --entrypoint bash codecept
cd /repo 
wget http://robo.li/robo.phar
sudo chmod +x robo.phar && mv robo.phar /usr/bin/robo
robo build:phar
```

## Usage

Development bash
```sh
docker-codeception-run$ docker-compose run --rm --entrypoint bash codecept
```

see [Parallel Execution](http://codeception.com/docs/12-ParallelExecution)

[How to start testing](https://github.com/yiisoft/yii2-app-advanced/blob/master/docs/guide/start-testing.md)


yii2-advanced tests inside `backend` `frontend` `console` folder
```sh
/usr/local/bin/docker-compose -i /home/dev/projects/docker-yii2-app-advanced-rbac/docker-codeception-run/docker-compose.yml run --rm --entrypoint bash codecept
root@e870b32bc227:/project# cd frontend/; codecept run acceptance HomeCest
```

external run
```sh
/usr/local/bin/docker-compose -f /path/to/codeception/docker-compose.yml run --rm codecept run -g paracept_1 --html result_1.html
```

### volumes
Composition volumes `project` and `.composer/cache` (in `docker-compose.yml`):
```yml
  codecept:
    image: bscheshir/codeception:php7.2.4-fpm-yii2
    depends_on:
      - php
    environment:
      XDEBUG_CONFIG: "remote_host=192.168.0.241 remote_port=9002 remote_enable=On"
      PHP_IDE_CONFIG: "serverName=codeception"
    volumes:
      - ../php-code:/project
      - ~/.composer/cache:/root/.composer/cache
```

## autocomplit
For smart IDE autocomplete copy source from the running container to `.codecept` using `docker cp` tools
```sh
docker cp dockercodeceptionrun_codecept_run_1:/repo/ .codecept
```

### Selenium
selenium in `docker-compose.yml`
```yml
  browser:
    image: selenium/standalone-firefox-debug:3.11.0
    ports:
      - '4444'
      - '5900'
```
or
```yml
  browser:
    image: selenium/standalone-chrome-debug:3.11.0
    volumes:
      - /dev/shm:/dev/shm # the docker run instance may use the default 64MB, that may not be enough in some cases
    ports:
      - '4444'
      - '5900'
```
> note: last stable comparability version is a 3.7. 
Wait for fix for newest 3.11.0

`codecept` service depends on `selenium` service


configure `acceptance.suite.yml` in `frontend/tests` like
```yml
actor: AcceptanceTester
modules:
    enabled:
# See docker-codeception-run/docker-compose.yml: "ports" of service "nginx" is null; the selenium service named "firefox"
# See nginx-conf/nginx.conf: listen 80 for frontend; listen 8080 for backend
        - WebDriver:
            url: http://nginx:80/
            host: firefox
            port: 4444
            browser: firefox
        - Yii2:
            part: init
```
or
```yml
actor: AcceptanceTester
modules:
    enabled:
# See docker-codeception-run/docker-compose.yml: "ports" of service "nginx" is null; the selenium service named "chrome"
# See nginx-conf/nginx.conf: listen 80 for frontend; listen 8080 for backend
        - WebDriver:
            url: http://nginx:8080/
            host: chrome
            port: 4444
            browser: chrome
        - \bscheshirwork\Codeception\Module\DbYii2Config:
            dump: ../common/tests/_data/dump.sql #relative path from "codeception.yml"
        - Yii2:
            part:
              - email
              - ORM
              - Fixtures
            cleanup: false # don't wrap test in transaction
        - common\tests\Helper\Acceptance

```

### yii2 index-test.php docker selenium access
After run yii2 `init` script you must change local entrypoint files 
`php-code/backend/web/index-test.php`, `php-code/frontend/web/index-test.php` for granted access from service firefox.
```php
if (!in_array(@$_SERVER['REMOTE_ADDR'], ['127.0.0.1', '::1'])) {
    die('You are not allowed to access this file.');
}
```
->
```php
//check if not in same subnet /16 (255.255.0.0)
if ((ip2long(@$_SERVER['REMOTE_ADDR']) ^ ip2long(@$_SERVER['SERVER_ADDR'])) >= 2 ** 16) {
    die('You are not allowed to access this file.');
}
```

### yii2 [docker-compose.yml](https://github.com/bscheshirwork/docker-yii2-app-advanced/blob/master/docker-codeception-run/docker-compose.yml)
```yml
version: '2'
services:
  php:
    image: bscheshir/php:7.2.4-fpm-4yii2-xdebug
    restart: always
    volumes:
      - ../php-code:/var/www/html #php-code
      - ~/.composer/cache:/root/.composer/cache
    depends_on:
      - db
    environment:
      TZ: Europe/Moscow
      XDEBUG_CONFIG: "remote_host=dev-Aspire-V3-772 remote_port=9001 var_display_max_data=1024 var_display_max_depth=5"
      PHP_IDE_CONFIG: "serverName=yii2advanced"
  nginx:
    image: nginx:1.13.12-alpine
    restart: always
    depends_on:
      - php
    volumes_from:
      - php
    volumes:
      - ../nginx-conf:/etc/nginx/conf.d #nginx-conf
      - ../nginx-logs:/var/log/nginx #nginx-logs
  db:
    image: mysql:8.0.4
    entrypoint: ['/entrypoint.sh', '--character-set-server=utf8', '--collation-server=utf8_general_ci']
    restart: always
    ports:
      - "33006:3306"
    volumes:
      - ../mysql-data-test/db:/var/lib/mysql #mysql-data
    environment:
      TZ: Europe/Moscow
      MYSQL_ROOT_PASSWORD: yii2advanced
      MYSQL_DATABASE: yii2advanced
      MYSQL_USER: yii2advanced
      MYSQL_PASSWORD: yii2advanced
  codecept:
    image: bscheshir/codeception:php7.2.4-fpm-yii2
    depends_on:
      - nginx
      - browser
    environment:
      XDEBUG_CONFIG: "remote_host=dev-Aspire-V3-772 remote_port=9002 remote_enable=On"
      PHP_IDE_CONFIG: "serverName=codeception"
    volumes:
      - ../php-code:/project
      - ~/.composer/cache:/root/.composer/cache
  browser:
    image: selenium/standalone-chrome-debug:3.7 # avoid bug in latest
#    image: selenium/standalone-firefox-debug:3.11.0
    volumes:
      - /dev/shm:/dev/shm # the docker run instance may use the default 64MB, that may not be enough in some cases
    ports:
      - '4444'
      - '5900'
```

## debug

copy source from the running container to `.codecept` using `docker cp` tools (include actual vendors)
```
docker cp dockercodeceptionrun_codecept_run_1:/repo/ .codecept
```

For xdebug tests

In PHPStorm set this settings:

Add `service` named by PHP_IDE_CONFIG
`Settings > Languages & Frameworks > PHP > Servers: [Name => codeception]`
In this service set the `path mapping`.

`Settings > Languages & Frameworks > PHP > Servers: [Use path mapping => True, /home/user/yourprojectname/.codecept => /repo, /home/user/yourprojectname/php-code => /project]`

Change port 9000 to `XDEBUG_CONFIG` `remote_port` value

`Settings > Languages & Frameworks > PHP > Debug: [Debug port => 9002]`


If you need change source inside container use `docker cp`
```
docker cp .codecept/src/Codeception/Lib/Connector/Yii2.php dockercodeceptionrun_codecept_run_1:/repo/src/Codeception/Lib/Connector/Yii2.php
docker cp .codecept/src/Codeception/Module/Yii2.php dockercodeceptionrun_codecept_run_1:/repo/src/Codeception/Module/Yii2.php
```

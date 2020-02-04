#!/bin/bash

read -p "Введите наименование Домена (с .loc): " SITE
if [[ -z "$SITE" ]]; then
  echo -e "Вы не ввели наименование домена
Работа скрипта остановлена" && exit
fi

read -p "По-умолчанию корневая папка: /var/www
Если не хотите ничего менять, нажмите enter или введите n
Если хотите изменить, введите наименование корневой папки для сайта: " $SITEDIR
if [[ -z "$DOMAIN" ]] || [ -e "$DOMAIN" == "n" ]; then
  echo -e "Вы не ввели наименование корневой папки
Корневая папка по-умолчанию: /var/www/$SITE"
  SITEDIR=/var/www/"$SITE"
fi
# --------------------------------
# 1 - Создание каталога для сайта.
# --------------------------------
echo -e "\nСоздаю каталоги..."
mkdir -p "$SITEDIR"
# -----------------------------------
# 2 - Создание базы данных для сайта.
# -----------------------------------
read -p "Создать БД? (y/n): " CASEDB
case $CASEDB in
  y)
    read -p "Введите наименование Базы Данных: " DBNAME
    if [[ -z "$DBNAME" ]]; then
      echo -e "Вы не ввели наименование БД
    Работа скрипта остановлена" && exit
    fi

    DBUSER=root
    DBPASS=123456

    echo "Создаю базу данных..."
    if [ -e "/var/lib/mysql/$DBNAME" ]; then
      echo -e "\nБаза с таким именем уже есть. Выбери другое имя для базы данных.
      Работа скрипта остановлена." && exit
    fi
    #if [ -e "CREATEUSR" == 0 ]; then
    #  Создание пользователя (раскомментировать если нужен новый пользователь).
    #  mysql -u root -p"$ROOTPASS" -e "create user "$DBUSER"@'localhost' identified by '$DBPASS';"
    #fi
    # Создание базы данных и назначение привилегий пользователя.
    mysql -u root -p"$DBPASS" -e "create database "$DBNAME"; grant all on "$DBNAME".* to "$DBUSER"@'localhost'; flush privileges;"
    if [ "$?" != 0 ]; then
      echo -e "\nВо время создания базы возникла ошибка.
      Работа скрипта остановлена." && exit
    fi
    echo -e "\nБаза данных успешно создана!
    База данных: $DBNAME
    Пользователь базы данных: $DBUSER
    Пароль пользователя: $DBPASS"

    read -p "Выполнить установку WORDPRESS с помощью wp-cli? (y/n): " CASEWP
    case $CASEWP in
      y)
        # Переменные для установки wordpress через wp-cli.
        URL=http://"$SITE"
        # настройки для WP
        DBPREFIX=wp_
        DBHOST=localhost
        TITLE="Test website on wordpress"
        ADMINUSER=admin
        ADMINPASS=123456
        ADMINEMAIL=admin@"$SITE"
        # -----------------------------------------
        # 3 - Установка wordpress c помощью wp-cli.
        # -----------------------------------------
        if [ -e "/usr/bin/wp" ]; then
          echo -e "\nwp-cli уже установлен"
        else
          echo -e "\nУстанавливаю wp-cli"
          wget -c https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
          if [ -e "wp-cli.phar" ]; then
            chmod +x wp-cli.phar
            mv wp-cli.phar /usr/bin/wp
          else
            echo -e "\nwp-cli не установлена
            Работа скрипта остановлена" && exit
          fi
        fi
        echo -e "\nСкачиваю wordpress..."
        cd "$SITEDIR"
        # Скачиваем русскую версию wordpress
        #wp core download --locale=ru_RU --path="$SITEDIR" --allow-root
        WPARCH=latest-ru_RU.tar.gz
        wget -c https://ru.wordpress.org/"$WPARCH"
        if [ -e "$WPARCH" ]; then
          echo -e "\nРаспаковываю и переношу файлы wordpress..."
          tar -xzvf "$WPARCH"
          mv wordpress/* "$SITEDIR" && rm -rf wordpress/ && rm -rf "$WPARCH" && rm -rf rm -rf "$SITEDIR"/readme.html
        else
          echo -e "\nАхив с wordpress не найден...
          Работа скрипта остановлена" && exit
        fi
        echo -e "\nУстанавливаю wordpress..."
        # Создание wp-config.php
        wp core config --dbname="$DBNAME" --dbuser="$DBUSER" --dbpass="$DBPASS" --dbhost="$DBHOST" --dbprefix="$DBPREFIX" --locale=ru_RU --allow-root
        # Установка wordpress
        wp core install --url="$URL" --title="$TITLE" --admin_user="$ADMINUSER" --admin_password="$ADMINPASS" --admin_email="$ADMINEMAIL" --allow-root
        # Удаление записей
        #wp post delete 1 --allow-root
        # Удаление страниц
        #wp post delete 2 --allow-root
        #wp post delete 3 --allow-root
        # Удаление плагинов
        wp plugin delete hello --allow-root
        wp plugin delete akismet --allow-root
        #статус плагинов
        wp plugin status --path="$SITEDIR" --allow-root
        # Установка вида постоянных ссылок
        #wp rewrite structure "/%postname%/" --allow-root
        #wp rewrite flush --allow-root
      ;;
      *)
        echo -e "\nWORDPRESS не будет установлен с помощью wp-cli"
        cd "$SITEDIR"
        # Скачиваем русскую версию wordpress
        #wp core download --locale=ru_RU --path="$SITEDIR" --allow-root
        WPARCH=latest-ru_RU.tar.gz
        wget -c https://ru.wordpress.org/"$WPARCH"
        if [ -e "$WPARCH" ]; then
          echo -e "\nРаспаковываю и переношу файлы wordpress..."
          tar -xzvf "$WPARCH"
          mv wordpress/* "$SITEDIR" && rm -rf wordpress/ && rm -rf "$WPARCH" && rm -rf rm -rf "$SITEDIR"/readme.html
        else
          echo -e "\nАхив с wordpress не найден...
          Работа скрипта остановлена" && exit
        fi
      ;;
    esac
  ;;
  *)
    echo -e "\nПродолжаю без БД..."
    echo -e "<?php phpinfo();?>" >> "$SITEDIR"/index.php
  ;;
esac
# ---------------------------------------------
# 4 - Назначение прав доступа к каталогу сайта.
# ---------------------------------------------
echo -e "\nНазначаю права и владельца каталога..."
chown -R www-data:www-data "$SITEDIR"
chmod -R 777 "$SITEDIR"
# --------------------------------
# 5 - конфиг apache + nginx
# --------------------------------
if [ -e "/etc/apache2/sites-available/$SITE.conf" ]; then
  echo -e "Конфигурационные файлы APACHE2 и NGINX уже существуют"
else
  echo -e "<VirtualHost *:81>
            ServerName $SITE
            DocumentRoot $SITEDIR
            ErrorLog ${APACHE_LOG_DIR}/$SITE-error.log
            CustomLog ${APACHE_LOG_DIR}/$SITE-access.log combined
</VirtualHost>" >> /etc/apache2/sites-available/"$SITE".conf
  a2ensite "$SITE"
  echo -e "server {
            listen 80;
            listen [::]:80;
            server_name $SITE www.$SITE;
            root $SITEDIR;
            index index.php;
            location = /favicon.ico {
                    log_not_found off;
                    access_log off;
            }
            location = /robots.txt {
                    allow all;
                    log_not_found off;
                    access_log off;
            }
            location ~ /\. {
                    deny all; # запрет для скрытых файлов
            }
#            location ~* /(?:uploads|files)/.*\.(php|php3|php4|php5|php6|phps|phtml)$ {
#                    deny all;
#            }
            location ~* ^.+\.(ogg|ogv|svg|svgz|eot|otf|woff|mp4|ttf|rss|atom|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav|bmp|rtf)$ {
                    access_log off;
                    log_not_found off;
                    expires max; # кеширование статики
            }" >> /etc/nginx/sites-available/"$SITE"
  echo -e '	location / {
                    try_files $uri $uri/ /index.php?$args; # permalinks
            }
            location ~ \.php$ {
                    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                    fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
                    fastcgi_index index.php;
                    include fastcgi_params;
            }
  }' >> /etc/nginx/sites-available/"$SITE"
  ln -s /etc/nginx/sites-available/"$SITE" /etc/nginx/sites-enabled/"$SITE"
  echo -e "127.0.0.1	$SITE	www.$SITE" >> /etc/hosts
fi

echo -e "\nПерезагружаю APACHE2 && NGINX..."
systemctl restart apache2 && systemctl restart nginx

echo -e "\nРабота скрипта успешно завершена!" && exit 0

#!/bin/bash

read -p "Введите наименование сайта с .loc " SITE
if [[ -z "$SITE" ]]; then
	echo -e "\nВы не ввели название сайта
Работа скрипта остановлена" && exit
fi

read -p "Удалить БД? (y/n): " DELDB
if [ -e $DELDB == 'y' ]; then
    read -p "Введите наименование БД: " DBNAME
    if [[ -z "$DBNAME" ]]; then
      echo -e "Вы не ввели наименование БД
Работа скрипта остановлена" && exit
    fi
    mysql -u "$DBUSER" -p"$DBPASS" -e "DROP DATABASE $DBNAME;"
fi

DBUSER=root
DBPASS=123456

rm -rf /etc/nginx/sites-available/"$SITE"
rm -rf /etc/nginx/sites-enabled/"$SITE"
rm -rf /etc/apache2/sites-available/"$SITE".conf
rm -rf /etc/apache2/sites-enabled/"$SITE".conf
rm -rf /var/www/"$SITE"

sed -i "/$SITE$/d" /etc/hosts

echo -e "\nSuccess!"

# bash: скрипт генерации файлов конфигурации для NGINX
# Имеется WebApp в Azure. В нему подключены 85 доменов.
# Задача — для каждого из подключенных доменов сгенерировать файлы настроек для NGINX, который будет проксировать запросы к этмоу WebApp.
# 
# Список подключенных доменов получется с помощью Azure CLI — azure webapp show.
# 
# Задача усложняется тем, что некоторые домены подключены к WebApp с www, а некоторые — без. Соответственно — в настройках NGINX надо определить направление переадресации с-www => без-www или наоборот.
# 
# Для этого — используется два файла шаблонов для NGINX.
# 
# Для доменов, которые подключены к WebApp напрямую, без www — устанавливается переадресация с www-имени на имя без него:
# 
# upstream jm_live_X_RAND {
#     server 65.***.***.88;
# }
# ...
# server {
#     server_name www.SERVER_NAME;
#     return 301 http://SERVER_NAME$request_uri;
# }
# server {
#     server_name SERVER_NAME;
#     ...
# }
# 
# для тех доменов, которые подключены с www — переадресация наоборот:
# ...
# server {
#     server_name SERVER_NAME;
#     return 301 http://www.SERVER_NAME$request_uri;
# }
# server {
#     server_name www.SERVER_NAME;
# ...
# 
# скрипт:

#!/usr/bin/env bash

# include /etc/nginx/migrate.d/*.conf;

resource_group="Default-Web-WestEurope"
webapp_name="jm"
confdir="configs"

# non-www redirects to www
www_template="nginx_conf-www.tmpl"

# www redirects to non-www
n_w_template="nginx_conf-n_w.tmpl"

# for testing
# att=0
# max=20

is_www () {
    local domain=$1
    [[ $domain =~ "www" ]]
}
get_domains () {
    domains=$(azure webapp show $resource_group $webapp_name | grep -A100  "Host Name" | grep "." | grep -v "-" | grep -v "Host Name" | grep -v "azurewebsites" | tac | sed "1,2d" | cut -d":" -f 2 | xargs)
    echo $domains
}

remove_www () {
    local domain=$1
    is_www $domain && domain=$(sed 's/www.//' <<< $domain)
    echo $domain
}

copy_template () {
    local domain=$1
    [[ ! -e $confdir/$domain.conf ]] && cp -v $template $confdir/$domain.conf || echo "$domain.conf already added, skip"
}

update_config () {
    local domain=$1
    local config=$2
    local x_rand=$(shuf -i 1000-9000 -n 1)
    sed -i 's/X_RAND/'"$x_rand"'/g' $config
    sed -i 's/SERVER_NAME/'"$domain"'/g' $config
}

main () {
    for domain in $(get_domains); do
        # depending on how domain was added to the WebApp - with or without WWW
        # select template to use
        is_www $domain && local template=$www_template || local template=$n_w_template
        # remove www
        domain=$(remove_www $domain)
        # copy template
        copy_template $domain
        # update configs
        update_config $domain $confdir/$domain.conf
        # for testing - create 4 config only
        # ((att++)) && [[ $att == $max ]] && { echo "Max."; exit 0; }
    done
}

main
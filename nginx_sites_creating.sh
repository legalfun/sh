sudo mkdir -p /var/www/$1/html
sudo chown -R $USER:$USER /var/www/$1/html
sudo chmod -R 755 /var/www/$1
sudo echo "$1" > /var/www/$1/html/index.html
sudo sh nginx_sites_generate_config.sh $1 > /etc/nginx/sites-available/$1

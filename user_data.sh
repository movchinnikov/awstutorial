#!/bin/bash
sudo dnf update
yum update -y
yum install -y httpd
sudo dnf install postgresql15.x86_64 postgresql15-server -y

# Стартуем Apache
systemctl start httpd
systemctl enable httpd

sudo postgresql-setup --initdb
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Определяем переменные для подключения к RDS
DB_HOST="${aws_db_instance.postgres_rds.endpoint}"
DB_USER="test"
DB_PASSWORD="admin123"
DB_NAME="${var.prefix}DB"

# Генерируем HTML страницу с информацией о базе данных
echo "<html><body><h1>Database Info</h1>" | sudo tee /var/www/html/index.html
echo "<p>Database Host: $DB_HOST</p>" | sudo tee /var/www/html/index.html
echo "<p>Database Name: $DB_NAME</p>" | sudo tee /var/www/html/index.html
echo "<h2>Sample Query Result:</h2>" | sudo tee /var/www/html/index.html

# Подключаемся к PostgreSQL и выполняем запрос
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';" | awk 'BEGIN{print "<table border=1>"} {print "<tr><td>" $1 "</td></tr>"} END{print "</table>"}' | sudo tee /var/www/html/index.html

echo "</body></html>" | sudo tee /var/www/html/index.html
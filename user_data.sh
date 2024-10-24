#!/bin/bash
DB_USER="test"
DB_PASSWORD="admin123"
DB_NAME="maxovDB"
RDS_IP=$(nslookup "maxov-postgres-rds.czswoaei837e.us-east-1.rds.amazonaws.com" | awk '/^Address: / { print $2 }')

# Update packages and install necessary tools: Apache (httpd) and PostgreSQL client
sudo dnf update -y
sudo yum install -y httpd postgresql15 nc

# Start and enable Apache service
sudo systemctl start httpd
sudo systemctl enable httpd

# Wait for PostgreSQL to be ready after installing the client
until nc -z -w5 "$RDS_IP" 5432; do
  echo "Waiting for PostgreSQL database to be ready..."
  sleep 30
done

# Start building HTML output
echo "<html lang='en'>" | sudo tee /var/www/html/index.html
echo "<head>" | sudo tee -a /var/www/html/index.html
echo "<meta charset='UTF-8'>" | sudo tee -a /var/www/html/index.html
echo "<meta name='viewport' content='width=device-width, initial-scale=1.0'>" | sudo tee -a /var/www/html/index.html
echo "<title>Countries Page</title>" | sudo tee -a /var/www/html/index.html
echo "</head>" | sudo tee -a /var/www/html/index.html
echo "<body><h1>Countries</h1>" | sudo tee -a /var/www/html/index.html

# Run SQL commands to create and populate the "countries" table in the remote database
PGPASSWORD=$DB_PASSWORD psql -h $RDS_IP -U "$DB_USER" -d "$DB_NAME" << SQL
    CREATE TABLE IF NOT EXISTS countries (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100),
        code VARCHAR(5),
        flag_emoji VARCHAR(5)
    );

    DELETE FROM countries;

    INSERT INTO countries (name, code, flag_emoji) VALUES
    ('United States', 'US', '🇺🇸'),
    ('Canada', 'CA', '🇨🇦'),
    ('United Kingdom', 'GB', '🇬🇧'),
    ('Germany', 'DE', '🇩🇪'),
    ('France', 'FR', '🇫🇷'),
    ('Japan', 'JP', '🇯🇵'),
    ('Russia', 'RU', '🇷🇺'),
    ('Brazil', 'BR', '🇧🇷'),
    ('India', 'IN', '🇮🇳'),
    ('China', 'CN', '🇨🇳');

    COMMIT;
SQL

# Generate HTML table with the countries data
PGPASSWORD=$DB_PASSWORD psql -h $RDS_IP -U "$DB_USER" -d "$DB_NAME" -c "SELECT * FROM countries;" -t | \
awk 'BEGIN {
        print "<table border=\"1\">"
        print "<tr><th>ID</th><th>Name</th><th>Code</th><th>Flag Emoji</th></tr>"
    }
    {
        gsub(/^ +| +$/, "", $0)
        split($0, columns, "|")
        print "<tr><td>" columns[1] "</td><td>" columns[2] "</td><td>" columns[3] "</td><td>" columns[4] "</td></tr>"
    }
    END {
        print "</table>"
    }' | sudo tee -a /var/www/html/index.html

echo "</body></html>" | sudo tee -a /var/www/html/index.html

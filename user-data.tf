# locals {
#   userdata1 = <<-EOF
# #!/bin/bash

# # Update system
# sudo yum update -y

# # Install Apache, php, wget and other plugins
# sudo yum install wget httpd php php-mysqlnd php-gd php-xml php-mbstring -y

# sudo echo "This is a test file" > /var/www/html/indextest.html

# # Download and install WordPress
# sudo wget https://wordpress.org/latest.tar.gz
# sudo tar -xzf latest.tar.gz -C /tmp/
# sudo cp -r /tmp/wordpress/* /var/www/html/
# sudo chown -R apache:apache /var/www/html/
# sudo chmod -R 755 /var/www/html/

# # Configure WordPress to connect to the database server
# sudo mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
# sudo sed -i 's/database_name_here/wordpress/g' /var/www/html/wp-config.php
# sudo sed -i 's/username_here/admin/g' /var/www/html/wp-config.php
# sudo sed -i 's/password_here/admin123/g' /var/www/html/wp-config.php
# sudo sed -i 's/localhost/${aws_instance.mysql_ec2.private_ip}/g' /var/www/html/wp-config.php
# sudo sed -i "s@define( 'WP_DEBUG', false )@define( 'WP_DEBUG', true )@g" /var/www/html/wp-config.php

# # Start Apache and enable it to start on boot
# sudo systemctl start httpd
# sudo systemctl enable httpd
# EOF  
# }


locals {
  userdata1 = <<-EOF
#!/bin/bash
sudo yum install httpd php php-mysqlnd -y
cd /var/www/html
echo "This is a test file" > indextest.html
sudo yum install wget -y
wget https://wordpress.org/wordpress-6.3.1.tar.gz
tar -xzf wordpress-6.3.1.tar.gz
sudo cp -r wordpress/* /var/www/html/
rm -rf wordpress
rm -rf wordpress-6.3.1.tar.gz
sudo chmod -R 755 wp-content
sudo chown -R apache:apache wp-content
cd /var/www/html && mv wp-config-sample.php wp-config.php
sed -i "s@define( 'DB_NAME', 'database_name_here' )@define( 'DB_NAME', 'wordpress')@g" /var/www/html/wp-config.php
sed -i "s@define( 'DB_USER', 'username_here' )@define( 'DB_USER', 'admin')@g" /var/www/html/wp-config.php
sed -i "s@define( 'DB_PASSWORD', 'password_here' )@define( 'DB_PASSWORD', 'admin123')@g" /var/www/html/wp-config.php
sed -i "s@define( 'WP_DEBUG', false )@define( 'WP_DEBUG', true )@g" /var/www/html/wp-config.php
sed -i "s@define( 'DB_HOST', 'localhost' )@define( 'DB_HOST', '${element(split(":", aws_db_instance.db-main.endpoint), 0)}' )@g" /var/www/html/wp-config.php
chkconfig httpd on
sudo systemctl restart httpd
sudo chmod 777 -R /var/www/html/

sudo setenforce 0
sudo systemctl restart httpd
EOF  
}
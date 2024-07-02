locals {
  userdata2 = <<-EOF
#!/bin/bash

# Update system
sudo yum update -y

# Install mysql
sudo yum install mysql-server -y

# Start mysql and enable it to start on boot
sudo systemctl start mysqld
sudo systemctl enable mysqld

# Configure database for WordPress
sudo mysql -u root <<EOT
CREATE DATABASE wordpress;
CREATE USER 'admin'@'%' IDENTIFIED BY 'admin123';
GRANT ALL PRIVILEGES ON wordpress.* TO 'admin'@'%';
EXIT;
EOT 
sudo hostnamectl set-hostname mysql
EOF 
}
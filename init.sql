use mysql;
CREATE USER 'root'@'%';
ALTER USER 'root'@'%' IDENTIFIED with mysql_native_password by @MYSQL_ROOT_PASSWORD;
grant all privileges on *.* to "root"@"%";
#update user set host = '%' where user = 'root';
flush privileges;

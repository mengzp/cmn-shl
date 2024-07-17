use mysql;
-- CREATE USER 'root'@'%';
-- ALTER USER 'root'@'%' IDENTIFIED with mysql_native_password by 'Admin123!';
-- grant all privileges on *.* to "root"@"%";
-- #update user set host = '%' where user = 'root';

CREATE USER 'dbadm'@'%';
ALTER USER 'dbadm'@'%' IDENTIFIED with mysql_native_password by 'Admin123!';
grant all privileges on *.* to "dbadm"@"%";
flush privileges;

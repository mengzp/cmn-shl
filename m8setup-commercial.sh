#!/bin/bash

MYSQL_DATA_PATH=/var/lib/mysql
MYSQL_BINLOG_DIR=/usr02
MYSQL_TEMP_DIR=/usr10
MYSQL_ROOT_PASSWORD=Admin123!
MYSQL_VERSION=8.0.36-1.1.el8.x86_64
MYSQL_LICENCE_VERSION=commercial

MYSQL_SERVER_ID=4112
MYSQL_PORT=3306
MYSQL_INNODB_BUFFER_POOL_SIZE=1

ps aux | grep 'mysql' | grep -v 'grep' | grep -v 'bash'
if [ $? -eq 0 ]; then
	echo "MySQL already started, don't need install again!"
	exit 0
fi


if [ -z "$MYSQL_ROOT_PASSWORD" ];then
 echo "MYSQL_ROOT_PASSWORD is empty"
 exit 0
fi


echo "mysql install start... "

INIT_MYSQL(){

    #read -t 30 -e -p "输入你的数据库  :  " dbname
    read -t 30 -e -p "please input your mysql port:  " mysql_port
    read -t 30 -e -p "please input mysql serverId:  " mysql_server_id
    read -t 30 -e -p "please input innodb_buffer_pool_size, the unit is G:  " mysql_innodb_buffer_pool_size
		
    if [ ! -z "$mysql_port" ];then
	MYSQL_PORT=$mysql_port
    fi
    if [ ! -z "$mysql_server_id" ];then
	MYSQL_SERVER_ID=$mysql_server_id
    fi
    if [ ! -z "$mysql_innodb_buffer_pool_size" ];then
	MYSQL_INNODB_BUFFER_POOL_SIZE=$mysql_innodb_buffer_pool_size
    fi
	
	# 卸载系统⾃带的MARIADB
	rpm -qa | grep mariadb | xargs yum remove -y > /dev/null
	# disable SELINUX
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	
    echo "Mysql Port:" $MYSQL_PORT
    echo "MySQL serverId:" $MYSQL_SERVER_ID
    echo "INNODB_BUFFER_POOL_SIZE:" $MYSQL_INNODB_BUFFER_POOL_SIZE "GB"
    echo "Mysql data path:" $MYSQL_DATA_PATH
    
    group=mysql
    egrep "^$group" /etc/group >& /dev/null
    if [ $? -ne 0 ]; then
		groupadd $group
    fi
    user=mysql
    egrep "^$user" /etc/passwd >& /dev/null
    if [ $? -ne 0 ]; then
		useradd -g  $group $user
    fi
    
   
    if [ ! -d ${MYSQL_TEMP_DIR} ];then
		mkdir ${MYSQL_TEMP_DIR}
    fi
    chown -R mysql.mysql ${MYSQL_TEMP_DIR}
    chmod 750 ${MYSQL_TEMP_DIR}
   

    if [ ! -d "${MYSQL_DATA_PATH}" ];then
		mkdir -p ${MYSQL_DATA_PATH}
    fi
    chown -R mysql.mysql ${MYSQL_DATA_PATH}
    chmod 750 ${MYSQL_DATA_PATH}
    

    if [ ! -d "MYSQL_BINLOG_DIR" ];then
		mkdir -p ${MYSQL_BINLOG_DIR}
    fi
    chown -R mysql.mysql ${MYSQL_BINLOG_DIR}
    chmod 750 ${MYSQL_BINLOG_DIR}
    	

    ###install mysql server
	
    yum install -y libaio  libnuma* net-tools perl compat-openssl10 libncurses* libtinfo*
    #yum install -y xz numactl* jemalloc* libaio* net-tools nload iftop sysstat wget vim ntpdate lrzsz 
    rpm -ivh ./package/mysql-${MYSQL_LICENCE_VERSION}-common-$MYSQL_VERSION.rpm
    rpm -ivh ./package/mysql-${MYSQL_LICENCE_VERSION}-client-plugins-$MYSQL_VERSION.rpm
    rpm -ivh ./package/mysql-${MYSQL_LICENCE_VERSION}-libs-$MYSQL_VERSION.rpm 
    rpm -ivh ./package/mysql-${MYSQL_LICENCE_VERSION}-icu-data-files-$MYSQL_VERSION.rpm
    rpm -ivh ./package/mysql-${MYSQL_LICENCE_VERSION}-client-$MYSQL_VERSION.rpm 
    rpm -ivh ./package/mysql-${MYSQL_LICENCE_VERSION}-server-$MYSQL_VERSION.rpm
    rpm -ivh ./package/mysql-${MYSQL_LICENCE_VERSION}-backup-$MYSQL_VERSION.rpm
	
    sed "s|3306|$MYSQL_PORT|;s|@serverid|$MYSQL_SERVER_ID|;s|@datadir|$MYSQL_DATA_PATH|;s|@buffersize|$MYSQL_INNODB_BUFFER_POOL_SIZE|" _my.cnf > /etc/my.cnf
	if [ $? -ne 0 ];then
	echo 'Failed to replace /etc/init.d/mysqld!!!'
	exit
	else
	echo '===================================='
	echo '/etc/init.d/mysqld successfully modified!'
	echo '===================================='
	fi
	
    echo "mysql init"
    #mysqld  --initialize --user=mysql --datadir=${MYSQL_DATA_PATH} > ./tmppwd 2>&1    
    mysqld  --initialize --user=mysql --datadir=${MYSQL_DATA_PATH}
    #mysqld --daemonize --pid-file=/var/run/mysqld/mysqld.pid --user=mysql
   

	# 设置MYSQL系统服务并开启⾃启
	systemctl enable mysqld
	systemctl start mysqld &
	
	while true
	do
		 netstat -ntlp | grep $dbport
		 if [ $? -eq 1 ]
		 then
			echo "MySQL Starting,please wait......"
			sleep 2
			continue
		 else
			if [ ! -e "/var/lib/mysql/mysql.sock" ];then
				echo "MySQL Starting,please wait......"
				sleep 2
				continue
			fi
			break
		 fi
	done

	ps aux | grep 'mysql' | grep -v 'grep' | grep -v 'bash'
	if [ $? -eq 0 ]
	then
		echo "MySQL init completed"
	else
		echo "MySQL install error!"
		exit 1
	fi
   ###更改root账号随机密码
   dbPassword=`grep 'temporary password' /var/log/mysqld.log | awk -F ' ' 'END{print $NF}'`
   #dbPassword=`grep 'temporary password' /var/log/mysqld.log | awk -F ' ' '{print $NF}'`
   if [ -z "$dbPassword" ];then
	 echo "fetch temporary password error,please fix it manually"
	 exit 0
   fi
   echo "Mysql temporary password is ${MYSQL_ROOT_PASSWORD}"
   mysqladmin -uroot -p'$dbPassword' password  $MYSQL_ROOT_PASSWORD
   host='127.0.0.1'
   dbUser='root'
   sql_file='./init.sql'
   sed -i "s/@MYSQL_ROOT_PASSWORD/'${MYSQL_ROOT_PASSWORD}'/g" $sql_file
   mysql -h $host -u $dbUser -p'$MYSQL_ROOT_PASSWORD' -e "source $sql_file";
   echo "Remote connection is set successfully!"
   echo "MySQL install completed!"
   
   #rm -f ./tmppwd
}
if [ ! -d $MYSQL_DATA_PATH ]; then
   mkdir $MYSQL_DATA_PATH
fi
if [ `cd $MYSQL_DATA_PATH && ls  |wc -l` -eq 0 ];then
   INIT_MYSQL
else
   #mysqld --daemonize --pid-file=/var/run/mysqld/mysqld.pid --user=mysql
   systemctl start mysqld
fi
#cat /var/log/mysqld.log

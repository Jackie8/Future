#!/bin/bash
touch /root/install.zabbix
touch /root/fail.zabbix

#配置epel源
rpm -Uvh http://mirrors.ustc.edu.cn/fedora/epel/6/x86_64/epel-release-6-8.noarch.rpm
if [ $? -eq 0 ]
	then
		echo "epel ok" >> /root/install.zabbix
	else
		echo "epel no " >> /root/fail.zabbix
fi
#安装依赖包
yum -y install wget vim tree gcc gcc-c++ autoconf httpd mysql mysql-server httpd-manual mod_ssl mod_perl mod_auth_mysql php-xml php-xmlrpc mysql-connector-odbc mysql-devel libdbi-dbd-mysql net-snmp net-snmp-devel curl-develet-snmp net-snmp-devel curl-devel
if [ $? -eq 0 ]
	then
		echo "package install ok" >> /root/install.zabbix
	else
		echo "package install no" >> /root/fail.zabbix
fi
#卸载旧版本php
yum -y  remove php  php-bcmath php-cli php-common  php-devel php-fpm    php-gd php-imap  php-ldap php-mbstring php-mcrypt php-mysql   php-odbc   php-pdo   php-pear  php-pecl-igbinary  php-xml php-xmlrpc
if [ $? -eq 0 ]
	then
		echo "old php remove ok" >> /root/install.zabbix
	else
		echo "old php remove no" >> /root/fail.zabbix
fi

#安装新的版本php
rpm -Uvh http://mirror.webtatic.com/yum/el6/latest.rpm
yum -y install php55w  php55w-bcmath php55w-cli php55w-common  php55w-devel php55w-fpm    php55w-gd php55w-imap  php55w-ldap php55w-mbstring php55w-mysql   php55w-odbc   php55w-pdo   php55w-pear  php55w-pecl-igbinary  php55w-xml php55w-xmlrpc php55w-opcache php55w-intl php55w-pecl-memcache
if [ $? -eq 0 ]
	then
		echo "The new php install ok" >> /root/install.zabbix
	else
		echo "The new php install no" >> /root/fail.zabbix
fi
#启动 httpd、mysql 并设置成开机自动启动
service httpd start
if [ $? -eq 0 ]
	then
		echo "httpd start is ok" >> /root/install.zabbix
	else
		echo "httpd start is  no" >> /root/fail.zabbix
fi
service mysqld start
if [ $? -eq 0 ]
	then
		echo "mysql start is  ok" >> /root/install.zabbix
	else
		echo "mysql start is  no" >> /root/fail.zabbix
fi

chkconfig httpd on
if [ $? -eq 0 ]
	then
		echo "chkconfig httpd is  ok" >> /root/install.zabbix
	else
		echo "chkconfig httpd  is no" >> /root/fail.zabbix
fi
chkconfig mysqld on
if [ $? -eq 0 ]
	then
		echo "chkconfig mysql is  ok" >> /root/install.zabbix
	else
		echo "chkconfig mysql  is no" >> /root/fail.zabbix
fi
#设置iptables策略
iptables -I INPUT -p tcp -m multiport --destination-port 80,10050:10051 -j ACCEPT
service iptables save
#修改php配置
sed -i "s@;date.timezone =@date.timezone = Asia/Shanghai@g" /etc/php.ini
if [ $? -eq 0 ]
	then
		echo "php canshu 0 " >> /root/install.zabbix
fi
sed -i "s@max_execution_time = 30@max_execution_time = 300@g" /etc/php.ini
if [ $? -eq 0 ]
	then
		echo "php canshu 0 " >> /root/install.zabbix
fi
sed -i "s@post_max_size = 8M@post_max_size = 32M@g" /etc/php.ini
if [ $? -eq 0 ]
	then
		echo "php canshu 0 " >> /root/install.zabbix
fi
sed -i "s@max_input_time = 60@max_input_time = 300@g" /etc/php.ini
if [ $? -eq 0 ]
	then
		echo "php canshu 0 " >> /root/install.zabbix
fi
sed -i "s@memory_limit = 128M@memory_limit = 128M@g" /etc/php.ini
if [ $? -eq 0 ]
	then
		echo "php canshu 0 " >> /root/install.zabbix
fi
#添加 zabbix 用户和组
groupadd -g 201 zabbix
if [ $? -eq 0 ]
	then
		echo "group zabbix is ok  " >> /root/install.zabbix
	else
		echo "group zabbix is no " >> /root/fail.zabbix
fi
useradd -g zabbix -u 201 -s /sbin/nologin zabbix
if [ $? -eq 0 ]
	then
		echo "user zabbix is ok  " >> /root/install.zabbix
	else
		echo "user zabbix is no " >> /root/fail.zabbix
fi
#安装 zabbix-server 端
tar zxf zabbix-3.0.4.tar.gz
cd zabbix-3.0.4
./configure --prefix=/usr/local/zabbix --enable-server --enable-proxy --enable-agent --with-mysql=/usr/bin/mysql_config --with-net-snmp --with-libcurl
make -j 4
make install
if [ $? -eq 0 ]
	then
		echo "install zabbix is ok  " >> /root/install.zabbix
	else
		echo "install zabbix is no " >> /root/fail.zabbix
fi
#数据库导入数据
mysql -e "create database zabbix default charset utf8;"
mysql -e "grant all on zabbix.* to zabbix@localhost identified by 'zabbix';"
if [ $? -eq 0 ]
	then
		echo "DB DBUSER zabbix is ok  " >> /root/install.zabbix
	else
		echo "DB DBUSER zabbix is no " >> /root/fail.zabbix
fi
mysql -uzabbix -pzabbix zabbix< /root/zabbix-3.0.4/database/mysql/schema.sql
mysql -uzabbix -pzabbix zabbix< /root/zabbix-3.0.4/database/mysql/images.sql
mysql -uzabbix -pzabbix zabbix< /root/zabbix-3.0.4/database/mysql/data.sql
if [ $? -eq 0 ]
	then
		echo "DATA zabbix is ok  " >> /root/install.zabbix
	else
		echo "DATA zabbix is no " >> /root/fail.zabbix
fi
#配置软连接和启动文件信息

mkdir /var/log/zabbix
chown zabbix.zabbix /var/log/zabbix
ln -s /usr/local/zabbix/etc/ /etc/zabbix
ln -s /usr/local/zabbix/bin/* /usr/bin/
ln -s /usr/local/zabbix/sbin/* /usr/sbin/
cp -f /root/zabbix-3.0.4/misc/init.d/fedora/core/zabbix_server /etc/init.d/
chmod 755 /etc/init.d/zabbix_server
if [ $? -eq 0 ]
	then
		echo "zabbix START SCRIPTS is ok  " >> /root/install.zabbix
	else
		echo "zabbix START SCRIPTS is no " >> /root/fail.zabbix
fi
#修改/etc/init.d 目录下的 zabbix_server
sed -i "s@BASEDIR=/usr/local@BASEDIR=/usr/local/zabbix@g" /etc/init.d/zabbix_server
sed -i "s@DBUser=root@DBUser=zabbix@g" /etc/zabbix/zabbix_server.conf
sed -i "s@# DBPassword=@DBPassword=zabbix@g" /etc/zabbix/zabbix_server.conf
if [ $? -eq 0 ]
	then
		echo "zabbix USER PASS SET  is ok  " >> /root/install.zabbix
	else
		echo "zabbix USER PASS SET  is no  " >> /root/fail.zabbix
fi
#复制 zabbix 站点的文件到/var/www/html 目录下
cp -rf /root/zabbix-3.0.4/frontends/php/ /var/www/html/zabbix
chown -R apache:apache /var/www/html/zabbix/
if [ $? -eq 0 ]
	then
		echo "zabbix WEB  is ok  " >> /root/install.zabbix
	else
		echo "zabbix WEB is no  " >> /root/fail.zabbix
fi
chkconfig zabbix_server on
service zabbix_server start

if [ $? -eq 0 ]
	then
		echo "zabbix SERVER START  is ok  " >> /root/install.zabbix
	else
		echo "zabbix SERVER START   is no  " >> /root/fail.zabbix
fi

setenforce 0
service httpd restart
echo $(netstat -anlpt | grep httpd) >> /root/install.zabbix
echo $(netstat -anlpt | grep mysqld ) >>  /root/install.zabbix
echo $(netstat -anlpt | grep zabbix ) >> /root/install.zabbix


                           

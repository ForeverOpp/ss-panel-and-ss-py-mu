#!/bin/bash
Select_interface_kind() {
# -------------------------------------------------------------------------- #
# This function will let user choose their way to connect the interface of ss.
# For example:
# Select_interface_kind
# install_node_for_centos
# ## By the way, what the hell is the name of these functions? ##
# -------------------------------------------------------------------------- #
	clear
	read -p "请指定接口对接方式\[1、MySQL, 2、网页\]（默认网页对接）: " interface_kind
	Setting_node_information $interface_kind
}

Shut_down_iptables(){
	yum -y install iptables iptables-services
	iptables -F;iptables -X
	iptables -I INPUT -p tcp -m tcp --dport 22:65535 -j ACCEPT
	iptables -I INPUT -p udp -m udp --dport 22:65535 -j ACCEPT
	iptables-save > /etc/sysconfig/iptables
	echo 'iptables-restore /etc/sysconfig/iptables' >> /etc/rc.local
}

Shut_down_firewall(){
	yum -y install firewalld
	systemctl stop firewalld.service
	systemctl disable firewalld.service
}

Setting_node_information(){
	clear;echo "设定服务端信息: "
	case $1 in
		1 )
			API_INTERFACE="glzjinmod"
			echo "如需数据库SSL请手动设置！"
			read -p "(1/7)前端地址: " Front_end_address
				if [[ ${Front_end_address} = '' ]];then
					Front_end_address=`curl -s "https://myip.ipip.net" | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"`
					echo "已将前端地址设置为: http://${Front_end_address}"
				fi
			read -p "(2/7)节点ID: " Node_ID
			read -p "(3/7)数据库地址: " MYSQL_HOST
	   	read -p "(4/7)数据库端口: " MYSQL_PORT
	   	read -p "(5/7)数据库用户: " MYSQL_USER
	   	read -p "(6/7)数据库密码: " MYSQL_PASS
	   	read -p "(7/7)数据库名: " MYSQL_DB

			if [[ ${Node_ID} = '' ]]; then
				Node_ID=2
			fi
			if [[ ${MYSQL_HOST} = '' ]]; then
				MYSQL_HOST="127.0.0.1"
			fi
			if [[ ${MYSQL_PORT} = '' ]]; then
				MYSQL_PORT=3306
			fi
			if [[ ${MYSQL_USER} = '' ]]; then
				MYSQL_USER="root"
			fi
			if [[ ${MYSQL_PASS} = '' ]]; then
				MYSQL_PASS="root"
			fi
			if [[ ${MYSQL_DB} = '' ]]; then
				MYSQL_DB="sspanel"
			fi

			echo "好了，以下是您的配置: "
			echo "
			#################################
				前端地址: ${Front_end_address}
				节点ID: ${Node_ID}
				数据库地址: ${MYSQL_HOST}
				数据库端口: ${MYSQL_PORT}
				数据库用户: ${MYSQL_USER}
				数据库密码: ${MYSQL_PASS}
				数据库名: ${MYSQL_DB}
			#################################
			"
			read -p "请确认[Y/N](默认为Y): " isPara
			case $isPara in
				N|n )
					echo "请重新配置。"
					Setting_node_information $interface_kind
					;;
				* )
					echo "参数确认。"
					;;
			esac
			;;
		*	)
			API_INTERFACE="modwebapi"
			read -p "(1/3)前端地址: " Front_end_address
				if [[ ${Front_end_address} = '' ]];then
					Front_end_address=`curl -s "https://myip.ipip.net" | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"`
					echo "已将前端地址设置为: http://${Front_end_address}"
				fi
			read -p "(2/3)节点ID: " Node_ID
			read -p "(3/3)Mukey: " Mukey
			if [[ ${Mukey} = '' ]];then
				Mukey='mupass';echo "未设置该项,默认Mukey值为: mupass"
			fi
			if [[ ${Node_ID} = '' ]]; then
				Node_ID=2
			fi
			echo "好了，以下是您的配置: "
			echo "
			#################################
				前端地址: ${Front_end_address}
				节点ID: ${Node_ID}
				Mukey: ${Mukey}
			#################################
			"
			read -p "请确认[Y/N](默认为Y): " isPara
			case $isPara in
				N|n )
					echo "请重新配置。"
					Setting_node_information $interface_kind
					;;
				* )
					echo "参数确认。"
					;;
			esac
			;;
	esac

	echo;echo "Great！即将开始安装...";echo;sleep 2.5
}

install_node_for_centos(){
	#yum -y update
	yum -y groupinstall "Development Tools"
	yum -y install git gcc wget curl python-setuptools
	wget "http://ssr-1252089354.coshk.myqcloud.com/get-pip.py"
	python get-pip.py;rm -rf python get-pip.py;mkdir python;cd python
	wget "http://ssr-1252089354.coshk.myqcloud.com/python.zip";unzip python.zip
	pip install *.whl;pip install *.tar.gz;cd /root;rm -rf python
	pip install cymysql requests -i https://pypi.org/simple/

	cd /root;wget "http://ssr-1252089354.coshk.myqcloud.com/libsodium-1.0.15.tar.gz"
	tar xf /root/libsodium-1.0.15.tar.gz;cd /root/libsodium-1.0.15;./configure;make -j2;make install;cd /root
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf;ldconfig

	wget -O /usr/bin/shadowsocks "https://raw.githubusercontent.com/qinghuas/ss-panel-and-ss-py-mu/master/node/ss";chmod 777 /usr/bin/shadowsocks
	yum -y install lsof lrzsz python-devel libffi-devel openssl-devel
	git clone -b manyuser https://github.com/glzjin/shadowsocks.git "/root/shadowsocks"
	cd /root/shadowsocks;cp apiconfig.py userapiconfig.py;cp config.json user-config.json

	sed -i "17c WEBAPI_URL = \'${Front_end_address}\'" /root/shadowsocks/userapiconfig.py
	sed -i "2c NODE_ID = ${Node_ID}" /root/shadowsocks/userapiconfig.py
	sed -i "18c WEBAPI_TOKEN = \'${Mukey}\'" /root/shadowsocks/userapiconfig.py

	sed -i "15c API_INTERFACE = \'${API_INTERFACE}\'" /root/shadowsocks/userapiconfig.py
	sed -i "24c MYSQL_HOST = \'${MYSQL_HOST}\'" /root/shadowsocks/userapiconfig.py
	sed -i "25c MYSQL_PORT = ${MYSQL_PORT}" /root/shadowsocks/userapiconfig.py
	sed -i "26c MYSQL_USER = \'${MYSQL_USER}\'" /root/shadowsocks/userapiconfig.py
	sed -i "27c MYSQL_PASS = \'${MYSQL_PASS}\'" /root/shadowsocks/userapiconfig.py
	sed -i "28c MYSQL_DB = \'${MYSQL_DB}\'" /root/shadowsocks/userapiconfig.py
}

Select_interface_kind
install_node_for_centos
Shut_down_iptables
Shut_down_firewall

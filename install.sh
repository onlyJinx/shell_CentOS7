#!/bin/bash
##CDN 104.16.160.3|104.16.192.155|104.20.157.6
##ss -lnp|grep :$port|awk -F "pid=" '{print $2}'|sed s/,.*//xargs kill -9
function check(){
	###状态码赋值给s
	#return_code=$?
	###调用函数
	###函数名 参数1 参数2
	if [ "0" != "$?" ]; then
		echo "$1编译失败，请手动检查"
		exit 0
	fi
}

function check_port(){

	while [[ true ]]; do

		read -p "请输入监听端口(默认$1):" port
		port=${port:-$1}
		myport=$(ss -lnp|grep :$port)
		if [ -n "$myport" ];then
			echo "端口$port已被占用,输入 y 关闭占用进程,输入 n 退出程序直接回车更换其他端口"
			read sel
			if [ "$sel" == "y" ] || [ "$sel" == "Y" ]; then
				##关闭进程
				ss -lnp|grep :$port|awk -F "pid=" '{print $2}'|sed 's/,.*//'|xargs kill -9
				if ! [ -n "$(ss -lnp|grep :$port)" ]; then
					echo "已终止占用端口进程"
					break
				else
					echo "进程关闭失败,请手动关闭"
					exit 1
				fi
			elif [ "$sel" == "n" ] || [ "$sel" == "N" ]; then
				echo "已取消操作"
				exit 0
			else
				clear
			fi
		else
			break
		fi
	done

}

function check_version(){
	if [ -x "$(command -v $1)" ]; then
		echo "$2已安装，是否继续覆盖安装？(Y/N)"
		read -t 30 -p "" sel
		if [ "$sel" == "y" ] || [ "$sel" == "Y" ];then
			echo "继续执行安装"
		else
			echo "已取消安装"
			exit 0
		fi
	fi
}

function check_fin(){
	if [ -x "$(command -v $1)" ]; then
		echo "编译安装完成"
	else
		echo "编译失败，请手动检查！！"
		exit 1
	fi
}

function download_dir(){

	#函数 提示语 默认路劲
	read -p "$1" dir
	dir=${dir:-$2}
	 if [ ! -d $dir ]; then
	 	echo "文件夹不存在，已创建文件夹 $dir"
	 	mkdir $dir
	 fi
}

function check_directory_exist(){
	##a_dir=$1
	if [[ -d $1 ]]; then
		echo 文件夹 $1 存在，是否删除\(y/n\)?
		read sel
		if [ "$sel" == "y" ] || [ "$sel" == "Y" ]; then
			rm -fr $1
			if [[ "$?"=="0" ]]; then
				echo 文件夹 $1 已删除
			else
				echo 文件夹 $1 删除失败，请手动删除！
				exit 0
			fi
		else
			mv $1 $1_$(date +%T)
			echo 已将目录 $1 移动至 $1_$(date +%T)
		fi
	fi
}

function shadowsocks-libev(){

	check_directory_exist /root/shadowsocks-libev
	check_version ss-server shadowsocks
	read -t 60 -p "请输入密码，直接回车则设置为默认密码: nPB4bF5K8+apre." passwd
	passwd=${passwd:-nPB4bF5K8+apre.}

	check_port 443

	###echo "passwd=$passwd"
	###搬瓦工默认禁用epel
	#yum remove epel-release -y
	#yum install epel-release -y

	###yum install gcc gettext autoconf libtool automake make pcre-devel asciidoc xmlto c-ares-devel libev-devel libsodium-devel mbedtls-devel -y
	yum install gcc gettext autoconf libtool automake make pcre-devel wget git vim asciidoc xmlto libev-devel -y
	###手动编译libsodium-devel mbedtls-devel c-ares


	###Installation of MbedTLS
	wget --no-check-certificate https://tls.mbed.org/download/mbedtls-2.16.3-gpl.tgz
	###wget https://tls.mbed.org/download/mbedtls-2.16.2-apache.tgz
	tar xvf mbedtls*gpl.tgz
	cd mbedtls*
	make SHARED=1 CFLAGS=-fPIC
	sudo make DESTDIR=/usr install
	check "shadowsocks依赖MbedTLS"
	cd ~
	sudo ldconfig

	###Installation of Libsodium
	## wget https://download.libsodium.org/libsodium/releases/libsodium-1.0.18.tar.gz
	## wget https://download.libsodium.org/libsodium/releases/LATEST.tar.gz
	## tar xvf LATEST.tar.gz
	## cd libsodium-stable
	## ./configure --prefix=/usr && make
	## sudo make install
	## check "shadowsocks依赖Libsodium"
	## sudo ldconfig
	## cd ~

	wget https://download.libsodium.org/libsodium/releases/LATEST.tar.gz
	cd LATEST
	./configure --prefix=/usr
	make && make install
	check "shadowsocks依赖Libsodium"
	sudo ldconfig
	cd ~


	###Installation of c-ares
	git clone https://github.com/c-ares/c-ares.git
	cd c-ares
	./buildconf
	autoconf configure.ac
	./configure --prefix=/usr && make
	sudo make install
	check "shadowsocks依赖c-ares"
	sudo ldconfig
	cd ~
	###安装方法引用http://blog.sina.com.cn/s/blog_6c4a60110101342m.html

	###Installation of simple-obfs

	###obfs已弃用###
	#git clone https://github.com/shadowsocks/simple-obfs.git
	#cd simple-obfs
	#git submodule update --init --recursive
	#./autogen.sh
	#./configure && make
	#sudo make install


	#wget https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.1.0/v2ray-plugin-linux-amd64-v1.1.0.tar.gz
	#tar zxvf v2ray-plugin* && mv v2ray-plugin-linux-amd64 /etc/shadowsocks-libev/v2ray-plugin &&rm -f v2ray-plugin*

	###报错 undefined reference to `ares_set_servers_ports_csv'，指定libsodium configure路径
	###Installation of shadowsocks-libev
	git clone https://github.com/shadowsocks/shadowsocks-libev.git
	cd shadowsocks-libev
	git submodule update --init --recursive
	./autogen.sh && ./configure --with-sodium-include=/usr/include --with-sodium-lib=/usr/lib
	##检查编译返回的状态码
	check "ShadowSocks-libev"
	make && make install

	###尝试运行程序
	check_fin "ss-server"
	mkdir /etc/shadowsocks-libev
	###cp /root/shadowsocks-libev/debian/config.json /etc/shadowsocks-libev/config.json

	###crate config.json
	###"plugin_opts":"obfs=tls;failover=127.0.0.1:888"
	cat >/etc/shadowsocks-libev/config.json<<-EOF
	{
	    "server":"0.0.0.0",
	    "server_port":$port,
	    "local_port":1080,
	    "password":"$passwd",
	    "timeout":60,
	    "method":"xchacha20-ietf-poly1305",
	    "fast_open": true,
	    "nameserver": "8.8.8.8",
	    "plugin":"/etc/shadowsocks-libev/v2ray-plugin",
	    "plugin_opts":"server",
	    "mode": "tcp_and_udp"
	}
	EOF


	###下载V2ray插件
	wget https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.0/v2ray-plugin-linux-amd64-v1.3.0.tar.gz
	tar zxvf v2ray-plugin* && mv v2ray-plugin_linux_amd64 /etc/shadowsocks-libev/v2ray-plugin &&rm -f v2ray-plugin*


	###crate service
	cat >/etc/systemd/system/ssl.service<<-EOF
	[Unit]
	Description=Shadowsocks Server
	After=network.target
	[Service]
	ExecStart=/usr/local/bin/ss-server -c /etc/shadowsocks-libev/config.json
	User=root
	[Install]
	WantedBy=multi-user.target
	EOF

	###禁用ping###
	###echo net.ipv4.icmp_echo_ignore_all=1>>/etc/sysctl.conf
	###sysctl -p


	###firewall oprt

	##firewall-cmd --zone=public --add-port=$port/tcp --permanent
	##firewall-cmd --zone=public --add-port=$port/udp --permanent

	##firewall-cmd --reload 


	systemctl start ssl&&systemctl enable ssl
	### remove the file
	cd /root && rm -fr mbedtls* shadowsocks-libev libsodium LATEST.tar.gz c-ares

	clear
	###ss -lnp|grep 443
	echo -e port:"          ""\e[31m\e[1m$port\e[0m"
	echo -e password:"      ""\e[31m\e[1m$passwd\e[0m"
	echo -e method:"        ""\e[31m\e[1mxchacha20-ietf-poly1305\e[0m"
	echo -e plugin:"        ""\e[31m\e[1mv2ray-plugin\e[0m"
	echo -e plugin_opts:"   ""\e[31m\e[1mhttp\e[0m"
	echo -e config.json:"   ""\e[31m\e[1m/etc/shadowsocks-libev/config.json\n\n\e[0m"
	echo -e use \""\e[31m\e[1msystemctl status ssl\e[0m"\" run the shadowsocks-libev in background
	echo -e "\e[31m\e[1mhttps://github.com/shadowsocks\e[0m"
}

function transmission(){

	check_directory_exist transmission-3.00+
	check_version transmission-daemon transmission
	clear
	check_port 9091
	clear
	read -p "请输入用户名，直接回车则设置为默认用户 transmission:  " uname
	uname=${uname:-transmission}
	clear
	read -p "请输入密码，直接回车则设置为默认密码 transmission2020:  " passwd
	passwd=${passwd:-transmission2020}
	clear
	download_dir "输入下载文件保存路径(默认/usr/downloads): " "/usr/downloads"
	check
	config_path="/root/.config/transmission-daemon/settings.json"

	if [[ "$(type -P apt)" ]]; then
		echo "Debian"
		apt-get -y --no-install-recommends install ca-certificates libcurl4-openssl-dev libssl-dev pkg-config build-essential autoconf libtool zlib1g-dev intltool libevent-dev wget git
	elif [[ "$(type -P yum)" ]]; then
		yum -y install gcc gcc-c++ make automake libtool gettext openssl-devel libevent-devel intltool libiconv curl-devel systemd-devel wget git
	else
		echo "error: The script does not support the package manager in this operating system."
		exit 1
	fi
	
	wget https://github.com/transmission/transmission-releases/raw/master/transmission-3.00.tar.xz
	tar xf transmission-3.00.tar.xz && cd transmission-3.00

	./autogen.sh && make && make install
	###检查返回状态码
	check transmission
	###尝试运行程序
	#check_fin "transmission-daemon"
	##默认配置文件
	##vi /root/.config/transmission-daemon/settings.json

	##crate service
	cat >/etc/systemd/system/transmission-daemon.service<<-EOF
	[Unit]
	Description=Transmission BitTorrent Daemon
	After=network.target

	[Service]
	User=root
	Type=simple
	ExecStart=/usr/local/bin/transmission-daemon -f --log-error
	ExecStop=/bin/kill -s STOP $MAINPID
	ExecReload=/bin/kill -s HUP $MAINPID

	[Install]
	WantedBy=multi-user.target
	EOF

	##首次启动，生成配置文件
	systemctl start transmission-daemon.service
	systemctl stop transmission-daemon.service

	##systemctl status transmission-daemon.service

	## change config  sed引用 https://segmentfault.com/a/1190000020613397
	
	sed -i '/rpc-whitelist-enabled/ s/true/false/' $config_path
	sed -i '/rpc-host-whitelist-enabled/ s/true/false/' $config_path
	sed -i '/rpc-authentication-required/ s/false/true/' $config_path
	##取消未完成文件自动添加 .part后缀
	sed -i '/rename-partial-files/ s/true/false/' $config_path
	##单引号里特殊符号都不起作用$ or /\，使用双引号替代单引号
	##sed -i "/rpc-username/ s/\"\"/\"$uname\"/" $config_path
	sed -i "/rpc-username/ s/: \".*/: \"$uname\",/" $config_path
	sed -i "/rpc-port/ s/9091/$port/" $config_path
	##sed分隔符/和路径分隔符混淆，用:代替/
	sed -i ":download-dir: s:\/root\/Downloads:$dir:" $config_path
	sed -i "/rpc-password/ s/\"{.*/\"$passwd\",/" $config_path
	##开启限速
	sed -i "/speed-limit-up-enabled/ s/false/true/" $config_path
	##限速1M/s
	sed -i "/\"speed-limit-up\"/ s/:.*/: 1024,/" $config_path
	##limit rate
	sed -i "/ratio-limit-enabled/ s/false/true/" $config_path
	sed -i "/\"ratio-limit\"/ s/:.*/: 4,/" $config_path

	##firewall-cmd --zone=public --add-port=51413/tcp --permanent
	##firewall-cmd --zone=public --add-port=51413/udp --permanent
	##firewall-cmd --zone=public --add-port=$port/tcp --permanent
	##firewall-cmd --zone=public --add-port=$port/udp --permanent
	##firewall-cmd --reload

	##替换webUI
	cd ~
	git clone https://github.com/ronggang/transmission-web-control.git
	mv /usr/local/share/transmission/web/index.html /usr/local/share/transmission/web/index.original.html
	cp -r /root/transmission-web-control/src/* /usr/local/share/transmission/web/

	systemctl start transmission-daemon.service
	systemctl enable transmission-daemon.service

	clear

	echo -e port:"          ""\e[31m\e[1m$port\e[0m"
	echo -e password:"      ""\e[31m\e[1m$passwd\e[0m"
	echo -e username:"      ""\e[31m\e[1m$uname\e[0m"
	echo -e download_dir:"      ""\e[31m\e[1m$dir\e[0m"
	echo -e config.json:"   ""\e[31m\e[1m/root/.config/transmission-daemon/settings.json\n\n\e[0m"
}


function aria2(){

	check_directory_exist aria2
	check_version aria2c aria2
	clear
	download_dir "输入下载文件保存路径(默认/usr/downloads): " "/usr/downloads"
	clear
	read -p "输入密码(默认密码crazy_0)： " key
	key=${key:-crazy_0}

	yum install -y gcc-c++ make libtool automake bison autoconf git intltool libssh2-devel expat-devel gmp-devel nettle-devel libssh2-devel zlib-devel c-ares-devel gnutls-devel libgcrypt-devel libxml2-devel sqlite-devel gettext xz-devel gperftools gperftools-devel gperftools-libs trousers-devel

	git clone https://github.com/aria2/aria2.git && cd aria2

	##静态编译
	##autoreconf -i && ./configure ARIA2_STATIC=yes
	
	autoreconf -i && ./configure
	make && make install

	###相关编译报错引用https://weair.xyz/build-aria2/
	check aria2
	###尝试运行程序
	clear
	check_fin "aria2c"
	cat >/etc/systemd/system/aria2.service<<-EOF
	[Unit]
	Description=aria2c
	After=network.target
	[Service]
	ExecStart=/usr/local/bin/aria2c --conf-path=/aria2.conf
	User=root
	[Install]
	WantedBy=multi-user.target
	EOF


	##aria2 config file

	cat >/aria2.conf<<-EOF
	    rpc-secret=$key
	    enable-rpc=true
	    rpc-allow-origin-all=true
	    rpc-listen-all=true
	    max-concurrent-downloads=5
	    continue=true
	    max-connection-per-server=5
	    min-split-size=10M
	    split=16
	    max-overall-download-limit=0
	    max-download-limit=0
	    max-overall-upload-limit=0
	    max-upload-limit=0
	    dir=$dir
	    file-allocation=prealloc
	EOF

	##安装nginx
	#SElinux原因不再用nginx，用httpd替代
	#rpm -ivh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
	#yum install nginx -y
	##selinux 设置
	#ausearch -c 'nginx' --raw | audit2allow -M my-nginx
	#semodule -i my-nginx.pp


	systemctl enable aria2
	systemctl start aria2

	##firewall-cmd --zone=public --add-port=6800/tcp --permanent
	##firewall-cmd --zone=public --add-port=6800/udp --permanent
	##firewall-cmd --reload 
	clear

	while [[ true ]]; do
		echo "是否安装webUI (y/n)?"
		read ins
		if [ "$ins" == "y" ] || [ "$ins" == "Y" ];then
			httpd
			clear
			echo -e port:"          ""\e[31m\e[1m$port\e[0m"
			break
		elif [ "$ins" == "n" ] || [ "$ins" == "N" ];then
			clear
			break
		fi
	done

	echo -e token:"      ""\e[31m\e[1m$key\e[0m"
	echo -e download_dir:"      ""\e[31m\e[1m$dir\e[0m"
	echo -e config.json:"   ""\e[31m\e[1m/aria2.conf\n\n\e[0m"

}

function httpd(){

	##if判断参考https://www.cnblogs.com/include/archive/2011/12/09/2307905.html
	count=0
	while(1>0)
	do
	read -p "输入一个大于1024的端口(第$count次)  " port
	let count++
	port=${port:-80}
	if [ "$port" -gt "1024" ];then
		if [ -n "$(ss -lnp|grep :$port)" ];then
			clear
			echo "端口$port已被占用，请输入其他端口"
		else
			break
		fi

	elif [ "$port" -eq "80" ] || [ "$port" -eq "443" ];then
		if [ -n "$(ss -lnp|grep :$port)" ];then
			clear
			echo "端口$port已被占用，请输入其他端口"
		else
			break
		fi
	fi

	if [ $count -gt 10 ]; then
		clear
		echo "滚"
		break
	fi
	done

	yum install httpd -y
	sed -i "/^Listen/ s/[0-9].*/$po
	rt/" /etc/httpd/conf/httpd.conf
	##firewall-cmd --zone=public --add-port=$port/tcp --permanent
	##firewall-cmd --zone=public --add-port=$port/udp --permanent
	##firewall-cmd --reload
	clear

	##webui
	cd ~
	git clone https://github.com/ziahamza/webui-aria2.git
	#rm -fr /usr/share/nginx/html/*
	mv /var/www/html /var/www/html_b
	mkdir /var/www/html/
	cp -r /root/webui-aria2/docs/* /var/www/html/
	##config file
	##vi /etc/nginx/conf.d/default.conf
	#sed -i "/listen/ s/80/$port/" /etc/nginx/conf.d/default.conf

	systemctl enable httpd
	systemctl start httpd

}

function Up_kernel(){
	if [[ "$(type -P apt)" ]]; then
		echo "deb https://deb.debian.org/debian buster-backports main" >> /etc/apt/sources.list
		apt update
		apt install -t buster-backports linux-image-cloud-amd64 linux-headers-cloud-amd64
	elif [[ "$(type -P yum)" ]]; then
		###导入elrepo密钥
		rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org

		###安装elrepo仓库
		rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm

		###安装内核
		yum --enablerepo=elrepo-kernel install kernel-ml -y

		###修改默认内核
		sed -i 's/saved/0/g' /etc/default/grub

		###重新创建内核配置
		grub2-mkconfig -o /boot/grub2/grub.cfg

		# Oracel内核
		# grub2-set-default 0
		# TCP-BBR
		#net.core.default_qdisc=fq
		#net.ipv4.tcp_congestion_control=bbr

		###查看tcp_bbr内核模块是否启动
		#lsmod | grep bbr

		#Please reboot your VPS after run command "yum update -y"

		#ping 127.0.0.1 -c 5 >>null
		#reboot

		###引用：http://www.jianshu.com/p/726bd9f37220
		###引用：https://legolasng.github.io/2017/05/08/upgrade-centos-kernel/#3安装新版本内核
	else
		echo "error: The script does not support the package manager in this operating system."
		exit 1
	fi

	###使修改的内核配置生效
	echo net.core.default_qdisc=fq >> /etc/sysctl.conf
	echo net.ipv4.tcp_congestion_control=bbr >> /etc/sysctl.conf
	sysctl -p

}

function trojan(){
	clear
	echo "######强烈建议使用443及80端口######"
	echo "#不会自动申请证书，请先准备好ssl证书#"
	echo "######并放到 /tmp/trojan 目录######"
	echo "########按任意键开始端口检测########"
	read
	clear
	echo "直接回车检测https(443)监听端口"
	check_port 443
	echo "直接回车检测http(80)监听端口"
	check_port 80
	clear

	while [[ true ]]; do
		read -p "请输入域名:" domain
		if [[ -n $domain ]]; then
			break;
		fi
	done

	###检测证书文件
	clear
	echo "########端口检测本地证书########"
	if [ ! -d "/tmp/trojan" ];then
		mkdir /tmp/trojan
	fi
	count=$(ls -l /tmp/trojan | grep "^-" | wc -l ) 
	if [ $count -gt 2 ];then
	        echo "这个/tmp/trojan目录怎么有$count个文件？证书加Key才两个文件而已,自己清空该目录所有文件再放入key和证书!!!"
	        exit 0
	elif  ! [ -f /tmp/trojan/*key ]; then
		#cp /tmp/trojan/*key /etc/trojan/private.key
		echo "请将密钥key放入 /tmp/trojan 文件夹后再执行该脚本"
		exit 0
	elif [ -f /tmp/trojan/*pem ]; then
		#cp /tmp/trojan/*pem /etc/trojan/certificate.pem
		cert=pem
		echo "已检测到pem证书文件"
	elif [ -f /tmp/trojan/*crt ]; then
		#cp /tmp/trojan/*crt /etc/trojan/certificate.crt
		cert=crt
		echo "已检测到crt证书文件"
	else
		echo "请将证书文件(crt/pem)放入/tmp/trojan 文件夹后再执行该脚本"
		exit 0
	fi

	read -p "设置一个trojan密码(默认trojanWdai1)： " PW
	PW=${PW:-trojanWdai1}
	read -p "请输入trojan版本号(默认1.15.1),可以到这里查https://github.com/trojan-gfw/trojan/releases： " trojan_version
	trojan_version=${trojan_version:-1.15.1}
	nginx_version=1.21.1
	nginx_url=http://nginx.org/download/nginx-${nginx_version}.tar.gz
	yum -y install gcc gcc-c++ pcre pcre-devel zlib zlib-devel openssl openssl-devel wget
	wget $nginx_url && tar zxf nginx-${nginx_version}.tar.gz && cd nginx-$nginx_version

	./configure \
	--prefix=/usr/local/nginx \
	--with-http_ssl_module \
	--with-http_stub_status_module \
	--with-http_realip_module \
	--with-threads \
	--with-stream_ssl_module \
	--with-http_v2_module \
	--with-stream_ssl_preread_module \
	--with-stream=dynamic
	check
	make && make install
	check
	ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx

	mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf_backup

	##nginx配置文件修改
	##wget -P /usr/local/nginx/conf https://raw.githubusercontent.com/onlyJinx/shell_CentOS7/master/nginx.conf
	cat >/usr/local/nginx/conf/nginx.conf<<-EOF
		load_module /usr/local/nginx/modules/ngx_stream_module.so;
		worker_processes  1;
		events {
		    worker_connections  1024;
		}
		stream {
		    map \$ssl_preread_server_name \$name {
		        $domain 127.0.0.1:555;    #forward to trojan
		        #aria2.domain.com 127.0.0.1:6801;    #forward to aria2_rpc
		        default 127.0.0.1:4433;             #block all
		    }
		    server {
		        listen 443 reuseport;
		        listen [::]:443 reuseport;
		        proxy_pass \$name;
		        ssl_preread on;                     #开启 ssl_preread
		    }
		}

		http {
		    include       mime.types;
		    default_type  application/octet-stream;
		    sendfile        on;
		    keepalive_timeout  65;

		    ###全站https
		    server {
		        listen 0.0.0.0:80;
		        listen [::]:80;
		        server_name _;
		        return 301 https://\$host\$request_uri;
		    }

		    server {
		        listen       4433 default ssl;
		        server_name  _;
		        return 403;  #block all
		        ssl_certificate      /etc/trojan/certificate.pem;
		        ssl_certificate_key  /etc/trojan/private.key;

		        ssl_session_cache    shared:SSL:1m;
		        ssl_session_timeout  5m;

		        ssl_ciphers  HIGH:!aNULL:!MD5;
		        ssl_prefer_server_ciphers  on;

		        location / {
		            root   html;
		            index  index.html index.htm;
		        }
		    }


		    server {
		    listen       127.0.0.1:6801 ssl;
		    server_name  _;
		        ssl_certificate      /etc/trojan/certificate.pem;
		        ssl_certificate_key  /etc/trojan/private.key;
		        location / {
		            proxy_pass                  http://127.0.0.1:6800;
		        }
		    }

		    ##Trojan伪装站点
		    server {
		        listen       127.0.0.1:5555 http2; 
		        server_name  _;
		        charset utf-8;
		        absolute_redirect off;
		        #ssl_certificate      /etc/trojan/certificate.pem;
		        #ssl_certificate_key  /etc/trojan/private.key;
		        location / {
		            #index index.html;
		        }
		    }

		}
	EOF
	###crate service
	#单双引号不转义，反单引号 $ 要转
	wget -P /etc/init.d https://raw.githubusercontent.com/onlyJinx/shell_CentOS7/master/nginx

	chmod a+x /etc/init.d/nginx
	chkconfig --add /etc/init.d/nginx
	chkconfig nginx on

	###nginx编译引用自博客
	###https://www.cnblogs.com/stulzq/p/9291223.html
	wget https://github.com/trojan-gfw/trojan/releases/download/v${trojan_version}/trojan-${trojan_version}-linux-amd64.tar.xz && tar xvJf trojan-${trojan_version}-linux-amd64.tar.xz -C /etc
	ln -s /etc/trojan/trojan /usr/bin/trojan
	config_path=/etc/trojan/config.json
	sed -i '/password2/ d' $config_path
	sed -i "/certificate.crt/ s/.crt/.$cert/" $config_path
	sed -i "/local_port/ s/443/555/" $config_path
	sed -i "/remote_port/ s/80/5100/" $config_path
	sed -i "/h2\":/ s/81/5555/" $config_path
	sed -i ":http/1.1: s:http/1.1:h2:" $config_path
	sed -i "/\"password1\",/ s/\"password1\",/\"$PW\"/" $config_path
	sed -i ":\"cert\": s:path\/to:etc\/trojan:" $config_path
	sed -i ":\"key\": s:path\/to:etc\/trojan:" $config_path


	##复制证书文件
	cp /tmp/trojan/*key /etc/trojan/private.key
	if [[ "$cert" == "crt" ]]; then
		cp /tmp/trojan/*crt /etc/trojan/certificate.crt
	else
		cp /tmp/trojan/*pem /etc/trojan/certificate.pem
	fi

	###crate service
	cat >/etc/systemd/system/trojan.service<<-EOF
	[Unit]
	Description=trojan Server
	After=network.target
	[Service]
	ExecStart=/etc/trojan/trojan -c /etc/trojan/config.json
	User=root
	[Install]
	WantedBy=multi-user.target
	EOF

	##firewall-cmd --zone=public --add-port=443/tcp --permanent
	##firewall-cmd --zone=public --add-port=443/udp --permanent
	##firewall-cmd --zone=public --add-port=80/tcp --permanent
	##firewall-cmd --zone=public --add-port=80/udp --permanent
	##firewall-cmd --reload

	systemctl start trojan
	systemctl enable trojan

	systemctl start nginx
	systemctl status nginx
	systemctl enable nginx

}

select option in "shadowsocks-libev" "transmission" "aria2" "Up_kernel" "trojan+nginx"
do
	case $option in
		"shadowsocks-libev")
			shadowsocks-libev
			break;;
		"transmission")
			transmission
			break;;
# 		"samba")
# 			samba
# 			break;;
		"aria2")
			aria2
			break;;
		"Up_kernel")
			Up_kernel
			break;;
# 		"ngrok")
# 			ngrok
# 			break;;
# 		"filemanager")
# 			filemanager
# 			break;;
		"trojan+nginx")
			trojan
			break;;
		*)
			echo "nothink to do"
			break;;
	esac
done

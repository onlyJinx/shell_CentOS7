yum install -y gcc-c++ bison libssh2-devel expat-devel gmp-devel nettle-devel libssh2-devel zlib-devel c-ares-devel gnutls-devel libgcrypt-devel libxml2-devel sqlite-devel gettext lzma-devel xz-devel gperftools gperftools-devel gperftools-libs jemalloc-devel trousers-devel

git clone https://github.com/aria2/aria2.git && cd aria2

##静态编译
autoreconf -i && ./configure ARIA2_STATIC=yes
make && make install

cat >/etc/systemd/system/aria2.service<< EOF
[Unit]
Description=aria2c
After=network.target
[Service]
ExecStart=/usr/local/bin/aria2c --conf-path=/aria2.conf
User=root
[Install]
WantedBy=multi-user.target
EOF

##安装nginx

rpm -ivh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
yum install nginx
firewall-cmd --zone=public --add-port=80/tcp --permanent

##webui
git clone https://github.com/ziahamza/webui-aria2.git /root
rm -fr /usr/share/nginx/html/*
cp /root/webui-aria2/docs/* /usr/share/nginx/html/

systemctl enable nginx
systemctl start nginx

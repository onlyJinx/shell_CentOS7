yum install -y gcc-c++ bison libssh2-devel expat-devel gmp-devel nettle-devel libssh2-devel zlib-devel c-ares-devel gnutls-devel libgcrypt-devel libxml2-devel sqlite-devel gettext lzma-devel xz-devel gperftools gperftools-devel gperftools-libs jemalloc-devel
wget https://github.com/aria2/aria2/releases/download/release-1.33.1/aria2-1.33.1.tar.gz
tar zxvf aria2*
cd aria2*
./configure
make&make install
##aria2c --conf-path=/aria2.conf

# This script will setup tools used by XiangShan
# tested on ubuntu 20.04 Docker image

apt update
apt install proxychains4 shadowsocks-libev vim wget git tmux make gcc time curl libreadline6-dev libsdl2-dev openjdk-11-jre zlib1g-dev device-tree-compiler flex autoconf bison sqlite3 libsqlite3-dev

# We need to use Verilator 4.204+, so we install Verilator manually
sudo apt-get install git perl python3 make autoconf g++ flex bison clang
sudo apt-get install libgoogle-perftools-dev numactl perl-doc
sudo apt-get install libfl2  # Ubuntu only (ignore if gives error)
sudo apt-get install libfl-dev  # Ubuntu only (ignore if gives error)
sudo apt-get install zlibc zlib1g zlib1g-dev  # Ubuntu only (ignore if gives error)

git clone git@github.com:verilator/verilator.git

# Every time you need to build:
unset VERILATOR_ROOT  # For bash
cd verilator

# XiangShan uses Verilator v4.218
git checkout v4.218

autoconf        # Create ./configure script
# Configure and create Makefile
./configure CC=clang CXX=clang++ # We use clang as default compiler
make -j8        # Build Verilator itself
sudo make install

verilator --version
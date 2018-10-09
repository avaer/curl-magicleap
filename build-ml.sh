#!/bin/bash

# Download and build libcurl, openssl and zlib for Android using Crystax NDK r7
# Must be run on 32 bit Linux as the Crystax r7 NDK doesn't support 64 bit hosts
# Tested on Ubuntu 14.04

# Make the working directory
ROOT_DIR=$(pwd)
OUTPUT_DIR=$ROOT_DIR/output
mkdir $OUTPUT_DIR

# NDK environment variables
export MLSDK=${MLSDK:-/mnt/c/Users/avaer/MagicLeap/mlsdk/v0.16.0}
export PATH=$PATH:$MLSDK/tools/toolchains/bin/

# Setup cross-compile environment
export SYSROOT=$MLSDK/lumin
# export ARCH=armv7
export CC=aarch64-linux-android-gcc
export CXX=aarch64-linux-android-g++
export AR=aarch64-linux-android-ar
export AS=aarch64-linux-android-as
export LD=aarch64-linux-android-ld
export RANLIB=aarch64-linux-android-ranlib
export NM=aarch64-linux-android-nm
export STRIP=aarch64-linux-android-strip
export CHOST=aarch64-linux-android

OUTPUT_DIR=$ROOT_DIR/libcurl-android
mkdir $OUTPUT_DIR

# Download and build zlib
mkdir -p $OUTPUT_DIR/zlib/lib/armeabi-v7a
mkdir $OUTPUT_DIR/zlib/include
ZLIB_DIR=$ROOT_DIR/zlib-1.2.11
wget https://zlib.net/zlib-1.2.11.tar.gz
tar -xvzf zlib-1.2.11.tar.gz
cd $ZLIB_DIR
./configure --static
make

# Copy zlib lib and includes to output directory
cp libz.a $OUTPUT_DIR/zlib/lib/armeabi-v7a/
cp zconf.h $OUTPUT_DIR/zlib/include/ 
cp zlib.h $OUTPUT_DIR/zlib/include/
cd ..

# Download and build openssl
wget https://www.openssl.org/source/old/1.0.2/openssl-1.0.2d.tar.gz
tar -xvf openssl-1.0.2d.tar.gz 
cd openssl-1.0.2d/
export CPPFLAGS="-DANDROID"
./Configure linux-aarch64 no-asm no-shared --static --with-zlib-include=${ZLIB_DIR}/include --with-zlib-lib=${ZLIB_DIR}/lib
pushd include
find -type l -exec bash -c 'ln -f "$(readlink -m "$0")" "$0"' {} \;
popd
make build_crypto build_ssl

# Copy openssl lib and includes to output directory
mkdir -p $OUTPUT_DIR/openssl/lib/armeabi-v7a
mkdir $OUTPUT_DIR/openssl/include
cp libssl.a $OUTPUT_DIR/openssl/lib/armeabi-v7a
cp libcrypto.a $OUTPUT_DIR/openssl/lib/armeabi-v7a
cp -LR include/openssl $OUTPUT_DIR/openssl/include
cd ..
OPENSSL_DIR=$ROOT_DIR/openssl-1.0.2d

# Download and build libcurl
wget http://curl.haxx.se/download/curl-7.45.0.tar.gz
tar -xvf curl-7.45.0.tar.gz 
cd curl-7.45.0
export CFLAGS="-v --sysroot=$SYSROOT -mandroid"
export CPPFLAGS="$CFLAGS -DCURL_STATICLIB -I${OPENSSL_DIR}/include/"
# export LDFLAGS="-march=$ARCH -Wl,--fix-cortex-a8 -L${OPENSSL_DIR}"
./configure --host=aarch64-linux-android --disable-shared --enable-static --disable-dependency-tracking --with-zlib=${ZLIB_DIR} --with-ssl=${OPENSSL_DIR} --without-ca-bundle --without-ca-path --enable-ipv6 --enable-http --enable-ftp --disable-file --disable-ldap --disable-ldaps --disable-rtsp --disable-proxy --disable-dict --disable-telnet --disable-tftp --disable-pop3 --disable-imap --disable-smtp --disable-gopher --disable-sspi --disable-manual --target=aarch64-linux-android --prefix=/opt/curlssl 
make

# Copy libcurl and includes to output directory
mkdir -p $OUTPUT_DIR/curl/lib/armeabi-v7a
mkdir $OUTPUT_DIR/curl/include
cp lib/.libs/libcurl.a $OUTPUT_DIR/curl/lib/armeabi-v7a
cp -LR include/curl $OUTPUT_DIR/curl/include
cd ..

# Tar up output
OUTPUT_FILE=libcurl-android.tar.gz
tar -czf $OUTPUT_FILE -C $OUTPUT_DIR .

echo Build result saved to $ROOT_DIR/$OUTPUT_FILE

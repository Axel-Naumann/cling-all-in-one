#!/bin/bash
#
# axel@cern.ch, 2014-02-07

p=$(./processors)

if [ ! -h python -a type -P python2 2>/dev/null ]
then
	ln -s `type -P python2` python
	export PATH=`pwd`:$PATH
fi

function update {
    cd src || exit 1
    echo '++ Updating llvm...'
    git pull || exit 1
    cd tools/clang || exit 1
    echo '++ Updating clang...'
    git pull || exit 1
    echo '++ Updating cling...'
    cd ../cling || exit 1
    git pull || exit 1
    echo 'Update done. Now run "cd obj; make -j$p; make install".'
}

function clone {
    # clone what branch where
    where=$3
    if [ "$where" = "" ]; then
        where=$1
    fi
    echo '>> Cloning '$1'...'
    git clone http://root.cern.ch/git/${1}.git $where > /dev/null || exit 1
    ( cd $where && git checkout $2 )
}

function initial {
    if [ -d inst ]; then
        echo '!! Directory inst/ exists; refusing to build / install!'
        exit 1
    fi

    clone llvm cling-patches src
    cd src/tools || exit 1
    clone clang cling-patches
    clone cling master
    cd ../..

    mkdir obj || exit 1
    INSTDIR=`pwd`/inst
    cd obj || exit 1
    echo '>> Configuring...'
    ../src/configure --enable-targets=host --prefix=$INSTDIR > /dev/null || exit 1
}

function build {
    echo ':: Building...'
    make -j$p || exit 1
    rm -rf ../inst
    echo ':: Installing...'
    make -j$p install || exit 1
    echo ':: SUCCESS.'
}

if [ -d src ]; then
    # update mode
    update
else
    initial
fi

build

echo 'Run ./inst/bin/cling'

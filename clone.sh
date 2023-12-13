#!/bin/bash
#
# axel@cern.ch, 2014-02-07
#
# arguments:
#   [cores]  number of cores to use, optional
#            default: all detected cores

# which is not ideal, see http://stackoverflow.com/a/677212/1392758
python=`which python`
if type python3 > /dev/null 2>&1; then
    python=`which python3`
fi

allcores=`$python <(cat <<EOF
import multiprocessing
print (multiprocessing.cpu_count())
EOF
)`
cores=${1:-${allcores}}
echo Using $cores cores.

function update {
    cd llvm-project || exit 1
    echo '++ Updating llvm...'
    git pull || exit 1
    echo '++ Updating cling...'
    cd ../cling || exit 1
    git pull || exit 1
    echo '++ Update done.'
    cd ..
}

function clone {
    # clone what branch where
    echo '>> Cloning '$1'...'
    git clone --depth=1 --branch $2 https://github.com/root-project/${1}.git > /dev/null || exit 1
}

function initial {
    if [ -d inst ]; then
        echo '!! Directory inst/ exists; refusing to build / install!'
        exit 1
    fi

    clone llvm-project cling-llvm16
    clone cling master
}

function configure {
    mkdir -p build || exit 1
    INSTDIR=`pwd`/inst
    cd build || exit 1
    echo '>> Configuring...'
    cmake -DCMAKE_INSTALL_PREFIX=$INSTDIR -DLLVM_EXTERNAL_PROJECTS=cling -DLLVM_EXTERNAL_CLING_SOURCE_DIR=../cling -DLLVM_ENABLE_PROJECTS="clang" -DLLVM_TARGETS_TO_BUILD="host;NVPTX" -DCMAKE_BUILD_TYPE=Release -DLLVM_BUILD_TOOLS=Off ../llvm-project/llvm/ > /dev/null || exit 1
    cd ..
}

function build {
    cd build
    echo ':: Building...'
    make -j$cores || exit 1
    rm -rf ../inst
    echo ':: Installing...'
    make -j$cores install || exit 1
    echo ':: SUCCESS.'
    cd ..
}

if [ -d cling ]; then
    # update mode
    update
else
    initial
fi

if ! [ -e build/Makefile ]; then
    configure
fi

build

echo 'Run ./inst/bin/cling'

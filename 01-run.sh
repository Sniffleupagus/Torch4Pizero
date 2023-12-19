#!/bin/bash -e

echo -n "Starting in: "
pwd

pushd ${ROOTFS_DIR}

pushd usr/local/src

if [ ! -d pytorch ]; then
    git clone --branch v2.1.2 https://github.com/pytorch/pytorch.git --recursive
fi

if [ ! -d vision ]; then
    git clone --branch v0.16.0 --depth=1 https://github.com/pytorch/vision
fi

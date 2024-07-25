#!/bin/bash

# This script will setup eula develop environment automatically

# Init submodules
git submodule update --init --recursive

# Setup nutshell environment variables
source env.sh
# OPTIONAL: export them to .bashrc

echo PROJECT_ROOT: ${PROJECT_ROOT}
echo NEMU_HOME: ${NEMU_HOME}
echo AM_HOME: ${AM_HOME}
echo NOOP_HOME: ${NOOP_HOME}
echo LA32RTC_HOME: ${LA32RTC_HOME}


cd ${NEMU_HOME}
make la32-reduced-ref_defconfig
make -j

cd ${AM_HOME}/apps/coremark
make ARCH=la32r-eula

cd ${PROJECT_ROOT}


#!/bin/bash

# This script is used to load the environment variables for the environment
# Custom for this Bootlin tutorial based on previous crosstool-ng configuration

# Add crosstool-ng built toolchain binaries to the PATH
export PATH=${HOME}/x-tools/arm-training-linux-musleabihf/bin/:${PATH}

# Load cross-compile prefix for our toolchain, based on our crosstool-ng configuration
export CROSS_COMPILE=arm-linux-

# Load target architecture for the kernel build
export ARCH=arm

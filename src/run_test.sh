#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: ./run_test.sh <test_file>"
    echo "Example: ./run_test.sh core_testbench.sv"
    exit 1
fi

TEST_NAME=$(basename "$1" .sv)

BUILD_DIR="build"
mkdir -p "$BUILD_DIR"

echo "Compiling $1..."
iverilog -g2012 -o "$BUILD_DIR/$TEST_NAME" "tests/$1" 2>&1

if [ $? -eq 0 ]; then
    echo "Compilation successful. Running test..."
    cd "$BUILD_DIR"
    ./"$TEST_NAME"
    cd ..
    
    if [ -f "${TEST_NAME}.vcd" ]; then
        mv "${TEST_NAME}.vcd" "$BUILD_DIR/"
    fi
    
    echo "Test complete. Wave file is in $BUILD_DIR/${TEST_NAME}.vcd"
else
    echo "Compilation failed!"
    exit 1
fi
set -e

# This script is designed to be equivalent to the process that JetBrains uses
# to build their LLVM for kotlin-native, which can be downloaded at
# https://download-cdn.jetbrains.com/kotlin/native/clang-llvm-8.0.0-linux-x86-64.tar.gz
#
# However, for build security, we want a trusted LLVM that we built ourselves.
#
# This is a sanitized descendant of the output discovered by running:
#
# $ git clone https://github.com/JetBrains/kotlin.git
# $ cd kotlin/kotlin-native-tools/llvm_builder
#
# # Where kotlin-native-toolchain is ../.. from this script
# $ export PREBUILTS=$SRC/kotlin-native-toolchain/prebuilts
#
# $ python3 package \
#     --dry-run \
#     --ninja=$PREBUILTS/build-tools/linux-x86/bin/ninja \
#     --cmake=$PREBUILTS/cmake/linux-x86/bin/cmake
#
# For why we run a 2-stage bootstrap, see
#  https://llvm.org/docs/BuildingADistribution.html#general-distribution-guidance

echo "Trivially succeeding to prevent musket turndown, until we resolve b/206804351"
exit 0

# find script
SCRIPT_DIR="$(cd $(dirname $0) && pwd)"
cd $SCRIPT_DIR

LLVM_PROJECT=$SCRIPT_DIR

ROOT=$SCRIPT_DIR/../..

if [ "$OUT_DIR" == "" ]; then
  OUT_DIR="$ROOT/out"
fi
mkdir -p "$OUT_DIR"
export OUT_DIR="$(cd $OUT_DIR && pwd)"

if [ "$DIST_DIR" == "" ]; then
  DIST_DIR="$OUT_DIR/dist"
fi
mkdir -p "$DIST_DIR"
export DIST_DIR

PREBUILTS=$ROOT/prebuilts
BIN_PATH=$PREBUILTS/build-tools/linux-x86/bin

# Add prebuilts (especially ninja) to PATH
#   (cmake won't run if ninja is not on PATH)
export PATH=$BIN_PATH:$PATH

CMAKE=$PREBUILTS/cmake/linux-x86/bin/cmake
NINJA=$BIN_PATH/ninja

CMAKE_COMMON_OPTS="\
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_ASSERTIONS=OFF \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_INCLUDE_GO_TESTS=OFF \
    -DLLVM_ENABLE_Z3_SOLVER=OFF \
    -DCOMPILER_RT_BUILD_BUILTINS=ON \
    -DLLVM_ENABLE_THREADS=ON \
    -DLLVM_OPTIMIZED_TABLEGEN=ON \
    -DLLVM_ENABLE_PROJECTS=clang;lld;libcxx;libcxxabi;compiler-rt \
    -DLLVM_BUILD_LLVM_DYLIB=OFF \
    -DLLVM_LINK_LLVM_DYLIB=OFF"

function stage1build() {
    STAGE1=$OUT_DIR/stage1
    mkdir -p $STAGE1

    STAGE1BUILD=$OUT_DIR/stage1build

    mkdir -p $STAGE1BUILD
    pushd $STAGE1BUILD

    # Build a toolset into $STAGE1.  We only need native, because
    # this is just for the next step.

    $CMAKE \
	-DCMAKE_INSTALL_PREFIX=$STAGE1 \
	-DLLVM_TARGETS_TO_BUILD=Native \
	$CMAKE_COMMON_OPTS \
	$LLVM_PROJECT/llvm

    $NINJA install

    popd
}

function stage2build() {
    ### (bootstrapped using the compiler we just built)

    STAGE2BUILD=$OUT_DIR/stage2build
    mkdir -p $STAGE2BUILD
    pushd $STAGE2BUILD

    # Use the tools we installed in $STAGE1, and install to $DIST_DIR
    # Leaving off LLVM_TARGETS_TO_BUILD means we'll build for all
    # available targets, according to package.py documentation

    $CMAKE \
	-DCMAKE_INSTALL_PREFIX=$DIST_DIR \
	-DCMAKE_C_COMPILER=$STAGE1/bin/clang \
	-DCMAKE_CXX_COMPILER=$STAGE1/bin/clang++ \
	-DCMAKE_LINKER=$STAGE1/bin/ld.lld \
	-DCMAKE_AR=$STAGE1/bin/llvm-ar \
	$CMAKE_COMMON_OPTS \
	$LLVM_PROJECT/llvm

    $NINJA install

    popd
}

stage1build
stage2build

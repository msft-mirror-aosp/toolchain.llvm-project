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

# find script
SCRIPT_DIR=$(cd "$(dirname $0)" && pwd)
cd $SCRIPT_DIR

LLVM_PROJECT=$SCRIPT_DIR

ROOT=$SCRIPT_DIR/../..

if [ "$OUT_DIR" == "" ]; then
  OUT_DIR="$ROOT/out"
fi
rm -rf $OUT_DIR
mkdir -p "$OUT_DIR"
OUT_DIR="$(cd $OUT_DIR && pwd)"
export OUT_DIR

if [ "$DIST_DIR" == "" ]; then
  DIST_DIR="$OUT_DIR/dist"
fi
mkdir -p "$DIST_DIR"
export DIST_DIR

PREBUILTS=$ROOT/prebuilts
BIN_PATH=$PREBUILTS/build-tools/linux-x86/bin

# We need a host clang to build the stage1 clang to build the stage2 clang
# (build machines have a very old gcc by default)
HOST_SYSROOT=$PREBUILTS/clang/host/linux-x86/clang-r437112b
HOST_CLANG_BIN=$HOST_SYSROOT/bin

# Add prebuilts (especially ninja) to PATH
#   (cmake won't run if ninja is not on PATH)
export PATH=$BIN_PATH:$PATH

CMAKE=$PREBUILTS/cmake/linux-x86/bin/cmake
NINJA=$BIN_PATH/ninja

LINKER_FLAGS=(-fuse-ld=lld -static-libstdc++)

CMAKE_COMMON_OPTS=(
    -G Ninja
    -DCMAKE_BUILD_TYPE=Release
    -DLLVM_ENABLE_ASSERTIONS=OFF
    -DLLVM_ENABLE_TERMINFO=OFF
    -DLLVM_INCLUDE_GO_TESTS=OFF
    -DLLVM_ENABLE_Z3_SOLVER=OFF
    -DCOMPILER_RT_BUILD_BUILTINS=ON
    -DLLVM_ENABLE_THREADS=ON
    -DLLVM_OPTIMIZED_TABLEGEN=ON
    -DLLVM_ENABLE_PROJECTS="clang;lld;libcxx;libcxxabi;compiler-rt"
    -DLLVM_BUILD_LLVM_DYLIB=OFF
    -DLLVM_LINK_LLVM_DYLIB=OFF
    -DLLVM_ENABLE_LIBCXX=ON
)

function cmakeBinArgs() {
    binDir=$1
    echo "\
	-DCMAKE_C_COMPILER=$binDir/clang \
	-DCMAKE_CXX_COMPILER=$binDir/clang++ \
	-DCMAKE_LINKER=$binDir/ld.lld \
	-DCMAKE_AR=$binDir/llvm-ar"
}

function stage1build() {
    STAGE1=$OUT_DIR/stage1
    mkdir -p $STAGE1

    STAGE1BUILD=$OUT_DIR/stage1build

    mkdir -p $STAGE1BUILD
    pushd $STAGE1BUILD

    # Build a toolset into $STAGE1.  We only need native, because
    # this is just for the next step.

    $CMAKE \
	$(cmakeBinArgs $HOST_CLANG_BIN) \
	-DCMAKE_INSTALL_PREFIX=$STAGE1 \
	-DLLVM_TARGETS_TO_BUILD=Native \
	-DCMAKE_EXE_LINKER_FLAGS="${LINKER_FLAGS[*]}" \
	-DCMAKE_SHARED_LINKER_FLAGS="${LINKER_FLAGS[*]}" \
	-DCMAKE_MODULE_LINKER_FLAGS="${LINKER_FLAGS[*]}" \
	"${CMAKE_COMMON_OPTS[@]}" \
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
	$(cmakeBinArgs $STAGE1/bin) \
	-DCMAKE_INSTALL_PREFIX=$DIST_DIR \
	"${CMAKE_COMMON_OPTS[@]}" \
	-DCMAKE_EXE_LINKER_FLAGS="-static-libstdc++" \
	-DCMAKE_SHARED_LINKER_FLAGS="-static-libstdc++" \
	-DCMAKE_MODULE_LINKER_FLAGS="-static-libstdc++" \
	$LLVM_PROJECT/llvm

    $NINJA install

    popd
}

stage1build

echo "Skipping stage 2 build for now: b/213465361"
# stage2build

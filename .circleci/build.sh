#!/usr/bin/env bash
echo "Downloading few Dependecies . . ."
git clone -b KSU-NEXT --depth=1 https://github.com/Assunzain/Kernel_asus_X01AD X01AD
git clone --depth=1 https://github.com/kdrag0n/proton-clang -b master clang

# Main
KERNEL_NAME=KSU-NEXT-Kernel-Z # IMPORTANT ! Declare your kernel name
KERNEL_ROOTDIR=$(pwd)/X01AD # IMPORTANT ! Fill with your kernel source root directory.
DEVICE_CODENAME=X01AD # IMPORTANT ! Declare your device codename
DEVICE_DEFCONFIG=X01AD_defconfig # IMPORTANT ! Declare your kernel source defconfig file here.
CLANG_ROOTDIR=$(pwd)/clang # IMPORTANT! Put your clang directory here.
export KBUILD_BUILD_USER=AssunZain # Change with your own name or else.
export KBUILD_BUILD_HOST=GLKernelBased # Change with your own hostname.
IMAGE=$(pwd)/X01AD/out/arch/arm64/boot/Image.gz-dtb
DATE=$(date +"%F-%S")
START=$(date +"%s")
PATH="${PATH}:${CLANG_ROOTDIR}/bin"

# Checking environtment
# Warning !! Dont Change anything there without known reason.
function check() {
echo ================================================
echo My Project CircleCI Editiion
echo version : rev0.1 - Goo..
echo ================================================
echo BUILDER NAME = ${KBUILD_BUILD_USER}
echo BUILDER HOSTNAME = ${KBUILD_BUILD_HOST}
echo DEVICE_DEFCONFIG = ${DEVICE_DEFCONFIG}
echo CLANG_VERSION = $(${CLANG_ROOTDIR}/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')
echo CLANG_ROOTDIR = ${CLANG_ROOTDIR}
echo KERNEL_ROOTDIR = ${KERNEL_ROOTDIR}
echo ================================================
}

# Compiler
function compile() {

   # Your Telegram Group
   curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>xKernelCompiler</b>%0ABUILDER NAME : <code>${KBUILD_BUILD_USER}</code>%0ABUILDER HOST : <code>${KBUILD_BUILD_HOST}</code>%0ADEVICE DEFCONFIG : <code>${DEVICE_DEFCONFIG}</code>%0ACLANG VERSION : <code>$(${CLANG_ROOTDIR}/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')</code>%0ACLANG ROOTDIR : <code>${CLANG_ROOTDIR}</code>%0AKERNEL ROOTDIR : <code>${KERNEL_ROOTDIR}</code>"

  cd ${KERNEL_ROOTDIR}
  make -j$(nproc) -j8 O=out ARCH=arm64 ${DEVICE_DEFCONFIG}
  make -j$(nproc) -j8 ARCH=arm64 O=out \
	CC=${CLANG_ROOTDIR}/bin/clang \
        LLVM=1 \
        LLVM_IAS=1 \
	HOSTCFLAGS="-fuse-ld=lld -Wno-unused-command-line-argument" \
	CROSS_COMPILE=${CLANG_ROOTDIR}/bin/aarch64-linux-gnu- \
	CROSS_COMPILE_ARM32=${CLANG_ROOTDIR}/bin/arm-linux-gnueabi- 

   if ! [ -a "$IMAGE" ]; then
	finerr
	exit 1
   fi
    git clone -b X01AD-old --depth=1 https://github.com/Assunzain/Anykernel3.git AnyKernel
	cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
}

# Push
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Compile selesai dalam kurun waktu $(($DIFF / 60)) menit(s) dan $(($DIFF % 60)) detik(s). | Untuk <b>Asus Zenfone Max M2 (X01AD)</b> | <b>$(${CLANG_ROOTDIR}/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')</b>"

}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Yahh Build kamu error(s)"
    exit 1
}

# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 ${KERNEL_NAME}-${DEVICE_CODENAME}-${DATE}.zip *
    cd ..
}
check
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push

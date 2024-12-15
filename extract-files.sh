#!/bin/bash
#
# SPDX-FileCopyrightText: 2016 The CyanogenMod Project
# SPDX-FileCopyrightText: 2017-2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=veux
VENDOR=xiaomi

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

# Define the default patchelf version used to patch blobs
# This will also be used for utility functions like FIX_SONAME
export PATCHELF_VERSION=0_18

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

ONLY_FIRMWARE=
KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        --only-firmware)
            ONLY_FIRMWARE=true
            ;;
        -n | --no-cleanup)
            CLEAN_VENDOR=false
            ;;
        -k | --kang)
            KANG="--kang"
            ;;
        -s | --section)
            SECTION="${2}"
            shift
            CLEAN_VENDOR=false
            ;;
        *)
            SRC="${1}"
            ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        odm/etc/build_*.prop)
            [ "$2" = "" ] && return 0
            sed -i "/marketname/d" "${2}"
            sed -i "s/cert/model/" "${2}"
            ;;
        system_ext/etc/init/wfdservice.rc)
            [ "$2" = "" ] && return 0
            sed -i "/^service/! s/wfdservice$/wfdservice64/g" "${2}"
            ;;
        system_ext/lib64/libwfdmmsrc_system.so)
            [ "$2" = "" ] && return 0
            grep -q "libgui_shim.so" "${2}" || "${PATCHELF}" --add-needed "libgui_shim.so" "${2}"
            ;;
        system_ext/lib64/libwfdnative.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --remove-needed "android.hidl.base@1.0.so" "${2}"
            grep -q "libinput_shim.so" "${2}" || "${PATCHELF}" --add-needed "libinput_shim.so" "${2}"
            ;;
        system_ext/lib64/libwfdservice.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "android.media.audio.common.types-V2-cpp.so" "android.media.audio.common.types-V3-cpp.so" "${2}"
            ;;
        vendor/etc/camera/camxoverridesettings.txt)
            [ "$2" = "" ] && return 0
            sed -i "s/0x10080/0/g" "${2}"
            sed -i "s/0x1F/0x0/g" "${2}"
            ;;
        vendor/etc/init/init.batterysecret.rc)
            [ "$2" = "" ] && return 0
            sed -i "s/on charger/on property:init.svc.vendor.charger=running/g" "${2}"
            ;;
        vendor/etc/libnfc-pn557.conf)
            [ "$2" = "" ] && return 0
            grep -q "NXP RF" "${2}" || cat "${SRC}/vendor/libnfc-nxp_RF.conf" >> "${2}"
            ;;
        vendor/etc/seccomp_policy/atfwd@2.0.policy)
            [ "$2" = "" ] && return 0
            grep -q "gettid: 1" "${2}" || echo "gettid: 1" >> "${2}"
            ;;
        vendor/lib64/android.hardware.secure_element@1.0-impl.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --remove-needed "android.hidl.base@1.0.so" "${2}"
            ;;
        vendor/lib64/camera/components/com.qti.node.mialgocontrol.so)
            [ "$2" = "" ] && return 0
            llvm-strip --strip-debug "${2}"
            grep -q "libpiex_shim.so" "${2}" || "${PATCHELF}" --add-needed "libpiex_shim.so" "${2}"
            ;;
        vendor/lib64/libalLDC.so|vendor/lib64/libalhLDC.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --clear-symbol-version "AHardwareBuffer_allocate" "${2}"
            "${PATCHELF}" --clear-symbol-version "AHardwareBuffer_describe" "${2}"
            "${PATCHELF}" --clear-symbol-version "AHardwareBuffer_lock" "${2}"
            "${PATCHELF}" --clear-symbol-version "AHardwareBuffer_release" "${2}"
            "${PATCHELF}" --clear-symbol-version "AHardwareBuffer_unlock" "${2}"
            ;;
        vendor/lib64/libgoodixhwfingerprint.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "libvendor.goodix.hardware.biometrics.fingerprint@2.1.so" "vendor.goodix.hardware.biometrics.fingerprint@2.1.so" "${2}"
            ;;
        vendor/lib64/libwvhidl.so|vendor/lib64/mediadrm/libwvdrmengine.so)
            [ "$2" = "" ] && return 0
            grep -q "libcrypto_shim.so" "${2}" || "${PATCHELF}" --add-needed "libcrypto_shim.so" "${2}"
            ;;
        *)
            return 1
            ;;
    esac

    return 0
}

function blob_fixup_dry() {
    blob_fixup "$1" ""
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

if [ -z "${ONLY_FIRMWARE}" ]; then
    extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

"${MY_DIR}/setup-makefiles.sh"

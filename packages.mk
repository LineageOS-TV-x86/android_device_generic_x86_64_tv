#
# Copyright (C) 2014 The Android-x86 Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Common packages for Android-x86 platform.

PRODUCT_PACKAGES += \
    com.android.future.usb.accessory \
    drmserver \
    gps.default \
    gps.huawei \
    io_switch \
    rtk_hciattach \
    scp \
    sftp \
    ssh \
    sshd \
    tablet-mode \
    wacom-input \

PRODUCT_PACKAGES += \
    libwpa_client \
    hostapd \
    wificond \
    wpa_supplicant

PRODUCT_PACKAGES += \
    e2fsck \
    fsck.exfat \
    fsck.f2fs \
    mke2fs \
    make_f2fs \
    mkfs.exfat \
    resize2fs \
    tune2fs \

PRODUCT_PACKAGES += \
    btattach \
	btmon \
    hciconfig \
    hcitool \
    thermal-daemon

# Third party apps
PRODUCT_PACKAGES += \
    libnativebridge-headers \
    libnativeloader-headers \
    libandroidemu

PRODUCT_HOST_PACKAGES, += \
    libnativebridge \
    libnativeloader

# Debug tools
PRODUCT_PACKAGES_DEBUG := \
    avdtptest \
    avinfo \
    avtest \
    bneptest \
    btmgmt \
    btproxy \
    haltest \
    l2ping \
    l2test \
    mcaptest \
    rctest \

#
# Packages for AOSP-available stuff we use from the framework
#
PRODUCT_PACKAGES += \
    ip \
    tcpdump \
    libbt-vendor \
    iw \
    iw_vendor

# usb.ids & pci.ids
PRODUCT_PACKAGES += usb.ids pci.ids

# wireless-regdb
PRODUCT_PACKAGES += regulatory.db regulatory.db.p7s

## Enable hidden features on Android
PRODUCT_PACKAGES += \
	pc.xml \
	hpe.xml

# Some additional CLI programs
PRODUCT_PACKAGES += tput dialog alsa-info.sh tree lspci dmidecode vainfo evtest efibootmgr

# Surface specific
ifeq ($(BOARD_IS_SURFACE_BUILD),true)
PRODUCT_PACKAGES += set_iptsd_device iptsd \
                    iptsd-find-hidraw \
                    iptsd-calibrate \
                    iptsd-check-device \
                    iptsd-dump \
                    iptsd-perf
endif

# For Recovery
## DHCP client
PRODUCT_PACKAGES += \
    x86_dhcpclient.recovery

# A collection of scripts at scripts/
PRODUCT_PACKAGES += blisspath boot-mode-selection.sh recovery.bms.sh

## ATV
PRODUCT_PACKAGES += \
    DocumentsUI \
    AudioOutputSwitch

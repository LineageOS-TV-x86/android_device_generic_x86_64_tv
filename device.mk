#
# Copyright (C) 2014-2016 The Android-x86 Open Source Project
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

PRODUCT_DIR := $(dir $(lastword $(filter-out device/common/%,$(filter device/%,$(ALL_PRODUCTS)))))

# ATV
PRODUCT_IS_ATV := true

# No Compressed APEXes
OVERRIDE_PRODUCT_COMPRESSED_APEX := false

# A/B
PRODUCT_BUILD_GENERIC_OTA_PACKAGE := true
AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

PRODUCT_PACKAGES += \
    otapreopt_script

# Boot control
PRODUCT_PACKAGES_DEBUG += \
    bootctl

# Update engine
PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

PRODUCT_PACKAGES_DEBUG += \
    update_engine_client

PRODUCT_PROPERTY_OVERRIDES := \
    ro.lmk.kill_timeout_ms=100 \
    ro.arch=x86 \
    persist.rtc_local_time=1 \
    dalvik.vm.useautofastjni=true \
    ro.surface_flinger.max_frame_buffer_acquired_buffers=3 \
    audio.safemedia.bypass=true \
    persist.device_config.mglru_native.lru_gen_config=all \
    persist.sys.zram_enabled=1 \
    external_storage.casefold.enabled=1 \
    external_storage.projid.enabled=1

PRODUCT_SYSTEM_EXT_PROPERTIES += ro.setupwizard.mode=DISABLED

PRODUCT_COPY_FILES := \
    $(if $(wildcard $(PRODUCT_DIR)init.rc),$(PRODUCT_DIR)init.rc:root/init.rc) \
    $(if $(wildcard $(PRODUCT_DIR)init.sh),$(PRODUCT_DIR),$(LOCAL_PATH)/)init.sh:system/etc/init.sh \
    $(if $(wildcard $(PRODUCT_DIR)init.fstab.sh),$(PRODUCT_DIR),$(LOCAL_PATH)/)init.fstab.sh:$(TARGET_COPY_OUT_VENDOR)/etc/init.fstab.sh \
    $(if $(wildcard $(PRODUCT_DIR)init.zram.sh),$(PRODUCT_DIR),$(LOCAL_PATH)/)init.zram.sh:$(TARGET_COPY_OUT_VENDOR)/etc/init.zram.sh \
    $(if $(wildcard $(PRODUCT_DIR)modules.blocklist),$(PRODUCT_DIR),$(LOCAL_PATH)/)modules.blocklist:system/etc/modules.blocklist \
    $(if $(wildcard $(PRODUCT_DIR)modules.options),$(PRODUCT_DIR),$(LOCAL_PATH)/)modules.options:system/etc/modules.options \
    $(if $(wildcard $(PRODUCT_DIR)fstab.$(TARGET_PRODUCT)),$(PRODUCT_DIR)fstab.$(TARGET_PRODUCT),$(LOCAL_PATH)/fstab.x86):root/fstab.$(TARGET_PRODUCT) \
    $(if $(wildcard $(PRODUCT_DIR)wpa_supplicant.conf),$(PRODUCT_DIR),$(LOCAL_PATH)/)wpa_supplicant.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant.conf \
    $(if $(wildcard $(PRODUCT_DIR)wpa_supplicant_overlay.conf),$(PRODUCT_DIR),$(LOCAL_PATH)/)wpa_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant_overlay.conf \
    $(if $(wildcard $(PRODUCT_DIR)excluded-input-devices.xml),$(PRODUCT_DIR),$(LOCAL_PATH)/)excluded-input-devices.xml:system/etc/excluded-input-devices.xml \
    $(if $(wildcard $(PRODUCT_DIR)init.$(TARGET_PRODUCT).rc),$(PRODUCT_DIR)init.$(TARGET_PRODUCT).rc,$(LOCAL_PATH)/init.x86.rc):root/init.$(TARGET_PRODUCT).rc \
    $(if $(wildcard $(PRODUCT_DIR)ueventd.$(TARGET_PRODUCT).rc),$(PRODUCT_DIR)ueventd.$(TARGET_PRODUCT).rc,$(LOCAL_PATH)/ueventd.x86.rc):$(TARGET_COPY_OUT_VENDOR)/etc/ueventd.rc \

# Copy System Files
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/ppp/ip-up:$(TARGET_COPY_OUT_SYSTEM)/etc/ppp/ip-up \
    $(LOCAL_PATH)/ppp/ip-down:$(TARGET_COPY_OUT_SYSTEM)/etc/ppp/ip-down \
    $(LOCAL_PATH)/ppp/peers/gprs:$(TARGET_COPY_OUT_SYSTEM)/etc/ppp/peers/gprs \
    $(LOCAL_PATH)/media_codecs.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs.xml \
    $(LOCAL_PATH)/media_profiles.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles_V1_0.xml \
    $(LOCAL_PATH)/fstab.internal.x86:$(TARGET_COPY_OUT_SYSTEM)/vendor/etc/fstab.internal.x86 \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_audio.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_video.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_video.xml \
    external/mesa/src/util/00-mesa-defaults.conf:$(TARGET_COPY_OUT_VENDOR)/etc/drirc

# Copy Vendor Files
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/external_camera_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/external_camera_config.xml \
    frameworks/native/data/etc/android.hardware.audio.low_latency.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.low_latency.xml \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.xml \
    frameworks/native/data/etc/android.hardware.ethernet.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.ethernet.xml \
    frameworks/native/data/etc/android.hardware.fingerprint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.fingerprint.xml \
    frameworks/native/data/etc/android.hardware.gamepad.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.gamepad.xml \
    frameworks/native/data/etc/android.software.ipsec_tunnels.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.ipsec_tunnels.xml \
    frameworks/native/data/etc/android.hardware.location.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.location.xml \
    frameworks/native/data/etc/android.hardware.location.gps.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.location.gps.xml \
    frameworks/native/data/etc/android.hardware.opengles.aep.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.opengles.aep.xml \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.barometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.barometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.compass.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.compass.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.gyroscope.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.distinct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.distinct.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.software.activities_on_secondary_displays.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.activities_on_secondary_displays.xml \
    frameworks/native/data/etc/android.software.app_widgets.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.app_widgets.xml \
    frameworks/native/data/etc/android.software.connectionservice.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.connectionservice.xml \
    frameworks/native/data/etc/android.software.controls.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.controls.xml \
    frameworks/native/data/etc/android.software.device_admin.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.device_admin.xml \
    frameworks/native/data/etc/android.software.freeform_window_management.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.freeform_window_management.xml \
    frameworks/native/data/etc/android.software.midi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.midi.xml \
    frameworks/native/data/etc/android.software.picture_in_picture.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.picture_in_picture.xml \
    frameworks/native/data/etc/android.software.print.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.print.xml \
    frameworks/native/data/etc/android.software.sip.voip.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.sip.voip.xml \
    frameworks/native/data/etc/android.software.autofill.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.autofill.xml \
    frameworks/native/data/etc/android.software.sip.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.sip.xml \
    frameworks/native/data/etc/android.software.voice_recognizers.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.voice_recognizers.xml \
    frameworks/native/data/etc/android.software.webview.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.webview.xml \
    frameworks/native/data/etc/android.hardware.keystore.app_attest_key.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.keystore.app_attest_key.xml \
    external/thermal_daemon/data/thermal-conf.xml:$(TARGET_COPY_OUT_VENDOR)/etc/thermal-daemon/thermal-conf.xml \
    external/thermal_daemon/data/thermal-cpu-cdev-order.xml:$(TARGET_COPY_OUT_VENDOR)/etc/thermal-daemon/thermal-cpu-cdev-order.xml \
    $(LOCAL_PATH)/OEMBlackList:$(TARGET_COPY_OUT_VENDOR)/etc/misc/.OEMBlackList \
    $(LOCAL_PATH)/OEMWhiteList:$(TARGET_COPY_OUT_VENDOR)/etc/misc/.OEMWhiteList \
    $(LOCAL_PATH)/ThirdPartySO:$(TARGET_COPY_OUT_VENDOR)/etc/misc/.ThirdPartySO \
    $(LOCAL_PATH)/seccomp/mediaswcodec.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/mediaswcodec.policy

# Copy Misc Config Files
PRODUCT_COPY_FILES += \
    $(foreach f,$(wildcard $(LOCAL_PATH)/idc/*.idc $(LOCAL_PATH)/keylayout/*.kl),$(f):$(subst $(LOCAL_PATH),system/usr,$(f)))

# Go init
ifeq ($(BOARD_IS_GO_BUILD),true)
PRODUCT_COPY_FILES += \
    $(if $(wildcard $(PRODUCT_DIR)init.low_performance.rc),$(PRODUCT_DIR)init.low_performance.rc,$(LOCAL_PATH)/init.low_performance.rc):$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.low_performance.rc
endif

# Recovery
PRODUCT_COPY_FILES += \
    $(if $(wildcard $(PRODUCT_DIR)init.recovery.$(TARGET_PRODUCT).rc),$(PRODUCT_DIR)init.recovery.$(TARGET_PRODUCT).rc,$(LOCAL_PATH)/init.recovery.x86.rc):$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.$(TARGET_PRODUCT).rc \
    $(if $(wildcard $(PRODUCT_DIR)init.recovery.sh),$(PRODUCT_DIR),$(LOCAL_PATH)/)init.recovery.sh:$(TARGET_COPY_OUT_RECOVERY)/root/system/etc/init.recovery.sh \
    $(if $(wildcard $(PRODUCT_DIR)init.fstab.sh),$(PRODUCT_DIR),$(LOCAL_PATH)/)init.fstab.sh:$(TARGET_COPY_OUT_RECOVERY)/root/system/etc/init.fstab.sh \

PRODUCT_TAGS += dalvik.gc.type-precise

PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false
PRODUCT_ENFORCE_VINTF_MANIFEST_OVERRIDE := true
PRODUCT_CHARACTERISTICS := tv

# AAPT
PRODUCT_AAPT_PREF_CONFIG := tvdpi

DEVICE_PACKAGE_OVERLAYS := $(LOCAL_PATH)/overlay

ifeq ($(BOARD_IS_GO_BUILD),true)
DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay-go
endif

# Force sdcardfs to use esdfs instead
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.sys.sdcardfs=false \
    persist.sys.sdcardfs=force_off

# Copy any Permissions files, overriding anything if needed
$(foreach f,$(wildcard $(LOCAL_PATH)/permissions/*.xml),\
    $(eval PRODUCT_COPY_FILES += $(f):$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/permissions/$(notdir $f)))

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/sysconfig/hiddenapi-package-whitelist-org.lineageos.tv.audiooutput.xml:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/sysconfig/hiddenapi-package-whitelist-org.lineageos.tv.audiooutput.xml

# Get emulated storage settings
#$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# Get Android 8.0 HIDL HALs
$(call inherit-product,$(LOCAL_PATH)/treble.mk)

# Get the touchscreen calibration tool
$(call inherit-product-if-exists,external/tslib/tslib.mk)

# Get the alsa files
$(call inherit-product-if-exists,hardware/libaudio/alsa.mk)

# Get GPS configuration
$(call inherit-product-if-exists,device/common/gps/gps_as.mk)

# Get the hardware acceleration libraries
$(call inherit-product-if-exists,$(LOCAL_PATH)/gpu/gpu_mesa.mk)

# Get the sensors hals
$(call inherit-product-if-exists,hardware/libsensors/sensors.mk)

# Get GloDroid components
$(call inherit-product-if-exists,$(LOCAL_PATH)/glodroid/device_glodroid.mk)

ifeq ($(USE_LIBNDK_TRANSLATION_NB),true)
$(call inherit-product-if-exists, vendor/google/emu-x86/target/libndk_translation.mk)
$(call inherit-product-if-exists, vendor/google/emu-x86/target/native_bridge_arm_on_x86.mk)
NDK_TRANSLATION_PREINSTALL := google
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += persist.sys.nativebridge=1
endif

ifeq ($(USE_CROS_HOUDINI_NB),true)
$(call inherit-product-if-exists, vendor/google/chromeos-x86/target/houdini.mk)
$(call inherit-product-if-exists, vendor/google/chromeos-x86/target/native_bridge_arm_on_x86.mk)
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += persist.sys.nativebridge=1
endif

ifeq ($(ANDROID_USE_NDK_TRANSLATION),true)
$(call inherit-product-if-exists, vendor/google/proprietary/ndk_translation-prebuilt/libndk_translation.mk)
$(call inherit-product-if-exists, vendor/google/proprietary/ndk_translation-prebuilt/native_bridge_arm_on_x86.mk)
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += persist.sys.nativebridge=1
endif

ifeq ($(ANDROID_USE_INTEL_HOUDINI),true)
$(call inherit-product-if-exists, vendor/intel/proprietary/houdini/houdini.mk)
$(call inherit-product-if-exists, vendor/intel/proprietary/houdini/native_bridge_arm_on_x86.mk)
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += persist.sys.nativebridge=1
endif

$(call inherit-product,$(if $(wildcard $(PRODUCT_DIR)packages.mk),$(PRODUCT_DIR),$(LOCAL_PATH)/)packages.mk)

ifeq ($(BOARD_IS_GO_BUILD),true)
ifeq ($(BOARD_IS_SURFACE_BUILD),true)
$(error "Go build should not be mixed with Surface build")
endif
ifeq ($(BOARD_IS_ZENITH_BUILD),true)
$(error "Go build should not be mixed with Zenith build")
endif
# Inherit common Android Go configurations
$(call inherit-product, build/target/product/go_defaults.mk)
DONT_UNCOMPRESS_PRIV_APPS_DEXS := true
endif

# Surface specific
ifeq ($(BOARD_IS_SURFACE_BUILD),true)
ifeq ($(BOARD_IS_ZENITH_BUILD),true)
$(error "Surface build should not be mixed with Zenith build")
endif
BLISS_SPECIAL_VARIANT := -Surface
endif

# Zenith
ifeq ($(BOARD_IS_ZENITH_BUILD),true)
BLISS_SPECIAL_VARIANT := -Zenith
endif

ifeq ($(USE_WIDEVINE),true)
$(call inherit-product-if-exists, vendor/google/chromeos-x86/target/widevine.mk)
$(call inherit-product-if-exists, vendor/google/proprietary/widevine-prebuilt/widevine.mk)
endif

# Add agp-apps
$(call inherit-product-if-exists, vendor/agp-apps/agp-apps.mk)

# DRM service opt-in
PRODUCT_VENDOR_PROPERTIES += drm.service.enabled=true

PRODUCT_REQUIRES_INSECURE_EXECMEM_FOR_SWIFTSHADER := true

# Custom Lineage OTA server
PRODUCT_PRODUCT_PROPERTIES += \
    lineage.updater.uri=https://lineageos-tv-x86.github.io/ota/api/v1/{device}_{type}

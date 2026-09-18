# Out-of-Tree Build Configuration
# This file is included when WireGuard is not found in kernel tree

AWG_SOURCE_SHORT:=ac946a9
AWG_SOURCE_BASENAME:=amneziawg-$(AWG_SOURCE_SHORT)

ifneq ($(CONFIG_USE_APK),)
PKG_VERSION:=0~$(AWG_SOURCE_SHORT)
else
PKG_VERSION:=0-$(AWG_SOURCE_SHORT)
endif
PKG_RELEASE:=2

PKG_SOURCE:=$(AWG_SOURCE_BASENAME).tar.gz

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/amnezia-vpn/amneziawg-linux-kernel-module.git
PKG_SOURCE_VERSION:=ac946a9df100a17d342b5982d1947deef1b51952

PKG_SOURCE_SUBDIR:=amneziawg-linux-kernel-module-$(AWG_SOURCE_BASENAME)
PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/$(PKG_SOURCE_SUBDIR)
AWG_BUILD_DIR:=$(PKG_BUILD_DIR)/src

# Extra compiler flags for out-of-tree build
AWG_EXTRA_CFLAGS:=
AWG_EXTRA_MAKE_FLAGS:=CONFIG_GL_FORCE_OUT_CRYPTO=y CONFIG_GL_FORCE_NOT_OUT_CRYPTO=n
# AWG_EXTRA_CFLAGS+=-Wno-error=stringop-overread
# Include package.mk here for out-of-tree build
include $(INCLUDE_DIR)/package.mk

# Build/Prepare: unpack source and apply compat patches

MEDIATEK_MT798X_TARGETS := $(CONFIG_TARGET_mediatek_mt7981) \
                           $(CONFIG_TARGET_mediatek_mt7986) \
                           $(CONFIG_TARGET_mediatek_mt7987) \
                           $(CONFIG_TARGET_mediatek_mt7988) \
                           $(CONFIG_TARGET_ramips_mt7621) \
                           $(CONFIG_TARGET_mediatek_filogic)
QUECTEL_RG650V_TARGETS := $(CONFIG_TARGET_sdx75)
QUECTEL_RG228QD_TARGETS := $(CONFIG_TARGET_qmb415)
ifneq ($(filter y,$(MEDIATEK_MT798X_TARGETS) $(QUECTEL_RG650V_TARGETS) $(QUECTEL_RG228QD_TARGETS)),)
  AWG_EXTRA_MAKE_FLAGS:=CONFIG_GL_FORCE_OUT_CRYPTO=n CONFIG_GL_FORCE_NOT_OUT_CRYPTO=y
  AWG_EXTRA_CFLAGS:=-DGL_NOT_COMPAT_OLD_IP_TUNNEL_IF -DGL_FORCE_NOT_COMPAT_SIMD -DGL_FORCE_NOT_USE_ZINC_CRYPTO
endif

define Build/Prepare
	$(call Build/Prepare/Default)
	@echo "[amneziawg-OOT] Applying compat patches"
	mkdir -p $(PKG_BUILD_DIR)/patches
	$(CP) -rvf $(CURDIR)/compat-patches/*.patch $(PKG_BUILD_DIR)/patches/ 2>/dev/null || true
	cd "$(PKG_BUILD_DIR)" && \
	ls patches/*.patch | xargs -n1 basename | sort -V > patches/series && \
	QUILT_PATCHES=patches quilt push -a || true;
endef

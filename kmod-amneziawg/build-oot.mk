# Out-of-Tree Build Configuration
# This file is included when WireGuard is not found in kernel tree

PKG_VERSION:=amneziawg-ac946a9
PKG_RELEASE:=2.0

PKG_SOURCE:=$(PKG_VERSION).tar.gz

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/amnezia-vpn/amneziawg-linux-kernel-module.git
PKG_SOURCE_VERSION:=ac946a9df100a17d342b5982d1947deef1b51952

PKG_SOURCE_SUBDIR:=amneziawg-linux-kernel-module-$(PKG_VERSION)
PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/$(PKG_SOURCE_SUBDIR)
AWG_BUILD_DIR:=$(PKG_BUILD_DIR)/src

# Extra compiler flags for out-of-tree build
AWG_EXTRA_CFLAGS:=
# AWG_EXTRA_CFLAGS+=-Wno-error=stringop-overread
# Include package.mk here for out-of-tree build
include $(INCLUDE_DIR)/package.mk

# Build/Prepare: unpack source and apply compat patches

ifeq ($(CONFIG_TARGET_mediatek_mt7981),y)
  AWG_EXTRA_CFLAGS+=-DGL_NOT_COMPAT_OLD_IP_TUNNEL_IF
endif

ifeq ($(CONFIG_TARGET_mediatek_mt7986),y)
  AWG_EXTRA_CFLAGS+=-DGL_NOT_COMPAT_OLD_IP_TUNNEL_IF
endif

ifeq ($(CONFIG_TARGET_mediatek_mt7988),y)
  AWG_EXTRA_CFLAGS+=-DGL_NOT_COMPAT_OLD_IP_TUNNEL_IF
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

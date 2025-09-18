include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=kmod-amneziawg

# Detect if WireGuard exists in kernel tree
WG_IN_TREE_DIR := $(strip $(wildcard $(LINUX_DIR)/drivers/net/wireguard))
$(info WG_IN_TREE_DIR: $(WG_IN_TREE_DIR))

# Use an isolated build dir, never $(KERNEL_BUILD_DIR) root
ifeq ($(WG_IN_TREE_DIR),)
  # ---- Out-of-tree ----
  PKG_VERSION:=1.0.20241112
  PKG_RELEASE:=1

  PKG_SOURCE:=v$(PKG_VERSION).tar.gz
  PKG_SOURCE_URL:=https://github.com/amnezia-vpn/amneziawg-linux-kernel-module/archive/refs/tags/
  PKG_HASH:=3c70dce9aec00c217021037b475fbcb792ab701d72bfd696c866f8740b96218d

  PKG_SOURCE_SUBDIR:=amneziawg-linux-kernel-module-$(PKG_VERSION)
  PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/$(PKG_SOURCE_SUBDIR)
  AWG_BUILD_DIR:=$(PKG_BUILD_DIR)/src
else
  # ---- In-tree: copy WG sources into our own dir ----
  PKG_VERSION:=in-tree
  PKG_RELEASE:=1
  PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/amneziawg-intree
  AWG_BUILD_DIR:=$(PKG_BUILD_DIR)
endif

include $(INCLUDE_DIR)/package.mk

define KernelPackage/amneziawg
  SECTION:=kernel
  CATEGORY:=Kernel modules
  SUBMENU:=Network Support
  TITLE:=AmneziaWG Kernel Module
  URL:=https://amnezia.org/
  MAINTAINER:=Amnezia Admin <admin@amnezia.org>
  FILES:=$(AWG_BUILD_DIR)/amneziawg.$(LINUX_KMOD_SUFFIX)
  DEPENDS:= \
		+kmod-udptunnel4 \
		+kmod-udptunnel6 \
		+kmod-crypto-lib-chacha20poly1305 \
		+kmod-crypto-lib-curve25519
endef

define Build/Prepare
	$(call Build/Prepare/Default)

ifneq ($(WG_IN_TREE_DIR),)
	@echo "[amneziawg] WireGuard is in-tree, copying sources into $(PKG_BUILD_DIR)"
	$(CP) -v $(WG_IN_TREE_DIR)/*.c $(PKG_BUILD_DIR)/ 2>/dev/null || true
	$(CP) -v $(WG_IN_TREE_DIR)/*.h $(PKG_BUILD_DIR)/ 2>/dev/null || true
	mkdir -p $(PKG_BUILD_DIR)/selftest $(PKG_BUILD_DIR)/uapi
	$(CP) -rv $(WG_IN_TREE_DIR)/selftest $(PKG_BUILD_DIR)/ 2>/dev/null || true
	$(CP) -v $(WG_IN_TREE_DIR)/uapi/linux/wireguard.h $(PKG_BUILD_DIR)/uapi/ 2>/dev/null || true

	# --- quilt patching for in-tree ---
	mkdir -p $(PKG_BUILD_DIR)/patches/common_patches
	mkdir -p $(PKG_BUILD_DIR)/patches/board_spec

	- cp -rvf $(CURDIR)/patches/common_patches/*.patch $(PKG_BUILD_DIR)/patches/common_patches/ 2>/dev/null
	- cp -rvf $(CURDIR)/patches/board_spec/$(BOARD)/$(SUBTARGET)/patches/*.patch $(PKG_BUILD_DIR)/patches/board_spec/ 2>/dev/null

	- sh -c 'cd "$(PKG_BUILD_DIR)" && find patches -name "*.patch" | xargs -n1 basename | sort -V > patches/series'
	@echo "[amneziawg] In-tree patch series generated (if any):"
	- @cat $(PKG_BUILD_DIR)/patches/series
	- sh -c 'cd "$(PKG_BUILD_DIR)" && [ -s patches/series ] && QUILT_PATCHES=patches quilt push -a'

else
	@echo "[amneziawg] Using out-of-tree source v$(PKG_VERSION)"

	# --- quilt patching for compact ---
	mkdir -p $(PKG_BUILD_DIR)/patches
	- cp -rvf $(CURDIR)/compat-patches/*.patch $(PKG_BUILD_DIR)/patches/ 2>/dev/null
	- sh -c 'cd "$(PKG_BUILD_DIR)" && ls patches/*.patch 2>/dev/null | xargs -n1 basename | sort -V > patches/series'
	@echo "[amneziawg] OOT compact patch series generated (if any):"
	- @cat $(PKG_BUILD_DIR)/patches/series
	- sh -c 'cd "$(PKG_BUILD_DIR)" && [ -s patches/series ] && QUILT_PATCHES=patches quilt push -a'
endif
endef

# Extra flags only for OOT if needed
ifneq ($(WG_IN_TREE_DIR),)
  WG_EXTRA_CFLAGS:=
else
  WG_EXTRA_CFLAGS:=-Wno-error=stringop-overread
endif

define Build/Compile
	$(MAKE) -C "$(LINUX_DIR)" \
		$(KERNEL_MAKE_FLAGS) \
		M="$(AWG_BUILD_DIR)" \
		EXTRA_CFLAGS="$(BUILDFLAGS) $(WG_EXTRA_CFLAGS)" \
		modules
endef

$(eval $(call KernelPackage,amneziawg))


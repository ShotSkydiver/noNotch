export TARGET = iphone:latest:12.0
export ARCHS = arm64e

INSTALL_TARGET_PROCESSES = SpringBoard


export ADDITIONAL_CFLAGS = -DTHEOS_LEAN_AND_MEAN -fobjc-arc

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = noNotch
$(TWEAK_NAME)_FILES = $(wildcard *.x)
$(TWEAK_NAME)_FRAMEWORKS = UIKit CoreGraphics
$(TWEAK_NAME)_EXTRA_FRAMEWORKS = Cephei
$(TWEAK_NAME)_LIBRARIES = rocketbootstrap
$(TWEAK_NAME)_LDFLAGS = $(wildcard *.tbd)

include $(THEOS_MAKE_PATH)/tweak.mk

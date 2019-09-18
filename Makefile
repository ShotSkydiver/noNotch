export TARGET = iphone:latest:12.0
export ARCHS = arm64e

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = noNotch
noNotch_FILES = Tweak.xm
noNotch_FRAMEWORKS = UIKit CoreGraphics
# noNotch_PRIVATE_FRAMEWORKS = AppSupport
noNotch_LDFLAGS = $(wildcard *.tbd)
noNotch_LIBRARIES = rocketbootstrap

include $(THEOS_MAKE_PATH)/tweak.mk

TARGET := iphone:clang:latest:15.0
ARCHS := arm64
THEOS_PACKAGE_SCHEME := rootless
INSTALL_TARGET_PROCESSES := Reynard ChatGPT
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = WriteNowGeckoCompanion
WriteNowGeckoCompanion_FILES = Tweak.xm
WriteNowGeckoCompanion_CFLAGS = -fobjc-arc
WriteNowGeckoCompanion_FRAMEWORKS = UIKit Foundation
include $(THEOS_MAKE_PATH)/tweak.mk

# RednoteTools - 小红书去水印插件

THEOS_DEVICE_IP = 192.168.1.100
THEOS_DEVICE_PORT = 22

TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RednoteTools

RednoteTools_FILES = Tweak.xm CopyrightAnimation.m
RednoteTools_CFLAGS = -fobjc-arc
RednoteTools_FRAMEWORKS = UIKit Foundation WebKit JavaScriptCore

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 'com.xingin.discover' 2>/dev/null || true"

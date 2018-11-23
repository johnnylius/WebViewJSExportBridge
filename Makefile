#Makefile for yaokan

#DATE = $(shell date +%Y%m%d)
#APP_VER = 1.0.0
#SVN_VER = $(shell svn info ./ |grep "Last Changed Rev: "|cut -c 19-)

PROJECT_NAME=WebViewTest
DATE=$(shell date +%Y%m%d)
DEST_DIR=$(shell pwd)
PWD = $(DEST_DIR)
BUILD_DIR = build
ARCHIVE_DIR = $(BUILD_DIR)/$(PROJECT_NAME).xcarchive
IPA_PATH = $(BUILD_DIR)/$(PROJECT_NAME).ipa
CONFIGURATION = $(c)

#InHouse
ifeq "$(CONFIGURATION)" "InHouse" 
  exportOptionsPlist = enterpriseConfig.plist
#Release
else
  ifeq "$(CONFIGURATION)" "Release" 
    exportOptionsPlist = enterpriseConfig.plist
  else
    ifeq "$(CONFIGURATION)" "Discovery_Release" 
	  exportOptionsPlist = exportConfig.plist
	else
	  ifeq "$(CONFIGURATION)" "Discovery_InHouse" 
	    exportOptionsPlist = enterpriseConfig.plist
	  else
        exportOptionsPlist = developmentConfig.plist
	  endif
	endif
  endif
endif
	
.PHONY: all build clean ipa

all: build

build:
	rm -rf $(PWD)/$(BUILD_DIR)
	xcodebuild archive -project UIWebViewDemo.xcodeproj -scheme UIWebViewDemo -configuration $(CONFIGURATION) -archivePath $(PWD)/$(ARCHIVE_DIR);

p:ipa
ipa:
	echo $(CONFIGURATION);
	xcodebuild -exportArchive -archivePath $(PWD)/$(ARCHIVE_DIR) -exportOptionsPlist $(exportOptionsPlist) -exportPath $(PWD)/$(IPA_PATH)

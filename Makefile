KEYSTORE=TheKeyStore.jks
KEYNAME=TheReleaseKeyName
STOREPASS=TheStorePassword
KEYPASS=TheKeyPassword
DNAME=CN=Hermann Digimon, OU=Software Building Department, O=Big Company ltd., L=Sometown, S=Somewhere, C=HR

APKNAME=TheGrandExperiment
IDENTIFIER=net.vucica.tv.ouya.sample.game

#WITH_OUYA=apk/raw/key.der
WITH_OUYA=

# regular install
INSTALLARGS=-r
# sdcard install
#INSTALLARGS=-r -s

#CFLAGS=-isystem .
LDFLAGS=-shared -llog -landroid -lEGL -lGLESv1_CM

ANDROID_REV=android-18

TEST_OBJC=true

##############################

PLATFORM=linux
ifeq ("$(PLATFORM)","linux")
COMPILER_BIN=/tmp/my-android-toolchain/bin/

CC=$(COMPILER_BIN)clang
CXX=$(COMPILER_BIN)clang++
JAVA_BIN=/usr/bin

ANDROID_SDK=/root/android-sdk-linux
ANDROID_SDK_WIN=${ANDROID_SDK}
AAPT=$(ANDROID_SDK)/build-tools/19.0.1/aapt
ADB=$(ANDROID_SDK)/platform-tools/adb
# -s emulator-5556
DX=$(ANDROID_SDK)/build-tools/19.0.1/dx

PROJECT_PATH_WIN=`pwd`

JARSIGNER="$(JAVA_BIN)"/jarsigner
KEYTOOL="$(JAVA_BIN)"/keytool
JAVAC="$(JAVA_BIN)"/javac

endif
ifeq ("$(PLATFORM)","windows")
COMPILER_BIN=$(shell cygpath -u `cygpath -w android-sdk`)/../compiler/bin/

CC=$(COMPILER_BIN)arm-linux-androideabi-gcc
CXX=$(COMPILER_BIN)arm-linux-androideabi-g++
JAVA_BIN=/cygdrive/c/Program Files (x86)/Java/jdk1.7.0_25/bin

#ANDROID_SDK_PATH=Path/To/AndroidSDK/On/F/Drive
#ANDROID_SDK=/cygdrive/f/$(ANDROID_SDK_PATH)
#ANDROID_SDK_WIN=F:/$(ANDROID_SDK_PATH)
ANDROID_SDK=$(shell cygpath -u `cygpath -w android-sdk`) # android-sdk is a symlink
ANDROID_SDK_WIN=$(shell cygpath -w android-sdk | sed 's_\\_/_g')

PROJECT_PATH_WIN=$(shell cygpath -w `pwd` | sed 's_\\_/_g')

AAPT=$(ANDROID_SDK)/build-tools/17.0.0/aapt.exe
ADB=$(ANDROID_SDK)/platform-tools/adb.exe
# -s emulator-5556
DX=$(ANDROID_SDK)/build-tools/17.0.0/dx.bat

JARSIGNER="$(JAVA_BIN)"/jarsigner.exe
KEYTOOL="$(JAVA_BIN)"/keytool.exe
JAVAC="$(JAVA_BIN)"/javac.exe
endif

ANDROID_JAR=$(ANDROID_SDK_WIN)/platforms/$(ANDROID_REV)/android.jar
AAPT_PACK=$(AAPT) package -v -f -I $(ANDROID_JAR)

#####################################

CFLAGS += -I $(COMPILER_BIN)/../include

#CP_SO=cp
CP_SO=$(COMPILER_BIN)/arm-linux-androideabi-objcopy -S 

ifeq ($(TEST_OBJC),true)
CFLAGS += -x objective-c $(shell gnustep-config --objc-flags) # testing objc
LDFLAGS += $(shell gnustep-config --base-libs)
FOUNDATION_COPY = $(CP_SO) $(shell gnustep-config --variable=GNUSTEP_LOCAL_LIBRARIES)/libgnustep-base.so.1.*.* apk/lib/armeabi/libgnustep-base.so
OBJC_COPY = $(CP_SO) $(shell gnustep-config --variable=GNUSTEP_LOCAL_LIBRARIES)/libobjc.so.*.* apk/lib/armeabi/libobjc.so
#DEP_PATCHELF = patchelf/src/patchelf
#BUILD_PATCHELF = cd patchelf && ./bootstrap.sh && ./configure && make
#FOUNDATION_PATCHELF = ./patchelf/src/patchelf --remove-needed libobjc.so.4.6 apk/lib/armeabi/libgnustep-base.so
#TGE_PATCHELF = ./patchelf/src/patchelf --remove-needed libobjc.so.4.6 apk/lib/armeabi/lib$(APKNAME).so
DEP_PATCHELF = patchelf_dummy
BUILD_PATCHELF = @echo Not building patchelf
TGE_PATCHELF = 

# instead of rpl to replace .4.6 with null, we should do this: 
# http://www.opengis.ch/2011/11/23/creating-non-versioned-shared-libraries-for-android/
RPL = rpl -R -e libobjc.so.4.6 "libobjc.so\x00\x00\x00\x00" apk/lib/armeabi/

JAVA_CLASS = TGENativeActivity

else
FOUNDATION_COPY = 
OBJC_COPY =
DEP_PATCHELF = patchelf_dummy
BUILD_PATCHELF = @echo Not building patchelf
FOUNDATION_PATCHELF = 
TGE_PATCHELF = 
RPL =

JAVA_CLASS = DummyClass
endif

all: $(APKNAME).apk

install: $(APKNAME).apk
	$(ADB) install $(INSTALLARGS) $(APKNAME).apk
uninstall:
	$(ADB) uninstall $(IDENTIFIER)

lib$(APKNAME).so: TheGrandExperiment.o android_native_app_glue.o
	$(CC) $(LDFLAGS) TheGrandExperiment.o android_native_app_glue.o -o lib$(APKNAME).so

$(DEP_PATCHELF):
	$(BUILD_PATCHELF)

$(APKNAME).unsigned.apk: lib$(APKNAME).so classes.dex AndroidManifest.xml $(DEP_PATCHELF)
	rm -rf apk/
	rm -rf gen
	mkdir apk/
	mkdir gen/
	mkdir -p apk/lib/armeabi/

	$(CP_SO) lib$(APKNAME).so apk/lib/armeabi/lib$(APKNAME).so
	$(FOUNDATION_COPY)
	$(OBJC_COPY)

	$(FOUNDATION_PATCHELF)
	$(TGE_PATCHELF)

	$(RPL)

	cp classes.dex apk/
ifdef WITH_OUYA
	mkdir -p `dirname "$(WITH_OUYA)"`
	cp ouya/key.der "$(WITH_OUYA)"
endif
	$(AAPT_PACK) -M AndroidManifest.xml -S res -A assets -m -J gen -F $(APKNAME).unsigned.apk apk

$(APKNAME).apk: $(APKNAME).unsigned.apk $(KEYSTORE)
	$(JARSIGNER) -keystore $(KEYSTORE) -storepass $(STOREPASS) -keypass $(KEYPASS) -signedjar $(APKNAME).apk $(APKNAME).unsigned.apk "$(KEYNAME)" -sigalg MD5withRSA -digestalg SHA1


$(KEYSTORE):
	$(KEYTOOL) -genkey -v -keystore "$(KEYSTORE)" -alias "$(KEYNAME)" -keyalg RSA -keysize 2048 -validity 10000 -storepass "$(STOREPASS)" -keypass "$(KEYPASS)" -dname "$(DNAME)" -sigalg MD5withRSA

classes.dex: classes/net/vucica/tv/ouya/sample/game/$(JAVA_CLASS).class
	$(DX) --dex --output=$(PROJECT_PATH_WIN)/classes.dex --verbose $(PROJECT_PATH_WIN)/classes

classes/net/vucica/tv/ouya/sample/game/$(JAVA_CLASS).class: $(JAVA_CLASS).java
	mkdir -p classes/net/vucica/tv/ouya/sample/game/
	$(JAVAC) -bootclasspath $(ANDROID_JAR) -d classes/ $(JAVA_CLASS).java -source 1.6 -target 1.6

clean:
	-rm *.o
	-rm lib$(APKNAME).so
	-rm $(APKNAME).apk
	-rm $(APKNAME).unsigned.apk
	-rm -rf apk/
	-rm -rf gen
	-rm -rf classes
	-rm classes.dex
distclean: clean
	-rm $(KEYSTORE)

run:
	$(ADB) shell am start -n $(IDENTIFIER)/android.app.NativeActivity

nginx: /usr/share/nginx/www/$(APKNAME).apk
/usr/share/nginx/www/$(APKNAME).apk: $(APKNAME).apk
	cp $(APKNAME).apk /usr/share/nginx/www/
	

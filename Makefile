#COMPILER_BIN=
COMPILER_BIN=$(shell cygpath -u `cygpath -w android-sdk`)/../compiler/bin/

#CC=$(COMPILER_BIN)clang
#CXX=$(COMPILER_BIN)clang++
CC=$(COMPILER_BIN)arm-linux-androideabi-gcc
CXX=$(COMPILER_BIN)arm-linux-androideabi-g++
CFLAGS=-isystem .
LDFLAGS=-shared -llog -landroid -lEGL -lGLESv1_CM
JAVA_BIN=/cygdrive/c/Program Files (x86)/Java/jdk1.7.0_25/bin

KEYSTORE=TheKeyStore.jks
KEYNAME=TheReleaseKeyName
STOREPASS=TheStorePassword
KEYPASS=TheKeyPassword
DNAME=CN=Hermann Digimon, OU=Software Building Department, O=Big Company ltd., L=Sometown, S=Somewhere, C=HR

#ANDROID_SDK_PATH=Path/To/AndroidSDK/On/F/Drive
#ANDROID_SDK=/cygdrive/f/$(ANDROID_SDK_PATH)
#ANDROID_SDK_WIN=F:/$(ANDROID_SDK_PATH)
ANDROID_SDK=$(shell cygpath -u `cygpath -w android-sdk`)
ANDROID_SDK_WIN=$(shell cygpath -w android-sdk | sed 's_\\_/_g')
ANDROID_REV=android-14
ANDROID_JAR=$(ANDROID_SDK_WIN)/platforms/$(ANDROID_REV)/android.jar
AAPT=$(ANDROID_SDK)/build-tools/17.0.0/aapt.exe
AAPT_PACK=$(AAPT) package -v -f -I $(ANDROID_JAR)
ADB=$(ANDROID_SDK)/platform-tools/adb
# -s emulator-5556
DX=$(ANDROID_SDK)/build-tools/17.0.0/dx.bat

APKNAME=TheGrandExperiment
IDENTIFIER=net.vucica.tv.ouya.sample.game

#WITH_OUYA=apk/raw/key.der
WITH_OUYA=

# regular install
INSTALLARGS=-r
# sdcard install
#INSTALLARGS=-r -s

PROJECT_PATH_WIN=$(shell cygpath -w `pwd` | sed 's_\\_/_g')

all: $(APKNAME).apk

install: $(APKNAME).apk
	$(ADB) install $(INSTALLARGS) $(APKNAME).apk
uninstall:
	$(ADB) uninstall $(IDENTIFIER)

lib$(APKNAME).so: TheGrandExperiment.o android_native_app_glue.o
	$(CC) $(LDFLAGS) TheGrandExperiment.o android_native_app_glue.o -o lib$(APKNAME).so

$(APKNAME).unsigned.apk: lib$(APKNAME).so classes.dex AndroidManifest.xml
	rm -rf apk/
	rm -rf gen
	mkdir apk/
	mkdir gen/
	mkdir -p apk/lib/armeabi/
	cp lib$(APKNAME).so apk/lib/armeabi
	cp classes.dex apk/
ifdef WITH_OUYA
	mkdir -p `dirname "$(WITH_OUYA)"`
	cp ouya/key.der "$(WITH_OUYA)"
endif
	$(AAPT_PACK) -M AndroidManifest.xml -S res -A assets -m -J gen -F $(APKNAME).unsigned.apk apk

$(APKNAME).apk: $(APKNAME).unsigned.apk $(KEYSTORE)
	"$(JAVA_BIN)"/jarsigner.exe -keystore $(KEYSTORE) -storepass $(STOREPASS) -keypass $(KEYPASS) -signedjar $(APKNAME).apk $(APKNAME).unsigned.apk "$(KEYNAME)" -sigalg MD5withRSA -digestalg SHA1


$(KEYSTORE):
	"$(JAVA_BIN)"/keytool.exe -genkey -v -keystore "$(KEYSTORE)" -alias "$(KEYNAME)" -keyalg RSA -keysize 2048 -validity 10000 -storepass "$(STOREPASS)" -keypass "$(KEYPASS)" -dname "$(DNAME)" -sigalg MD5withRSA

classes.dex: classes/DummyClass.class
	$(DX) --dex --output=$(PROJECT_PATH_WIN)/classes.dex --verbose $(PROJECT_PATH_WIN)/classes

classes/DummyClass.class: DummyClass.java
	mkdir -p classes/
	"$(JAVA_BIN)"/javac.exe -bootclasspath $(ANDROID_JAR) -d classes/ DummyClass.java -source 1.6 -target 1.6

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


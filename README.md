TheGrandExperiment
==================

This is an exercise in building Android native activities with GNU Make.
And it's the smallest possible project I could come up with.

Windows
-------

Expectations to build out of the box:

* build with cygwin
* build on windows
* have JDK in `/cygdrive/c/Program Files (x86)/Java/jdk1.7.0_25/bin`
* create a symlink to your Android SDK and call it `[root]/android-sdk`
* bootstrap a 'standalone' compiler in `[Path to Android SDK]/../compiler`; 
  see folder 'bootstrap/' for an example of how to do this

Any system that does not match these expectations will require slight 
changes to environment variables set up in `Makefile`. Not building on
Windows will also require changes to any rules that call Win32 binaries
such as binaries from JDK and Android SDK.

Some of the requirements are obvious hacks so I don't have to expose my
personal working environment to the world.

Ouya deployment key is obviously not included. Include your own and
set the `WITH_OUYA` variable properly.

`android_native_app_glue.c/h` are coming from 
`[android_ndk]/sources/android/native_app_glue`.

There are references to build tools version 17.0.0. There are references
to particular API revision. `PLATFORM` needs to be set to `windows`.
There may be other assumptions.

Linux
-----
Makefile now actually contains code to build under Linux, as long as:

* JDK is in `/usr/bin/`
* Android SDK is in `/root/android-sdk-linux`
* standalone NDK compiler is in `/tmp/my-android-toolchain`

Build tools are presumed to be 19.0.1. `PLATFORM` needs to be set to
`linux`. There may be other assumptions.

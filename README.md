TheGrandExperiment
==================

This is an exercise in building Android native activities with GNU Make.
And it's the smallest possible project I could come up with.

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



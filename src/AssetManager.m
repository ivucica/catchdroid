#import <jni.h>
#import <android/asset_manager_jni.h>

static AAssetManager* assetManager = NULL;
JNIEXPORT void JNICALL Java_net_vucica_catchdroid_IVNativeActivity_initAssetManager(JNIEnv * env, jclass jclazz, jobject java_asset_manager)
{
  assetManager = AAssetManager_fromJava(env, java_asset_manager);
}

@implementation AssetManager
+(AAssetManager*)assetManager
{
  return assetManager;
}
@end


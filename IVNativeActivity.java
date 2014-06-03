package net.vucica.catchdroid;
import android.app.NativeActivity;

public class IVNativeActivity extends NativeActivity
{
  static
  {
    /*
    AssetManager am = applicationContext.getAssets(); 
    in = am.open(OPENSSL_SO_LIB_NAME); // source instream

    File privateStorageDir = applicationContext.getFilesDir();
    String libPath = privateStorageDir.getAbsolutePath();
    */
    System.loadLibrary("objc");
    System.loadLibrary("gnustep-base");
    System.loadLibrary("CatchDroid");
  }

}

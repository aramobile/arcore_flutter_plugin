package com.difrancescogianmarco.arcore_flutter_plugin.utils

import java.io.File
import java.io.OutputStream
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import android.content.pm.PackageManager
import android.view.PixelCopy
import android.os.Handler
import android.Manifest
import android.graphics.Bitmap
import android.app.Activity
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import com.google.ar.sceneform.ArSceneView

class ScreenshotsUtils {

    companion object {

        private fun getPictureName(): String {

            val sDate: String = SimpleDateFormat("yyyyMMddHHmmss").format(Date())

            return "arcore-$sDate.png"
        }


        private fun saveBitmap(bitmap: Bitmap, activity: Activity): String {

            val cacheDir = activity.cacheDir

            val file = File(cacheDir, getPictureName())

            try{

                // Get the file output stream
                val stream: OutputStream = FileOutputStream(file)

                // Compress bitmap
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)

                // Flush the stream
                stream.flush()

                // Close stream
                stream.close()


            }catch (e: Exception){
                e.printStackTrace()
            }

            return file.absolutePath


        }

        private fun permissionToWrite(activity: Activity): Boolean {

            val perm = activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE)

            if(perm == PackageManager.PERMISSION_GRANTED) {
                Log.i("Sreenshot", "Permission to write granted!")

                return true
            }

            Log.i("Sreenshot","Requesting permissions...")
            activity.requestPermissions(
                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                11
            )
            Log.i("Sreenshot", "No permissions :(")

            return false
        } 


        fun onGetSnapshot(arSceneView: ArSceneView?, result: MethodChannel.Result,activity: Activity){

            if( !permissionToWrite(activity) ) {
                Log.i("Sreenshot", "Permission to write files missing!")

                result.success(null)

                return
            }

            if(arSceneView == null){
                Log.i("Sreenshot", "Ar Scene View is NULL!")

                result.success(null)

                return
            }
     
           
            try {

                val bitmapImage: Bitmap = Bitmap.createBitmap(
                    arSceneView.width,
                    arSceneView.height,
                    Bitmap.Config.ARGB_8888
                )
                Log.i("Sreenshot", "PixelCopy requesting now...")
                PixelCopy.request(
                    arSceneView, bitmapImage, { copyResult ->
                        if (copyResult == PixelCopy.SUCCESS) {
                            Log.i("Sreenshot", "PixelCopy request SUCESS. $copyResult")

                            val pathSaved: String = saveBitmap(bitmapImage, activity)

                            Log.i("Sreenshot", "Saved on path: $pathSaved")
                            result.success(pathSaved)

                        } else {
                            Log.i("Sreenshot", "PixelCopy request failed. $copyResult")
                            result.success(null)
                        }

                    },
                    Handler()
                )

            } catch (e: Exception){

                e.printStackTrace()
            }
            
            
        }
    }
}
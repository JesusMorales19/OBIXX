package com.example.integradora

import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.obix.app/media_store"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanFile" -> {
                    val filePath = call.argument<String>("filePath")
                    val mimeType = call.argument<String>("mimeType") ?: "application/pdf"
                    
                    if (filePath != null) {
                        try {
                            registerFileInDownloadManager(filePath, mimeType)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", "Error al registrar archivo: ${e.message}", null)
                        }
                    } else {
                        result.error("ERROR", "Ruta de archivo no proporcionada", null)
                    }
                }
                "openFile" -> {
                    val filePath = call.argument<String>("filePath")
                    val mimeType = call.argument<String>("mimeType") ?: "application/pdf"
                    
                    if (filePath != null) {
                        try {
                            openFile(filePath, mimeType)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", "Error al abrir archivo: ${e.message}", null)
                        }
                    } else {
                        result.error("ERROR", "Ruta de archivo no proporcionada", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun registerFileInDownloadManager(filePath: String, mimeType: String) {
        val file = File(filePath)
        if (!file.exists()) {
            throw Exception("El archivo no existe: $filePath")
        }

        // Registrar el archivo en el MediaStore para que aparezca en las descargas
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10+ (API 29+)
            val contentValues = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, file.name)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Downloads.SIZE, file.length())
            }
            contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
        } else {
            // Android 9 y anteriores - escanear el archivo
            val mediaScanIntent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
            val contentUri = Uri.fromFile(file)
            mediaScanIntent.data = contentUri
            sendBroadcast(mediaScanIntent)
        }

        // Usar DownloadManager para mostrar la notificación nativa
        val downloadManager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val request = DownloadManager.Request(Uri.fromFile(file)).apply {
            setTitle(file.name)
            setDescription("Nómina descargada")
            setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, file.name)
            setMimeType(mimeType)
        }
        
        // Registrar en el DownloadManager (esto mostrará la notificación)
        val downloadId = downloadManager.enqueue(request)
        
        // Escuchar cuando se complete para abrir el archivo
        val onComplete = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val id = intent?.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1)
                if (id == downloadId) {
                    val query = DownloadManager.Query().setFilterById(downloadId)
                    val cursor = downloadManager.query(query)
                    if (cursor.moveToFirst()) {
                        val status = cursor.getInt(cursor.getColumnIndex(DownloadManager.COLUMN_STATUS))
                        if (status == DownloadManager.STATUS_SUCCESSFUL) {
                            val uri = downloadManager.getUriForDownloadedFile(downloadId)
                            uri?.let {
                                val openIntent = Intent(Intent.ACTION_VIEW).apply {
                                    setDataAndType(it, mimeType)
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                                }
                                startActivity(openIntent)
                            }
                        }
                    }
                    cursor.close()
                    unregisterReceiver(this)
                }
            }
        }
        registerReceiver(onComplete, IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE))
    }

    private fun openFile(filePath: String, mimeType: String) {
        val file = File(filePath)
        if (!file.exists()) {
            throw Exception("El archivo no existe: $filePath")
        }

        val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            // Android 7.0+ (API 24+) - usar FileProvider
            val authority = "${applicationContext.packageName}.fileprovider"
            androidx.core.content.FileProvider.getUriForFile(
                applicationContext,
                authority,
                file
            )
        } else {
            // Android 6.0 y anteriores
            Uri.fromFile(file)
        }

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mimeType)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        try {
            startActivity(Intent.createChooser(intent, "Abrir PDF con"))
        } catch (e: Exception) {
            throw Exception("No se pudo abrir el archivo: ${e.message}")
        }
    }
}

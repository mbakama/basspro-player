package com.example.basspro_player

import android.content.ContentUris
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.basspro_player/mediastore"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "queryAudioFiles" -> {
                    try {
                        val audioFiles = queryAudioFiles()
                        result.success(audioFiles)
                    } catch (e: Exception) {
                        result.error("QUERY_ERROR", "Failed to query audio files: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun queryAudioFiles(): List<Map<String, Any?>> {
        val audioFiles = mutableListOf<Map<String, Any?>>()
        
        // Define the columns we want to retrieve
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.DATE_ADDED
        )
        
        // Query only music files (exclude notifications, ringtones, etc.)
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"
        
        // Sort by title
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"
        
        // Query the MediaStore
        val cursor: Cursor? = contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            null,
            sortOrder
        )
        
        cursor?.use {
            val idColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val durationColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val dataColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val albumIdColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
            val dateAddedColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)
            
            while (it.moveToNext()) {
                val id = it.getLong(idColumn)
                val title = it.getString(titleColumn) ?: "Unknown"
                val artist = it.getString(artistColumn) ?: "Unknown Artist"
                val album = it.getString(albumColumn) ?: "Unknown Album"
                val duration = it.getLong(durationColumn)
                val data = it.getString(dataColumn)
                val albumId = it.getLong(albumIdColumn)
                val dateAdded = it.getLong(dateAddedColumn)
                
                // Build content URI for the audio file
                val contentUri = ContentUris.withAppendedId(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    id
                )
                
                // Build artwork URI from album ID
                val artworkUri = ContentUris.withAppendedId(
                    Uri.parse("content://media/external/audio/albumart"),
                    albumId
                )
                
                val audioFile = mapOf(
                    "id" to id,
                    "title" to title,
                    "artist" to artist,
                    "album" to album,
                    "duration" to duration,
                    "uri" to contentUri.toString(),
                    "artworkUri" to artworkUri.toString(),
                    "dateAdded" to dateAdded * 1000 // Convert to milliseconds
                )
                
                audioFiles.add(audioFile)
            }
        }
        
        return audioFiles
    }
}

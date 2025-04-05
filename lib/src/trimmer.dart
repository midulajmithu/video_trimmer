import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/src/utils/file_formats.dart';
import 'package:video_trimmer/src/utils/storage_dir.dart';

enum TrimmerEvent { initialized }

class Trimmer {
  final StreamController<TrimmerEvent> _controller =
      StreamController<TrimmerEvent>.broadcast();

  VideoPlayerController? _videoPlayerController;
  VideoPlayerController? get videoPlayerController => _videoPlayerController;

  File? currentVideoFile;

  Stream<TrimmerEvent> get eventStream => _controller.stream;

  Future<void> loadVideo({required File videoFile}) async {
    currentVideoFile = videoFile;
    if (videoFile.existsSync()) {
      _videoPlayerController = VideoPlayerController.file(currentVideoFile!);
      await _videoPlayerController!.initialize().then((_) {
        _controller.add(TrimmerEvent.initialized);
      });
    }
  }

  Future<String> _createFolderInAppDocDir(
    String folderName,
    StorageDir? storageDir,
  ) async {
    Directory? directory;

    if (storageDir == null) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      switch (storageDir.toString()) {
        case 'temporaryDirectory':
          directory = await getTemporaryDirectory();
          break;
        case 'applicationDocumentsDirectory':
          directory = await getApplicationDocumentsDirectory();
          break;
        case 'externalStorageDirectory':
          directory = await getExternalStorageDirectory();
          break;
      }
    }

    final Directory directoryFolder =
        Directory('${directory!.path}/$folderName/');

    if (await directoryFolder.exists()) {
      return directoryFolder.path;
    } else {
      final Directory directoryNewFolder =
          await directoryFolder.create(recursive: true);
      return directoryNewFolder.path;
    }
  }

  /// Dummy save — just returns the original file path
  Future<void> saveTrimmedVideo({
    required double startValue,
    required double endValue,
    required Function(String? outputPath) onSave,
    bool applyVideoEncoding = false,
    FileFormat? outputFormat,
    String? ffmpegCommand,
    String? customVideoFormat,
    int? fpsGIF,
    int? scaleGIF,
    String? videoFolderName,
    String? videoFileName,
    StorageDir? storageDir,
  }) async {
    // NOTE: Real trimming is disabled, we just return the original file path.
    debugPrint(
        "⚠️ FFmpeg has been removed. Returning the original video file path.");
    onSave(currentVideoFile?.path);
  }

  Future<bool> videoPlaybackControl({
    required double startValue,
    required double endValue,
  }) async {
    if (videoPlayerController!.value.isPlaying) {
      await videoPlayerController!.pause();
      return false;
    } else {
      if (videoPlayerController!.value.position.inMilliseconds >=
          endValue.toInt()) {
        await videoPlayerController!
            .seekTo(Duration(milliseconds: startValue.toInt()));
        await videoPlayerController!.play();
        return true;
      } else {
        await videoPlayerController!.play();
        return true;
      }
    }
  }

  void dispose() {
    _controller.close();
  }
}

import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Formats a [Duration] object to a human-readable string.
///
/// Example:
/// ```dart
/// final duration = Duration(hours: 1, minutes: 30, seconds: 15);
/// print(_formatDuration(duration)); // Output: 01:30:15
/// ```
String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hours = twoDigits(duration.inHours);
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return '$hours:$minutes:$seconds';
}

/// Generates a stream of thumbnails for a given video.
///
/// This function generates a specified number of thumbnails for a video at
/// different timestamps and yields them as a stream of lists of byte arrays.
/// The thumbnails are generated using the `video_thumbnail` package.
///
/// Parameters:
/// - `videoPath` (required): The path to the video file.
/// - `videoDuration` (required): The duration of the video in milliseconds.
/// - `numberOfThumbnails` (required): The number of thumbnails to generate.
/// - `quality` (required): The quality of the thumbnails (percentage).
/// - `onThumbnailLoadingComplete` (required): A callback function that is
///   called when all thumbnails have been generated.
///
/// Returns:
/// A stream of lists of byte arrays, where each list contains the generated
/// thumbnails up to that point.
///
/// Example usage:
/// ```dart
/// final thumbnailStream = generateThumbnail(
///   videoPath: 'path/to/video.mp4',
///   videoDuration: 60000, // 1 minute
///   numberOfThumbnails: 10,
///   quality: 50,
///   onThumbnailLoadingComplete: () {
///     print('Thumbnails generated successfully!');
///   },
/// );
///
/// await for (final thumbnails in thumbnailStream) {
///   // Process the thumbnails
/// }
/// ```
///
/// Throws:
/// An error if the thumbnails could not be generated.
Stream<List<Uint8List?>> generateThumbnail({
  required String videoPath,
  required int videoDuration,
  required int numberOfThumbnails,
  required int quality,
  required VoidCallback onThumbnailLoadingComplete,
}) async* {
  final double eachPart = videoDuration / numberOfThumbnails;

  final List<Uint8List?> thumbnailBytes = [];
  Uint8List? lastBytes;

  log('Generating thumbnails for video: $videoPath');
  log('Total thumbnails to generate: $numberOfThumbnails');
  log('Quality: $quality%');
  log('Generating thumbnails...');
  log('---------------------------------');

  try {
    for (int i = 1; i <= numberOfThumbnails; i++) {
      log('Generating thumbnail $i / $numberOfThumbnails');

      final timestamp = (eachPart * i).toInt();
      final formattedTimestamp =
          _formatDuration(Duration(milliseconds: timestamp));

      Uint8List? bytes = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 180, // You can customize this
        quality: quality,
        timeMs: timestamp,
      );

      if (bytes != null) {
        log('Timestamp: $formattedTimestamp | Size: ${(bytes.length / 1000).toStringAsFixed(2)} kB');
        log('---------------------------------');
        lastBytes = bytes;
      } else {
        bytes = lastBytes; // Use the previous thumbnail if current fails
      }

      thumbnailBytes.add(bytes);

      if (thumbnailBytes.length == numberOfThumbnails) {
        onThumbnailLoadingComplete();
      }

      yield thumbnailBytes;
    }

    log('Thumbnails generated successfully!');
  } catch (e) {
    log('ERROR: Couldn\'t generate thumbnails: $e');
  }
}

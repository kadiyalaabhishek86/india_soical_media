import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/api_endpoints.dart';

VideoPlayerController createVideoControllerForXFile(XFile file) {
  return VideoPlayerController.file(File(file.path));
}

VideoPlayerController createVideoControllerForUrlOrPath(String urlOrPath) {
  final trimmed = urlOrPath.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return VideoPlayerController.networkUrl(Uri.parse(trimmed));
  } else if (trimmed.startsWith('/')) {
    final full = '${ApiEndpoints.rootUrl}$trimmed';
    return VideoPlayerController.networkUrl(Uri.parse(full));
  } else if (trimmed.startsWith('file://')) {
    return VideoPlayerController.file(File(Uri.parse(trimmed).toFilePath()));
  } else {
    return VideoPlayerController.file(File(trimmed));
  }
}

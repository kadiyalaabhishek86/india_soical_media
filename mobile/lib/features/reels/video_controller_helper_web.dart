import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/api_endpoints.dart';

VideoPlayerController createVideoControllerForXFile(XFile file) {
  return VideoPlayerController.networkUrl(Uri.parse(file.path));
}

VideoPlayerController createVideoControllerForUrlOrPath(String urlOrPath) {
  final trimmed = urlOrPath.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://') || trimmed.startsWith('blob:')) {
    return VideoPlayerController.networkUrl(Uri.parse(trimmed));
  } else if (trimmed.startsWith('/')) {
    final full = '${ApiEndpoints.rootUrl}$trimmed';
    return VideoPlayerController.networkUrl(Uri.parse(full));
  } else {
    return VideoPlayerController.networkUrl(Uri.parse(trimmed));
  }
}

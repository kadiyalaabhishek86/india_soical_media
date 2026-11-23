export 'video_controller_helper_io.dart'
    if (dart.library.html) 'video_controller_helper_web.dart'
    if (dart.library.js_interop) 'video_controller_helper_web.dart';

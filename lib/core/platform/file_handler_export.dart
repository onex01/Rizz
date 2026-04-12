import 'file_handler.dart';
export 'file_handler.dart';

import 'file_handler_stub.dart'
    if (dart.library.html) 'file_handler_web.dart'
    if (dart.library.io) 'file_handler_native.dart';

FileHandler getFileHandler() => createFileHandler();
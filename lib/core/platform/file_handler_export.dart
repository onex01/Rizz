import 'file_handler_stub.dart'
    if (dart.library.html) 'file_handler_web.dart'
    if (dart.library.io) 'file_handler_native.dart';

export 'file_handler.dart';
FileHandler getFileHandler() => createFileHandler();
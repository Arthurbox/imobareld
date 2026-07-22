import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

final Logger appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0, 
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    printTime: false,
  ),
  level: kDebugMode ? Level.trace : Level.off, 
);

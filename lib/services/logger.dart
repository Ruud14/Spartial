import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';

/// Service for logging error and info messages.
class Logger {
  /// The maximum number of logs in the log storage.
  static const int maxErrorLogEntries = 50;
  static const int maxInfoLogEntries = 50;

  /// Prefix of log message.
  static const String errorPrefix = "[Error]";
  static const String infoPrefix = "[Info]";

  /// The maximum number of similar logs in a row.
  static const int maxContinuousSimilarErrorLogs = 3;
  static const int maxContinuousSimilarInfoLogs = 3;

  /// Storages.
  static var errorLog;
  static var infoLog;

  /// Whether the logs will be printed.
  static const bool printLogs = false;

  /// Temp.
  static Exception lastError = Exception();
  static String lastInfo = "";
  static int similarErrorLogCounter = 0;
  static int similarInfoLogCounter = 0;

  /// Opens the hive error box if it isn't open already.
  static Future<void> _openErrorBoxIfNotOpen() async {
    if (!Hive.isBoxOpen('error') || errorLog == null) {
      await Hive.openBox<String>('error');
      errorLog = Hive.box<String>('error');
    }
  }

  /// Opens the hive info box if it isn't open already.
  static Future<void> _openInfoBoxIfNotOpen() async {
    if (!Hive.isBoxOpen('info') || infoLog == null) {
      await Hive.openBox<String>('info');
      infoLog = Hive.box<String>('info');
    }
  }

  /// Logs an exception.
  static Future<void> error(Exception e) async {
    // Check if we haven't had too many similar error logs in a row.
    if (e.toString() == lastError.toString()) {
      similarErrorLogCounter += 1;
      if (similarErrorLogCounter > maxContinuousSimilarErrorLogs) {
        return;
      }
    } else {
      lastError = e;
      similarErrorLogCounter = 1;
    }
    // Open the hive error box if it isn't open already.
    await _openErrorBoxIfNotOpen();
    // Remove the first entry if the log is getting full.
    List keys = List.from(errorLog.keys);
    keys.sort();
    if (keys.length > maxErrorLogEntries) {
      errorLog.delete(keys[0]);
    }
    // Put the error log in log storage.
    DateTime time = DateTime.now();
    String value = errorPrefix +
        "[${time.year}-${time.month}-${time.day} ${time.hour}:${time.minute}:${time.second}]" +
        e.toString();
    errorLog.put(time.microsecondsSinceEpoch.toString(), value);
    // Print the log.
    if (printLogs) {
      print(value);
    }
  }

  /// Logs in info String.
  static Future<void> info(String s) async {
    // Check if we haven't had too many similar info logs in a row.
    if (s == lastInfo) {
      similarInfoLogCounter += 1;
      if (similarInfoLogCounter > maxContinuousSimilarInfoLogs) {
        return;
      }
    } else {
      lastInfo = s;
      similarInfoLogCounter = 1;
    }

    // Open the hive info box if it isn't open already.
    await _openInfoBoxIfNotOpen();

    // Remove the first entry if the log is getting full.
    List keys = List.from(infoLog.keys);
    keys.sort();
    if (keys.length > maxInfoLogEntries) {
      infoLog.delete(keys[0]);
    }
    // Put the info log in log storage.
    DateTime time = DateTime.now();
    String value = infoPrefix +
        "[${time.year}-${time.month}-${time.day} ${time.hour}:${time.minute}:${time.second}]" +
        s;
    infoLog.put(time.microsecondsSinceEpoch.toString(), value);
    // Print the log.
    if (printLogs) {
      print(value);
    }
  }

  /// Gets all the error logs.
  static Future<List<String>> getErrorLogs() async {
    await _openErrorBoxIfNotOpen();
    return List<String>.from(errorLog.values);
  }

  /// Gets all the info logs.
  static Future<List<String>> getInfoLogs() async {
    await _openInfoBoxIfNotOpen();
    return List<String>.from(infoLog.values);
  }

  /// Clears the error logs.
  static void clearErrorLogs() {
    errorLog.clear();
  }

  /// Clears the error logs.
  static void clearInfoLogs() {
    infoLog.clear();
  }

  /// Share the error logs.
  static void shareErrorLogs() async {
    List<String> logs = await getErrorLogs();
    if (logs.isEmpty) {
      return;
    }
    String logsString = logs.join("\n");
    Share.share(logsString);
  }

  /// Share the info logs.
  static void shareInfoLogs() async {
    List<String> logs = await getInfoLogs();
    if (logs.isEmpty) {
      return;
    }
    String logsString = logs.join("\n");
    Share.share(logsString);
  }
}

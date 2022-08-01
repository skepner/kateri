import 'package:universal_platform/universal_platform.dart';

// ----------------------------------------------------------------------

class FormatError extends FormatException {
  FormatError(String message) : super(message) {
    error("[FormatError]: $message", stackLevel: 3);
  }
}

// ----------------------------------------------------------------------

class DataError extends FormatException {
  DataError(String message) : super(message) {
    error("[DataError]: $message", stackLevel: 3);
  }
}

// ----------------------------------------------------------------------

String currentFilenameLineColumn(int stackLevel) {
  var re = UniversalPlatform.isMacOS ? RegExp('^#$stackLevel[ \\t]+.+\\(([^\\)]+)\\)\$', multiLine: true) : RegExp('[ \\t]currentFilenameLineColumn\\n.+\\npackages/([^ ]+) ([0-9:]+)', multiLine: true);
  try {
    final match = re.firstMatch(StackTrace.current.toString());
    switch (match?.groupCount) {
      case 1:
        return match!.group(1) ?? "re[no-group-1]";
      case 2:
        return "package:${match!.group(1) ?? 're[no-group-1]'}:${match.group(2) ?? 're[no-group-2]'}";
      default:
        return "re[no-match]\n$re\n${StackTrace.current}";
    }
  } catch (err) {
    return "re[$err]";
  }
}

// String currentFilenameLineColumnSuffix(int stackLevel) {
//   if (UniversalPlatform.isMacOS) {
//     return " [${currentFilenameLineColumn(stackLevel + 1)}]";
//   } else {
//     print(StackTrace.current.toString());
//     return "";
//   }
// }

// void print_debug(String message) {
//   print("$message [${currentFilenameLineColumn()}]");
// }

void error(String message, {int stackLevel = 2}) {
  print("> ERROR $message [${currentFilenameLineColumn(stackLevel)}]");
}

void warning(String message, {int stackLevel = 2}) {
  print(">> $message [${currentFilenameLineColumn(stackLevel)}]");
}

void info(String message, {int stackLevel = 2}) {
  print(">>> $message [${currentFilenameLineColumn(stackLevel)}]");
}

void debug(String message, {int stackLevel = 2}) {
  print(">>>> $message [${currentFilenameLineColumn(stackLevel)}]");
}

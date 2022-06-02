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

String currentFilenameLineColumn([int stackLevel = 2]) {
  try {
    final re = RegExp('^#${stackLevel}[ \\t]+.+\\(([^\\)]+)\\)\$', multiLine: true);
    final match = re.firstMatch(StackTrace.current.toString());
    if (match != null) {
      return match.group(1) ?? "re[no-group]";
    } else {
      return "re[no-match]\n$re\n${StackTrace.current}";
    }
  } catch (err) {
    return "re[$err]";
  }
}

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

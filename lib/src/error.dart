class FormatError extends FormatException {
  FormatError(String message) : super(message) {
    print("> ERROR [FormatError]: $message");
  }
}

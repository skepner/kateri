import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:brotli/brotli.dart';

// ----------------------------------------------------------------------

List<int> decompress(List<int> source) {
  try {
    return brotliDecode(source);
  } catch (_) {
    print("[not brotli]: $_");
  }

  try {
    return XZDecoder().decodeBytes(source);
  } catch (_) {
    print("[not xz]: $_");
  }

  try {
    return BZip2Decoder().decodeBytes(source);
  } catch (_) {
    print("[not bz2]: $_");
  }

  try {
    return GZipDecoder().decodeBytes(source);
  } catch (_) {
    print("[not gzip]: $_");
  }

  print("plain text");
  return source;
}

// ----------------------------------------------------------------------

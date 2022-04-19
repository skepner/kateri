import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:brotli/brotli.dart';

// ----------------------------------------------------------------------

List<int> decompress(List<int> source) {
  try {
    return brotliDecode(source);
  } catch (_) {
    print("[not brotli (${_.runtimeType})]: $_");
  }

  try {
    return XZDecoder().decodeBytes(source);
  } catch (err) {
    if (err.toString().contains("has already been initialized.")) {
      throw const FormatException("xz decompression is not yet supported");
    }
    print("[not xz (${err.runtimeType})]: $err");
  }

  try {
    return BZip2Decoder().decodeBytes(source);
  } catch (_) {
    print("[not bz2 (${_.runtimeType})]: $_");
  }

  try {
    return GZipDecoder().decodeBytes(source);
  } catch (_) {
    print("[not gzip (${_.runtimeType})]: $_");
  }

  print("assuming plain text");
  return source;
}

// ----------------------------------------------------------------------

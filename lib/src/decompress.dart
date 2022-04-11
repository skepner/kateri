import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:brotli/brotli.dart';

// ----------------------------------------------------------------------

List<int> decompress(List<int> source) {
  try {
    return brotliDecode(source);
  }
  catch(_) {
  }

  try {
    return XZDecoder().decodeBytes(source);
  }
  catch(_) {
  }

  try {
    return BZip2Decoder().decodeBytes(source);
  }
  catch(_) {
  }

  try {
    return GZipDecoder().decodeBytes(source);
  }
  catch(_) {
  }

  return source;
}

// ----------------------------------------------------------------------

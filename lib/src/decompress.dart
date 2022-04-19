import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart' as aio;
import 'package:brotli/brotli.dart';

// ----------------------------------------------------------------------

enum Encoder { plain, xz, bz2, gzip, brotli }

final xzSignature = Uint8List.fromList([0xFD, 0x37, 0x7a, 0x58, 0x5a, 0]); // \xDF 7zXZ \x00;
final bz2Signature = Uint8List.fromList([0x42, 0x5a, 0x68]); // BZh
final gzipSignature = Uint8List.fromList([0x1F, 0x8B]);
final detectSize = xzSignature.length;

// at least 6 elements required in the source
Encoder detect(Uint8List source) {
  if (Uint8List.sublistView(source, 0, xzSignature.length) == xzSignature) {
    return Encoder.xz;
  }
  if (Uint8List.sublistView(source, 0, bz2Signature.length) == bz2Signature) {
    return Encoder.bz2;
  }
  if (Uint8List.sublistView(source, 0, gzipSignature.length) == gzipSignature) {
    return Encoder.gzip;
  }
  if (Uint8List.sublistView(source, 0, detectSize).any((char) => char > 0x7F)) {
    // non-ascii at the beginning, assume brotli
    return Encoder.brotli;
  }
  return Encoder.plain;
}

// ----------------------------------------------------------------------

Future<List<int>> decompressFile(String path) async {
  final fd = await File(path).open();
  final bytes = await fd.read(detectSize);
  switch (detect(bytes)) {
    case Encoder.plain:
      return File(path).readAsBytes();
    case Encoder.xz:
      return aio.XZDecoder().decodeBuffer(aio.InputFileStream(path));
    case Encoder.bz2:
      return aio.BZip2Decoder().decodeBuffer(aio.InputFileStream(path));
    case Encoder.gzip:
      return aio.GZipDecoder().decodeBuffer(aio.InputFileStream(path));
    case Encoder.brotli:
      return brotliDecode(await File(path).readAsBytes());
  }
}

// ----------------------------------------------------------------------

List<int> decompressBytes(Uint8List source) {
  switch (detect(source)) {
    case Encoder.plain:
      return source;
    case Encoder.xz:
      return XZDecoder().decodeBytes(source);
    case Encoder.bz2:
      return BZip2Decoder().decodeBytes(source);
    case Encoder.gzip:
      return GZipDecoder().decodeBytes(source);
    case Encoder.brotli:
      return brotliDecode(source);
  }
  // return source;
}

// ----------------------------------------------------------------------

Future<List<int>> decompressStdin() async {
  final data = <int>[];
  await for (final chunk in stdin) {
    data.addAll(chunk);
  }
  return decompressBytes(Uint8List.fromList(data));
}

// ----------------------------------------------------------------------

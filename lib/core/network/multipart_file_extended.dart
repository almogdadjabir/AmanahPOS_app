import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

/// A subclass of [MultipartFile] that remembers either the disk [filePath]
/// or the in-memory [rawBytes], so we can recreate a new stream for retry.
class ExtendedMultipartFile extends MultipartFile {
  final String? filePath; // If from disk
  final List<int>? rawBytes; // If from memory

  ExtendedMultipartFile(
    super.stream,
    super.length, {
    required super.filename,
    super.contentType,
    this.filePath,
    this.rawBytes,
  });

  /// Create from a disk file
  static Future<ExtendedMultipartFile> fromFile(
    String path, {
    String? filename,
    MediaType? contentType,
  }) async {
    final file = File(path);
    final len = await file.length();
    final stream = file.openRead();

    filename ??= p.basename(path);

    return ExtendedMultipartFile(
      stream,
      len,
      filename: filename,
      contentType: contentType,
      filePath: path,
      rawBytes: null,
    );
  }

  /// Create from a disk file synchronously
  static ExtendedMultipartFile fromFileSync(
    String path, {
    String? filename,
    MediaType? contentType,
  }) {
    final file = File(path);
    final len = file.lengthSync();
    final stream = file.openRead();

    filename ??= p.basename(path);

    return ExtendedMultipartFile(
      stream,
      len,
      filename: filename,
      contentType: contentType,
      filePath: path,
      rawBytes: null,
    );
  }

  /// Create from raw bytes in memory
  static Future<ExtendedMultipartFile> fromBytes(
    List<int> bytes, {
    String? filename,
    MediaType? contentType,
  }) async {
    final stream = Stream.value(bytes);
    return ExtendedMultipartFile(
      stream,
      bytes.length,
      filename: filename,
      contentType: contentType,
      filePath: null,
      rawBytes: bytes,
    );
  }

  /// Create from raw bytes in memory (sync)
  static ExtendedMultipartFile fromBytesSync(
    List<int> bytes, {
    String? filename,
    MediaType? contentType,
  }) {
    final stream = Stream.value(bytes);
    return ExtendedMultipartFile(
      stream,
      bytes.length,
      filename: filename,
      contentType: contentType,
      filePath: null,
      rawBytes: bytes,
    );
  }
}

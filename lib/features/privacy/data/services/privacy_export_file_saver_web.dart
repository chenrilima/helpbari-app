// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

Future<String> savePrivacyExportFile({
  required Uint8List bytes,
  required String fileName,
}) async {
  final anchor = html.AnchorElement(
    href: 'data:application/zip;base64,${base64Encode(bytes)}',
  )..download = fileName;
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  return fileName;
}

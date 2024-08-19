import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

Future<String> saveImagePermanently(File imageFile) async {
  final directory = await getApplicationDocumentsDirectory();
  final String path = directory.path;
  final String fileName = basename(imageFile.path);
  final File permanentFile = await imageFile.copy('$path/$fileName');
  return '$path/$fileName';
}

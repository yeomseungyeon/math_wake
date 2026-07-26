import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class SoundPickerSheet {
  /// 기기 저장소에서 음원 파일을 선택하고 절대 경로를 반환
  static Future<String?> pick(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      return result?.files.single.path;
    } catch (_) {
      return null;
    }
  }
}

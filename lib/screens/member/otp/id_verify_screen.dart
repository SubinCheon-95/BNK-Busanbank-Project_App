/*
  날짜: 2026/01/02
  내용: 신분증 OCR 인증
  이름: 오서정
*/

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tkbank/services/member_service.dart';
import 'dart:typed_data';

const Color bnkPrimary = Color(0xFF6A1B9A);
const Color bnkGrayText = Color(0xFF6B7280);

enum IdDocType { rrnCard, driverLicense, unknown }

class IdVerifyScreen extends StatefulWidget {
  const IdVerifyScreen({super.key});

  @override
  State<IdVerifyScreen> createState() => _IdVerifyScreenState();
}

class _IdVerifyScreenState extends State<IdVerifyScreen> {

  Size? _previewAreaSize;
  Rect? _guideRectOnPreview;

  Uint8List? _debugCropBytes;
  Uint8List? _debugStripBytes;


  CameraController? _cam;
  bool _ready = false;

  bool _capturing = false;
  bool _processing = false;

  XFile? _shot;
  String _message = '';
  bool _success = false;

  // OCR 결과
  String _rawText = '';
  Map<String, String> _fields = {};
  IdDocType _docType = IdDocType.unknown;

  @override
  void initState() {
    super.initState();
    _initCam();
  }

  Future<void> _initCam() async {
    final cams = await availableCameras();
    final back = cams.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cams.first,
    );

    final controller = CameraController(
      back,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await controller.initialize();
    if (!mounted) return;

    setState(() {
      _cam = controller;
      _ready = true;
    });
  }

  @override
  void dispose() {
    _cam?.dispose();
    super.dispose();
  }

  // ====== UI 가이드 사각형(화면 좌표) ======
  Rect _guideRect(Size screen) {
    final w = screen.width;
    final h = screen.height;

    final guideW = w * 0.86;
    final guideH = guideW / 1.6;

    final left = (w - guideW) / 2;
    final top = (h - guideH) / 2.2; // 살짝 위로
    return Rect.fromLTWH(left, top, guideW, guideH);
  }

  Future<void> _takeShot() async {
    if (_cam == null || !_cam!.value.isInitialized) return;
    if (_capturing || _processing) return;

    setState(() {
      _capturing = true;
      _message = '';
      _success = false;
      _fields = {};
      _rawText = '';
      _docType = IdDocType.unknown;
    });

    try {
      await _cam!.setFlashMode(FlashMode.off);
      final x = await _cam!.takePicture();
      setState(() => _shot = x);
      await _processShot(x);
    } catch (e) {
      setState(() {
        _message = '촬영에 실패했습니다. 다시 시도해주세요.';
        _success = false;
      });
    } finally {
      setState(() => _capturing = false);
    }
  }

  Future<void> _processShot(XFile shot) async {
    setState(() => _processing = true);

    try {
      // 1) 가이드 기준 크롭
      final cropped = await _cropToGuideAccurate(shot);

      // 2) 1차 OCR (전체)
      final text1 = (await MemberService()
          .idOcrByVision(base64: await _encodeBase64(cropped)))
          .trim();

      String mergedText = text1;

      // 3) 주민번호가 없으면 → 2차 OCR (하단 스트립)
      final rrn1 = extractRrnSmart(text1);
      if (rrn1 == null) {
        final strip = await _cropBottomStripForRrn(cropped);

        final text2 = (await MemberService()
            .idOcrByVision(base64: await _encodeBase64(strip)))
            .trim();

        mergedText = '$text1\n$text2';
      }

      setState(() => _rawText = mergedText);

      if (mergedText.isEmpty) {
        setState(() {
          _success = false;
          _message = '텍스트를 인식하지 못했어요.\n밝은 곳에서, 반사 없이 다시 촬영해 주세요.';
        });
        return;
      }

      // 4) 파싱
      final parsed = parseKoreanIdFields(mergedText);
      setState(() {
        _docType = parsed.docType;
        _fields = parsed.fields;
      });

      final name = parsed.fields['이름'];
      final rrn  = parsed.fields['주민번호'];

      bool matched = false;
      if (name != null && rrn != null) {
        matched = await MemberService().verifyIdWithDb(userName: name, rrn: rrn);
      }

      final ok = isAcceptable(parsed) && matched;

      setState(() {
        _success = ok;
        _message = ok
            ? '신분증 인증이 완료되었습니다.'
            : (!matched
            ? '신분증 정보가 일치하지 않습니다.'
            : '이름/주민번호를 충분히 인식하지 못했어요.\n가이드에 맞춰 다시 촬영해 주세요.');
      });

    } catch (e) {
      setState(() {
        _success = false;
        _message = '처리 중 오류가 발생했습니다.\n$e';
      });
    } finally {
      setState(() => _processing = false);
    }
  }

  Future<String> _encodeBase64(File f) async {
    final bytes = await f.readAsBytes();
    return base64Encode(bytes);
  }

  /// ✅ 핵심: 화면 가이드(Rect) -> 캡처 이미지 픽셀(Rect)로 변환 후 crop
  Future<File> _cropToGuideAccurate(XFile shot) async {
    final bytes = await File(shot.path).readAsBytes();
    var decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('이미지 decode 실패');

    // ✅ EXIF/회전 반영
    decoded = img.bakeOrientation(decoded);

    final previewArea = _previewAreaSize;
    final guideOnScreen = _guideRectOnPreview;
    if (previewArea == null || guideOnScreen == null) {
      throw Exception('preview area not ready');
    }

// 이제부터는 "screen" 대신 previewArea를 사용
    final screen = previewArea;

    final previewSize = _cam!.value.previewSize;
    if (previewSize == null) throw Exception('previewSize 없음');

    // previewSize는 보통 landscape 기준이라 swap
    final previewW = previewSize.height;
    final previewH = previewSize.width;

    // cover 스케일
    final scale = max(screen.width / previewW, screen.height / previewH);
    final fittedW = previewW * scale;
    final fittedH = previewH * scale;

    final dx = (screen.width - fittedW) / 2;
    final dy = (screen.height - fittedH) / 2;

    // guide(화면) -> preview(화면상)
    final gxInPreviewOnScreen = guideOnScreen.left - dx;
    final gyInPreviewOnScreen = guideOnScreen.top - dy;

    // preview(화면상) -> 정규화
    final gxNorm = gxInPreviewOnScreen / fittedW;
    final gyNorm = gyInPreviewOnScreen / fittedH;
    final gwNorm = guideOnScreen.width / fittedW;
    final ghNorm = guideOnScreen.height / fittedH;

    // 정규화 -> 캡처 이미지 픽셀
    int x = (decoded.width * gxNorm).round();
    int y = (decoded.height * gyNorm).round();
    int w = (decoded.width * gwNorm).round();
    int h = (decoded.height * ghNorm).round();

    // ✅ margin(글자 잘림 방지)
    final mx = (w * 0.10).round();
    final my = (h * 0.12).round();

    x = max(0, x - mx);
    y = max(0, y - my);
    w = min(decoded.width - x, w + mx * 2);
    h = min(decoded.height - y, h + my * 2);

    if (w <= 0 || h <= 0) throw Exception('crop 영역 계산 실패(w/h<=0)');

    final cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);

    // ✅ OCR 전처리(안정적으로)
    final gray = img.grayscale(cropped);
    final contrast = img.adjustColor(gray, contrast: 1.25);
    final resized = img.copyResize(contrast, width: 1600);

// ✅ 여기 추가
    final jpgBytes = img.encodeJpg(resized, quality: 92);
    setState(() => _debugCropBytes = Uint8List.fromList(jpgBytes));
    final dir = await getTemporaryDirectory();
    final outPath = p.join(
      dir.path,
      'id_crop_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final outFile = File(outPath)
      ..writeAsBytesSync(img.encodeJpg(resized, quality: 92));

    return outFile;
  }

  /// ✅ 주민번호 하단 스트립만 따로 잘라서 OCR하기
  Future<File> _cropBottomStripForRrn(File baseCropped) async {
    final bytes = await baseCropped.readAsBytes();
    var decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('bottom strip decode 실패');

    decoded = img.bakeOrientation(decoded);

    // 주민번호는 보통 카드 하단부 → 하단 42%
    final stripH = (decoded.height * 0.42).round();
    final y = max(0, decoded.height - stripH);

    final strip = img.copyCrop(
      decoded,
      x: 0,
      y: y,
      width: decoded.width,
      height: stripH,
    );

    // 전처리(숫자 선 살리기: threshold 없이 먼저)
    final gray = img.grayscale(strip);
    final contrast = img.adjustColor(gray, contrast: 1.55);
    final out = img.copyResize(contrast, width: 2000);
    final jpgBytes = img.encodeJpg(out, quality: 95);
    setState(() => _debugStripBytes = Uint8List.fromList(jpgBytes));
    final dir = await getTemporaryDirectory();
    final outPath = p.join(
      dir.path,
      'id_rrn_strip_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    return File(outPath)..writeAsBytesSync(img.encodeJpg(out, quality: 95));
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final guide = _guideRect(screen);

    return Scaffold(
      appBar: AppBar(
        title: const Text('신분증 인증'),
        backgroundColor: bnkPrimary,
        foregroundColor: Colors.white,
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final previewSizeOnScreen = constraints.biggest;

                // ✅ 프리뷰 영역 크기로 가이드 계산
                final guide = _guideRect(previewSizeOnScreen);

                // ✅ 크롭에서도 같은 값 쓰도록 저장
                _previewAreaSize = previewSizeOnScreen;
                _guideRectOnPreview = guide;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(_cam!),
                    _overlay(guide),
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 16,
                      child: _hintCard(),
                    ),
                    if (_processing)
                      Container(
                        color: Colors.black.withOpacity(0.35),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_message.isNotEmpty) _resultCard(),
                const SizedBox(height: 10),
                if (!_success) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _processing
                              ? null
                              : () {
                            setState(() {
                              _shot = null;
                              _message = '';
                              _success = false;
                              _fields = {};
                              _rawText = '';
                              _docType = IdDocType.unknown;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: bnkPrimary,
                            side: const BorderSide(color: bnkPrimary),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('다시찍기'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (_processing || _capturing) ? null : _takeShot,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bnkPrimary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(_capturing ? '촬영중...' : '촬영하기'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                ElevatedButton(
                  onPressed:
                  _success ? () => Navigator.pop(context, true) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bnkPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('인증 완료'),
                ),

                /*
                if (_rawText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ExpansionTile(
                    title: const Text(
                      '인식 결과 보기(디버그)',
                      style: TextStyle(fontSize: 13),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _rawText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: bnkGrayText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_debugCropBytes != null) ...[
                    const SizedBox(height: 8),
                    const Text('크롭 이미지(확인용)', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 180,
                      child: Image.memory(_debugCropBytes!, fit: BoxFit.contain),
                    ),
                  ],

                  if (_debugStripBytes != null) ...[
                    const SizedBox(height: 8),
                    const Text('하단 스트립(확인용)', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 120,
                      child: Image.memory(_debugStripBytes!, fit: BoxFit.contain),
                    ),
                  ],

                ],

                */
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hintCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '신분증을 가이드 안에 맞춰 촬영해 주세요.\n반사(빛 번짐)가 있으면 인식이 잘 안돼요.',
        style: TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
      ),
    );
  }

  Widget _resultCard() {
    final bg = _success ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final fg = _success ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Text(
        _message,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700),
      ),
    );
    /*
    final bg = _success ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final fg = _success ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _message,
            style: TextStyle(color: fg, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (_fields.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _fields.entries.map((e) {
                final v =
                e.key.contains('주민번호') ? maskRrn(e.value) : e.value;
                return Chip(
                  label: Text('${e.key}: $v',
                      style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: fg.withOpacity(0.25)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );

     */
  }

}

// ====== 가이드 오버레이 ======
Widget _overlay(Rect guide) {
  return Stack(
    children: [
      Positioned(
        left: 0,
        top: 0,
        right: 0,
        height: guide.top,
        child: Container(color: Colors.black.withOpacity(0.45)),
      ),
      Positioned(
        left: 0,
        top: guide.bottom,
        right: 0,
        bottom: 0,
        child: Container(color: Colors.black.withOpacity(0.45)),
      ),
      Positioned(
        left: 0,
        top: guide.top,
        width: guide.left,
        height: guide.height,
        child: Container(color: Colors.black.withOpacity(0.45)),
      ),
      Positioned(
        left: guide.right,
        top: guide.top,
        right: 0,
        height: guide.height,
        child: Container(color: Colors.black.withOpacity(0.45)),
      ),
      Positioned(
        left: guide.left,
        top: guide.top,
        width: guide.width,
        height: guide.height,
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.85), width: 2),
            ),
          ),
        ),
      ),
    ],
  );
}

// ====== 파싱/검증 로직 ======
class ParsedIdResult {
  final IdDocType docType;
  final Map<String, String> fields;
  ParsedIdResult({required this.docType, required this.fields});
}

ParsedIdResult parseKoreanIdFields(String raw) {
  final text = raw
      .replaceAll('\u00A0', ' ')
      .replaceAll(RegExp(r'[|]'), ' ')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n+'), '\n')
      .trim();

  final name = extractNameSmart(text);
  final rrnValue = extractRrnSmart(text);

  final dl = RegExp(r'(\d{2})[- ]?(\d{2})[- ]?(\d{6})[- ]?(\d{2})')
      .firstMatch(text);

  IdDocType type = IdDocType.unknown;
  final fields = <String, String>{};

  if (rrnValue != null || text.contains('주민등록증')) {
    type = IdDocType.rrnCard;
    if (name != null) fields['이름'] = name;
    if (rrnValue != null) fields['주민번호'] = rrnValue;
  } else if (dl != null || text.contains('운전면허')) {
    type = IdDocType.driverLicense;
    if (name != null) fields['이름'] = name;
    if (dl != null) {
      fields['면허번호'] =
      '${dl.group(1)}-${dl.group(2)}-${dl.group(3)}-${dl.group(4)}';
    }
  } else {
    if (name != null) fields['이름(추정)'] = name;
    if (rrnValue != null) fields['주민번호(추정)'] = rrnValue;
    if (dl != null) {
      fields['면허번호(추정)'] =
      '${dl.group(1)}-${dl.group(2)}-${dl.group(3)}-${dl.group(4)}';
    }
  }

  return ParsedIdResult(docType: type, fields: fields);
}

bool isAcceptable(ParsedIdResult r) {
  final f = r.fields;
  if (r.docType == IdDocType.rrnCard) {
    return f.containsKey('이름') && f.containsKey('주민번호');
  }
  if (r.docType == IdDocType.driverLicense) {
    return f.containsKey('이름') && f.containsKey('면허번호');
  }
  return false;
}

String maskRrn(String rrn) {
  final m = RegExp(r'^(\d{6})-([1-4])(\d{6}|\*{6})$').firstMatch(rrn);
  if (m == null) return rrn;
  return '${m.group(1)}-${m.group(2)}******';
}

String? extractNameSmart(String raw) {
  final t = raw
      .replaceAll('\u00A0', ' ')
      .replaceAll(RegExp(r'[|]'), ' ')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n+'), '\n')
      .trim();

  // 1) "홍길동(吳)" 같은 패턴이 있으면 최우선
  final mHan = RegExp(
    r'\b([가-힣]{2,4})\s*\(\s*[一-龥㐀-䶵豈-﫿]{1,4}\s*\)',
  ).firstMatch(t);
  if (mHan != null) {
    final cand = mHan.group(1)!;
    if (!_isStop(cand) && !_looksLikeAddress(cand)) return cand;
  }

  // 2) "주민등록증" 다음 구간에서만 후보 찾기
  final idx = t.indexOf('주민등록증');
  if (idx >= 0) {
    // ✅ 핵심: "주민등록증" 문자 자체는 제외하고 그 다음부터 보기
    final start = idx + '주민등록증'.length;
    final end = min(t.length, start + 120);
    var near = t.substring(start, end).trim();

    // OCR이 "- " 같은거 붙일 수 있으니 제거
    near = near.replaceFirst(RegExp(r'^[-–—\s]+'), '');

    // 여기서 2~4글자 후보를 순서대로 보면서 첫 "이름같은" 것 선택
    final matches = RegExp(r'([가-힣]{2,4})')
        .allMatches(near)
        .map((e) => e.group(1)!)
        .toList();

    for (final c in matches) {
      if (_isStop(c)) continue;
      if (_looksLikeAddress(c)) continue;
      // ✅ 주민/등록/증 같은 단어가 섞이면 이름 아님 처리
      if (c.contains('주민') || c.contains('등록') || c.contains('증')) continue;
      return c;
    }
  }

  return null;
}

bool _isStop(String c) {
  const stop = {
    // 원본
    '주민등록증', '대한민국', '발급일', '주소', '성명', '이름', '주민등록번호', '운전면허증',
    // ✅ 추가(중요): OCR이 쪼개서 내는 케이스 방어
    '주민등록', '주민', '등록', '등록증', '주민번호',
    // 종종 잡히는 잡단어
    '관할', '시장', '구청', '청장',
  };

  if (stop.contains(c)) return true;

  // "주민등록증"이 붙어 깨지거나 일부만 나오는 케이스까지 방어
  if (c.contains('주민') || c.contains('등록') || c.contains('증')) return true;

  return false;
}

bool _looksLikeAddress(String c) {
  if (RegExp(r'(시|군|구|동|읍|면|리)$').hasMatch(c)) return true;
  if (RegExp(r'(로|길)$').hasMatch(c)) return true;

  const tokens = {
    '부산','서울','대구','인천','광주','대전','울산','세종',
    '해운대','동래','수영','사하','사상','연제','금정','기장','중구','서구','동구','남구','북구'
  };
  if (tokens.contains(c)) return true;

  return false;
}



String normalizeForRrn(String s) {
  return s
      .replaceAll(RegExp(r'[Oo]'), '0')
      .replaceAll(RegExp(r'[Il|]'), '1')
      .replaceAll('S', '5')
      .replaceAll('B', '8')
      .replaceAll(RegExp(r'[‐-‒–—−]'), '-')
      .replaceAll(RegExp(r'[^0-9\-\*\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String? extractRrnSmart(String raw) {
  final t = normalizeForRrn(raw);

  final m1 =
  RegExp(r'(\d{6})\s*[- ]?\s*([1-4][0-9\*]{6}|\*{7})').firstMatch(t);
  if (m1 != null) return '${m1.group(1)}-${m1.group(2)}';

  final m2 = RegExp(r'\b(\d{6})([1-4][0-9\*]{6})\b').firstMatch(t);
  if (m2 != null) return '${m2.group(1)}-${m2.group(2)}';

  final m3 = RegExp(
      r'(\d{2}\s*\d{2}\s*\d{2})\s*[- ]?\s*([1-4]\s*[0-9\*]\s*[0-9\*]\s*[0-9\*]\s*[0-9\*]\s*[0-9\*]\s*[0-9\*])')
      .firstMatch(t);
  if (m3 != null) {
    final left = m3.group(1)!.replaceAll(' ', '');
    final right = m3.group(2)!.replaceAll(' ', '');
    return '$left-$right';
  }

  return null;
}

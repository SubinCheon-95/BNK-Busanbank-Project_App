// 2025/12/23 - 프로필 수정 화면 - 작성자: 진원

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../services/profile_service.dart';
import '../../providers/auth_provider.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final ProfileService _profileService = ProfileService();
  final TextEditingController _nicknameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedAvatar;
  bool _isNicknameChecked = false;
  bool _isNicknameAvailable = false;
  bool _isLoading = false;
  String? _currentNickname;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  /// 사용자 프로필 로드
  void _loadUserProfile() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _currentNickname = authProvider.nickname;
      _currentAvatarUrl = authProvider.avatarImage;
      if (_currentNickname != null) {
        _nicknameController.text = _currentNickname!;
      }
    });
  }

  /// 닉네임 중복 확인
  Future<void> _checkNickname() async {
    final nickname = _nicknameController.text.trim();

    if (nickname.isEmpty) {
      _showMessage('닉네임을 입력해주세요.');
      return;
    }

    if (nickname.length < 2 || nickname.length > 20) {
      _showMessage('닉네임은 2-20자 이내로 입력해주세요.');
      return;
    }

    // 현재 닉네임과 동일한 경우
    if (nickname == _currentNickname) {
      setState(() {
        _isNicknameChecked = true;
        _isNicknameAvailable = true;
      });
      _showMessage('현재 사용 중인 닉네임입니다.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _profileService.checkNickname(nickname);

      setState(() {
        _isNicknameChecked = true;
        _isNicknameAvailable = result['available'] ?? false;
      });

      _showMessage(result['message'] ?? '확인 완료');
    } catch (e) {
      setState(() {
        _isNicknameChecked = false;
        _isNicknameAvailable = false;
      });
      _showMessage('닉네임 중복 확인 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 아바타 이미지 선택
  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedAvatar = File(image.path);
        });
      }
    } catch (e) {
      _showMessage('이미지 선택 실패: $e');
    }
  }

  /// 프로필 저장
  Future<void> _saveProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userNo = authProvider.userNo?.toString();

    if (userNo == null) {
      _showMessage('사용자 정보를 찾을 수 없습니다.');
      return;
    }

    bool hasChanges = false;

    setState(() => _isLoading = true);

    try {
      // 닉네임 변경
      final nickname = _nicknameController.text.trim();
      if (nickname.isNotEmpty && nickname != _currentNickname) {
        if (!_isNicknameChecked || !_isNicknameAvailable) {
          _showMessage('닉네임 중복 확인을 해주세요.');
          setState(() => _isLoading = false);
          return;
        }

        final nicknameResult = await _profileService.updateNickname(
          userNo: userNo,
          nickname: nickname,
        );

        if (nicknameResult['success'] == true) {
          hasChanges = true;
          setState(() => _currentNickname = nickname);
          // AuthProvider의 사용자 정보 업데이트
          await authProvider.updateProfile(nickname: nickname);
        }
      }

      // 아바타 변경
      if (_selectedAvatar != null) {
        final avatarResult = await _profileService.uploadAvatar(
          userNo: userNo,
          avatarFile: _selectedAvatar!,
        );

        if (avatarResult['success'] == true) {
          hasChanges = true;
          final avatarUrl = avatarResult['avatarUrl'];
          setState(() => _currentAvatarUrl = avatarUrl);
          // AuthProvider의 사용자 정보 업데이트
          await authProvider.updateProfile(avatarImage: avatarUrl);
        }
      }

      if (hasChanges) {
        _showMessage('프로필이 업데이트되었습니다.');
        // 이전 화면으로 돌아가기
        Navigator.pop(context, true);
      } else {
        _showMessage('변경된 내용이 없습니다.');
      }
    } catch (e) {
      _showMessage('프로필 저장 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아바타 섹션
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _selectedAvatar != null
                              ? FileImage(_selectedAvatar!)
                              : (_currentAvatarUrl != null
                                  ? NetworkImage(_currentAvatarUrl!)
                                  : null) as ImageProvider?,
                          child: _selectedAvatar == null && _currentAvatarUrl == null
                              ? const Icon(Icons.person, size: 60, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '프로필 사진 변경',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 닉네임 섹션
            const Text(
              '닉네임',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      hintText: '닉네임을 입력하세요 (2-20자)',
                      border: const OutlineInputBorder(),
                      suffixIcon: _isNicknameChecked
                          ? Icon(
                              _isNicknameAvailable ? Icons.check_circle : Icons.cancel,
                              color: _isNicknameAvailable ? Colors.green : Colors.red,
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      // 입력 변경 시 중복 확인 상태 초기화
                      if (_isNicknameChecked) {
                        setState(() {
                          _isNicknameChecked = false;
                          _isNicknameAvailable = false;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkNickname,
                  child: const Text('중복 확인'),
                ),
              ],
            ),

            if (_isNicknameChecked && !_isNicknameAvailable)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '이미 사용 중인 닉네임입니다.',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 12,
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('저장', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

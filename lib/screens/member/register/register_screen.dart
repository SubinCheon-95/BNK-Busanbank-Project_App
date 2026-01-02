
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tkbank/models/users.dart';
import 'package:tkbank/services/member_service.dart';

class RegisterScreen extends StatefulWidget{
  const RegisterScreen({super.key});

  @override
  State<StatefulWidget> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>{

  final _formKey = GlobalKey<FormState>();

  final _usidController = TextEditingController();
  final _pass1Controller = TextEditingController();
  final _pass2Controller = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  // 서비스 생성
  final _service = MemberService();

  bool _isLoading = false;


  Future<void> _submitForm() async {

    if(!_formKey.currentState!.validate()){
      return;
    }

  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입'),),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('기본 정보 입력'),
                  const SizedBox(height: 20,),
                  _buildInputField(
                      controller: _usidController,
                      title: '아이디 입력',
                      vaildator: (value){
                        if(value == null || value.length < 4){
                          return '아이디는 4자 이상 이어야 합니다.';
                        }
                        return null;
                      }
                  ),
                  const SizedBox(height: 10,),
                  _buildInputField(
                      controller: _pass1Controller,
                      title: '비밀번호 입력',
                      isPass: true,
                      vaildator: (value){
                        if(value == null || value.length < 5){
                          return '비밀번호는 5자 이상 이어야 합니다.';
                        }
                        return null;
                      }
                  ),
                  const SizedBox(height: 10,),
                  _buildInputField(
                      controller: _pass2Controller,
                      title: '비밀번호 확인',
                      isPass: true,
                      vaildator: (value){
                        if(value == null || value.length < 5){
                          if(value != _pass1Controller.text){
                            return '비밀번호가 일치하지 않습니다.';
                          }
                          return '비밀번호는 5자 이상 이어야 합니다.';
                        }
                        return null;
                      }
                  ),
                  const SizedBox(height: 10,),
                  _buildInputField(
                      controller: _nameController,
                      title: '이름 입력',
                      vaildator: (value){
                        if(value == null || value.isEmpty){
                          return '이름은 필수 입력 항목 입니다.';
                        }
                        return null;
                      }
                  ),
                  const SizedBox(height: 10,),
                  _buildInputField(
                      controller: _emailController,
                      title: '이메일 입력(선택)',
                      vaildator: (value){
                        return null;
                      }
                  ),
                  const SizedBox(height: 10,),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(onPressed: (){
                          // 로그인 이동
                          Navigator.of(context).pop();
                        }, child: const Text('취소')),
                        const SizedBox(width: 10,),
                        ElevatedButton(onPressed: _submitForm, child: const Text('가입')),
                      ],
                    ),

                  )

                ],

              )
          ),
        ),
      ),
    );
  }

  // 입력 필드 디자인 함수
  Widget _buildInputField({
    required TextEditingController controller,
    required String title,
    required String? Function(String?) vaildator,
    bool isPass = false
  }){
    return TextFormField(
      controller: controller,
      obscureText: isPass,
      decoration: InputDecoration(
          labelText: title,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 15)
      ),
      validator: vaildator,

    );
  }

  @override
  void dispose() {
    super.dispose();
    _usidController.dispose();
    _pass1Controller.dispose();
    _pass2Controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
  }

}
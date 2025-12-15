/*
  날짜 : 2025/12/15
  내용 : 약관 html 보는 기능 페이지 추가
  작성자 : 오서정
*/
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TermWebViewScreen extends StatefulWidget {
  final String url;

  const TermWebViewScreen({
    super.key,
    required this.url,
  });

  @override
  State<TermWebViewScreen> createState() => _TermWebViewScreenState();
}

class _TermWebViewScreenState extends State<TermWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('약관 보기'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

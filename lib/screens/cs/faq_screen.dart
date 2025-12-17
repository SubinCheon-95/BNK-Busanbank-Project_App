import 'package:flutter/material.dart';

import '../../../models/faq_models.dart';
import '../../../services/cs/faq_api_service.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> with TickerProviderStateMixin {
  final _api = FaqApiService();

  final _searchCtrl = TextEditingController();

  List<FaqCategory> _categories = [];
  TabController? _tabController;

  // 상태
  bool _loadingInit = true;
  bool _loadingList = false;
  bool _loadingMore = false;

  String _searchType = 'qa'; // question/answer/qa
  String _keyword = '';

  int _page = 1;
  final int _size = 10;
  int _total = 0;

  final List<FaqItem> _items = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _loadingInit = true);

    try {
      final cats = await _api.fetchCategories();
      // "전체" 탭을 위한 가상 카테고리(코드 빈값)
      _categories = [FaqCategory(code: '', codeName: '전체'), ...cats];

      _tabController?.dispose();
      _tabController = TabController(length: _categories.length, vsync: this);
      _tabController!.addListener(() {
        if (_tabController!.indexIsChanging) return;
        _refreshList(); // 탭 바뀌면 새로 조회
      });

      await _refreshList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('FAQ 초기화 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingInit = false);
    }
  }

  String? _currentCate() {
    if (_tabController == null) return null;
    final code = _categories[_tabController!.index].code;
    if (code.trim().isEmpty) return null; // 전체
    return code;
  }

  Future<void> _refreshList() async {
    setState(() {
      _loadingList = true;
      _page = 1;
      _total = 0;
      _items.clear();
    });

    try {
      final res = await _api.fetchFaqList(
        cate: _currentCate(),
        keyword: _keyword,
        searchType: _searchType,
        page: _page,
        size: _size,
      );

      setState(() {
        _items.addAll(res.dtoList);
        _total = res.total;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('FAQ 조회 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingList = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    if (_items.length >= _total) return;

    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final res = await _api.fetchFaqList(
        cate: _currentCate(),
        keyword: _keyword,
        searchType: _searchType,
        page: nextPage,
        size: _size,
      );

      setState(() {
        _page = nextPage;
        _items.addAll(res.dtoList);
        _total = res.total;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('FAQ 추가 로드 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _applySearch() {
    final text = _searchCtrl.text.trim();
    setState(() => _keyword = text);
    _refreshList();
  }

  @override
  Widget build(BuildContext context) {
    final tabController = _tabController;

    return Scaffold(
      appBar: AppBar(
        title: const Text('자주 묻는 질문(FAQ)'),
        bottom: tabController == null
            ? null
            : TabBar(
          controller: tabController,
          isScrollable: true,
          tabs: _categories.map((c) => Tab(text: c.codeName)).toList(),
        ),
      ),
      body: _loadingInit
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 검색 영역
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _searchType,
                  items: const [
                    DropdownMenuItem(value: 'qa', child: Text('질문+답변')),
                    DropdownMenuItem(value: 'question', child: Text('질문')),
                    DropdownMenuItem(value: 'answer', child: Text('답변')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _searchType = v);
                    if (_keyword.isNotEmpty) _refreshList();
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _applySearch(),
                    decoration: const InputDecoration(
                      hintText: '검색어를 입력하세요',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _applySearch,
                  child: const Text('검색'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: _loadingList
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                ? const Center(child: Text('검색 결과가 없습니다.'))
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _items.length + 1, // 더보기 영역 포함
              itemBuilder: (context, idx) {
                if (idx == _items.length) {
                  final canMore = _items.length < _total;
                  if (!canMore) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          '총 $_total건',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: _loadingMore
                          ? const CircularProgressIndicator()
                          : OutlinedButton(
                        onPressed: _loadMore,
                        child: Text('더보기 (${_items.length}/$_total)'),
                      ),
                    ),
                  );
                }

                final item = _items[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ExpansionTile(
                    title: Text(
                      'Q. ${item.question}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '카테고리: ${item.faqCategory}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('A. ${item.answer}'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

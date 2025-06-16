// about_us.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_state.dart'; // ApplicationState import

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {

  // 카드 추가/수정을 위한 폼을 표시하는 함수
  void _showCardForm(BuildContext context, ApplicationState appState,
      {DocumentSnapshot<Map<String, dynamic>>? cardDocument}) 
  {
    final _formKey = GlobalKey<FormState>();
    String _title = cardDocument?['title'] ?? '';
    String _content = cardDocument?['content'] ?? '';
    int _order = cardDocument?['order'] ?? 0; // 기본값 또는 다음 순서

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(cardDocument == null ? '새 카드 추가' : '카드 수정'),
          content: SingleChildScrollView( // 스크롤 가능하도록
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    initialValue: _title,
                    decoration: const InputDecoration(labelText: '제목'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '제목을 입력해주세요.';
                      }
                      return null;
                    },
                    onSaved: (value) => _title = value!,
                  ),
                  TextFormField(
                    initialValue: _content,
                    decoration: const InputDecoration(labelText: '내용'),
                    maxLines: 3, // 여러 줄 입력 가능
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '내용을 입력해주세요.';
                      }
                      return null;
                    },
                    onSaved: (value) => _content = value!,
                  ),
                  TextFormField(
                    initialValue: _order.toString(),
                    decoration: const InputDecoration(labelText: '순서 (숫자)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '순서를 입력해주세요.';
                      }
                      if (int.tryParse(value) == null) {
                        return '숫자만 입력 가능합니다.';
                      }
                      return null;
                    },
                    onSaved: (value) => _order = int.parse(value!),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: Text(cardDocument == null ? '추가' : '저장'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  try {
                    if (cardDocument == null) {
                      // 새로운 카드 추가
                      // 현재 카드 개수를 기반으로 order 값 자동 설정 (예시)
                      final snapshot = await FirebaseFirestore.instance.collection('about_us').get();
                      _order = snapshot.docs.length; // 단순 예시, 더 정교한 로직 필요 가능

                      await appState.addAboutCard(_title, _content, _order);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('카드가 추가되었습니다.')),
                      );
                    } else {
                      // 기존 카드 수정
                      await appState.updateAboutCard(
                          cardDocument.id, _title, _content, _order);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('카드가 수정되었습니다.')),
                      );
                    }
                    Navigator.of(dialogContext).pop(); // 폼 닫기
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('오류 발생: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<ApplicationState>(context);


    return Scaffold(
      appBar: AppBar(
                title: const Text('About Us'),
        actions: [
          if(appState.isManager) // 관리자 모드일 때만 표시
            // 새 카드 추가 버튼 (관리자 기능으로 제한할 수 있음)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _showCardForm(context, appState),
              tooltip: '새 카드 추가',
            ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: appState.getAboutCards(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('소개 내용이 아직 없습니다. 관리자 모드에서 추가해주세요.'),
            );
          }

          final cards = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final cardData = cards[index].data();
              final cardDocument = cards[index]; // DocumentSnapshot 전달

              return _buildEditableCard(
                context,
                appState,
                cardDocument, // DocumentSnapshot 전달
                title: cardData['title'] ?? '제목 없음',
                content: cardData['content'] ?? '내용 없음',
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEditableCard(
    BuildContext context,
    ApplicationState appState,
    DocumentSnapshot<Map<String, dynamic>> cardDocument, // DocumentSnapshot 사용
    {
    required String title,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            // 수정 및 삭제 버튼 (관리자 기능으로 제한할 수 있음)
            if(appState.isManager)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () =>
                        _showCardForm(context, appState, cardDocument: cardDocument),
                    tooltip: '수정',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      // 삭제 확인 다이얼로그
                      final confirmDelete = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            title: const Text('카드 삭제'),
                            content: const Text('정말로 이 카드를 삭제하시겠습니까?'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('취소'),
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(false),
                              ),
                              TextButton(
                                child: const Text('삭제'),
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(true),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmDelete == true) {
                        try {
                          await appState.deleteAboutCard(cardDocument.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('카드가 삭제되었습니다.')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('카드 삭제 실패: $e')),
                          );
                        }
                      }
                    },
                    tooltip: '삭제',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

}

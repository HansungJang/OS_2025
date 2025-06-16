// therapist_page.dart 수정

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_state.dart'; // ApplicationState import

class TherapistPage extends StatefulWidget {
  const TherapistPage({super.key});

  @override
  State<TherapistPage> createState() => _TherapistPageState();
}

class _TherapistPageState extends State<TherapistPage> {
  // 상담사 정보 수정을 위한 폼을 표시하는 함수
  void _showTherapistForm(
      BuildContext context,
      ApplicationState appState,
      DocumentSnapshot<Map<String, dynamic>>? therapistDataDoc) {
    final _formKey = GlobalKey<FormState>();

    // Firestore 문서에서 데이터를 가져오거나, 문서가 없으면 기본값 또는 빈 문자열 사용
    Map<String, dynamic> currentData = therapistDataDoc?.data() ?? {};
    String _name = currentData['name'] ?? '';
    String _titleCredentials = currentData['titleCredentials'] ?? '';
    String _affiliation = currentData['affiliation'] ?? '';
    String _specialties = currentData['specialties'] ?? ''; 
    String _message = currentData['message'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(therapistDataDoc != null && therapistDataDoc.exists ? '상담사 정보 수정'  : '상담사 정보 입력'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    initialValue: _name,
                    decoration: const InputDecoration(labelText: '이름 및 학위'),
                    validator: (value) =>
                        value == null || value.isEmpty ? '이름을 입력해주세요.' : null,
                    onSaved: (value) => _name = value!,
                  ),
                  TextFormField(
                    initialValue: _titleCredentials,
                    decoration: const InputDecoration(labelText: '영문 직함/자격'),
                    validator: (value) =>
                        value == null || value.isEmpty ? '직함/자격을 입력해주세요.' : null,
                    onSaved: (value) => _titleCredentials = value!,
                  ),
                  TextFormField(
                    initialValue: _affiliation,
                    decoration: const InputDecoration(labelText: '소속 및 주요 경력'),
                    maxLines: 10,
                    validator: (value) =>
                        value == null || value.isEmpty ? '소속을 입력해주세요.' : null,
                    onSaved: (value) => _affiliation = value!,
                  ),
                  TextFormField(
                    initialValue: _specialties, // specialties 필드 사용
                    decoration: const InputDecoration(labelText: '전문 분야'),
                    maxLines: 5,
                    validator: (value) =>
                        value == null || value.isEmpty ? '전문 분야를 입력해주세요.' : null,
                    onSaved: (value) => _specialties = value!,
                  ),
                  TextFormField(
                    initialValue: _message,
                    decoration: const InputDecoration(labelText: '상담사의 한마디'),
                    maxLines: 4,
                    validator: (value) =>
                        value == null || value.isEmpty ? '메시지를 입력해주세요.' : null,
                    onSaved: (value) => _message = value!,
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
              child: Text(therapistDataDoc != null && therapistDataDoc.exists ? '업데이트' : '저장'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  try {
                    await appState.updateTherapistProfile(
                      name: _name,
                      titleCredentials: _titleCredentials,
                      affiliation: _affiliation,
                      specialties: _specialties, // specialties 전달
                      message: _message,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(therapistDataDoc != null && therapistDataDoc.exists ? '상담사 정보가 업데이트되었습니다.' : '상담사 정보가 저장되었습니다.')),
                    );
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
        title: const Text('상담사 소개'),
        actions: [
        if(appState.isManager) // 관리자일 때만 수정 버튼 표시
          // 정보 수정 버튼
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>( // StreamBuilder를 사용하여 therapistDoc을 가져옵니다.
            stream: appState.getTherapistProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return IconButton(
                  icon: const Icon(Icons.edit_note_outlined), // 비활성화된 느낌의 아이콘
                  onPressed: null, // 버튼 비활성화
                  tooltip: '정보 수정 (데이터 없음)',
                );
              }
              // 데이터가 있으면 수정 버튼 활성화
              return IconButton(
                icon: const Icon(Icons.edit_note),
                onPressed: () {
                  _showTherapistForm(context, appState, snapshot.data);
                },
                  tooltip: snapshot.hasData && snapshot.data!.exists ? '정보 수정' : '정보 입력',
              );
            }
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: appState.getTherapistProfile(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('정보를 불러오는 중 오류 발생: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            // ensureTherapistProfileExists가 실행되었음에도 문서가 없다면,
            // 사용자에게 정보를 입력하도록 유도하거나, 기본 메시지를 보여줄 수 있습니다.
            // AppBar의 버튼을 통해 정보 입력이 가능하므로 여기서는 간단한 메시지를 표시합니다.

            return const Center(
             child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '상담사 정보가 아직 없습니다. 우측 상단 수정 버튼을 눌러 정보를 입력해주세요.',
                  textAlign: TextAlign.center,
                ),
              ),            );
          }

          final therapistInfo = snapshot.data!.data()!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView( // 내용이 길어질 경우 스크롤
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: therapistInfo['imageUrl'] == null
                        ? const Icon(Icons.person, size: 50, color: Colors.white70)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    therapistInfo['name'] ?? '이름 정보 없음',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    therapistInfo['titleCredentials'] ?? '직함 정보 없음',
                    style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    // affiliation과 specialties를 합쳐서 보여주거나, 별도 Text 위젯으로 분리
                    // 여기서는 예시로 affiliation만 보여주고, specialties는 아래 별도 섹션으로 구성 가능
                    therapistInfo['affiliation'] ?? '소속 정보 없음',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                   const SizedBox(height: 8),
                  Text(
                    therapistInfo['specialties'] ?? '전문 분야 정보 없음', // specialties 표시
                    style: TextStyle(fontSize: 15, color: Colors.blueGrey[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    '상담사의 한마디',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    therapistInfo['message'] ?? '메시지 정보 없음',
                    style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
// therapy_area.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_state.dart'; // ApplicationState import
import 'therapy_area_detail.dart'; // Import the new detail page

final Map<String, IconData> _iconMap = {
  'child_care': Icons.child_care,
  'school': Icons.school,
  'favorite': Icons.favorite,
  'people': Icons.people,
  'healing': Icons.healing,
  'spa': Icons.spa,
  'psychology': Icons.psychology,
  'self_improvement': Icons.self_improvement,
  'help_outline': Icons.help_outline,
};

// Updated function to get IconData from the map.
IconData getIconDataFromString(String iconName) {
  return _iconMap[iconName.toLowerCase()] ?? Icons.help_outline; // Default icon
}


class TherapyPage extends StatefulWidget {
  const TherapyPage({super.key});

  @override
  State<TherapyPage> createState() => _TherapyPageState();
}

class _TherapyPageState extends State<TherapyPage> {
 
   // Form dialog for adding/editing therapy areas [Create/Update]
  void _showTherapyAreaForm(BuildContext context, ApplicationState appState,
      {DocumentSnapshot<Map<String, dynamic>>? therapyDoc}) {
    final formKey = GlobalKey<FormState>();
    String title = therapyDoc?['title'] ?? '';
    String description = therapyDoc?['description'] ?? '';
    String iconName = therapyDoc?['iconName'] ?? 'healing';
    int order = therapyDoc?['order'] ?? 0;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(therapyDoc == null ? '새 상담 분야 추가' : '상담 분야 수정'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        initialValue: title,
                        decoration: const InputDecoration(labelText: '제목'),
                        validator: (value) =>
                            value == null || value.isEmpty ? '제목을 입력해주세요.' : null,
                        onSaved: (value) => title = value!,
                      ),
                      TextFormField(
                        initialValue: description,
                        decoration: const InputDecoration(labelText: '설명'),
                        maxLines: 4,
                        validator: (value) =>
                            value == null || value.isEmpty ? '설명을 입력해주세요.' : null,
                        onSaved: (value) => description = value!,
                      ),
                          DropdownButtonFormField<String>(
                            value: iconName,
                            decoration: const InputDecoration(labelText: '아이콘 선택'),
                            items: _iconMap.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Row(
                                  children: [
                                    Icon(entry.value, color: Theme.of(context).primaryColor),
                                    const SizedBox(width: 10),
                                    Text(entry.key),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setDialogState(() {
                                  iconName = newValue;
                                });
                              }
                            },
                            validator: (value) =>
                                value == null || value.isEmpty ? '아이콘을 선택해주세요.' : null,
                            onSaved: (value) => iconName = value ?? _iconMap.keys.first,
                          ),
            
                      TextFormField(
                        initialValue: order.toString(),
                        decoration: const InputDecoration(labelText: '순서 (숫자)'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return '순서를 입력해주세요.';
                          if (int.tryParse(value) == null) return '숫자만 입력 가능합니다.';
                          return null;
                        },
                        onSaved: (value) => order = int.parse(value!),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('취소'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  child: Text(therapyDoc == null ? '추가' : '저장'),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      try {
                        if (therapyDoc == null) {
                          await appState.addTherapyArea(
                              title, description, iconName, order);
                        } else {
                          await appState.updateTherapyArea(
                              therapyDoc.id, title, description, iconName, order);
                        }
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('작업이 완료되었습니다.')),
                        );
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
          }
        );
      },
    );
  }
 
   // Delete confirmation dialog [Delete]
  Future<void> _confirmDelete(BuildContext context, ApplicationState appState, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('정말로 이 항목을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await appState.deleteTherapyArea(docId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제되었습니다.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 중 오류 발생: $e')),
        );
      }
    }
  }

 
  // 카드 탭 시 확대/축소 효과를 위한 상태
  //String? _selectedCardId;
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<ApplicationState>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('상담 분야 안내'),
        backgroundColor: const Color(0xFFE8F5E9), // 연한 녹색 계열
      ), floatingActionButton:  appState.isManager
          ? FloatingActionButton(
        onPressed: () => _showTherapyAreaForm(context, appState),
        tooltip: '새 분야 추가',
        child: const Icon(Icons.add),
      ) : null,
      body: Stack(
        children: [
          // 1. 숲 테마 배경 (은은하게)
          Positioned.fill(
            child: Opacity(
              opacity: 0.1, // 투명도 조절
              child: Image.asset(
                'assets/enviroment.png', // TODO: 실제 이미지 경로로 변경
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 2. Firestore 데이터 연동하여 카드 목록 표시
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: appState.getTherapyAreas(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('등록된 상담 분야가 아직 없습니다.'),
                );
              }

              final therapyDocs = snapshot.data!.docs;

              // ListView.builder 또는 GridView.builder 선택
              // 여기서는 ListView.builder를 사용합니다.
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: therapyDocs.length,
                itemBuilder: (context, index) {
                  final doc = therapyDocs[index];
                  final data = doc.data();
                  //final cardId = doc.id; // Firestore 문서 ID

                  // Firestore에서 가져온 데이터 사용
                  return _buildTherapyCard(
                  context: context,
                  appState: appState,
                  doc: doc,
                  title: data['title'] ?? '제목 없음',
                  description: data['description'] ?? '설명 없음',
                  iconData: getIconDataFromString(data['iconName'] ?? 'help_outline'),
                  );
                 
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTherapyCard({
    required BuildContext context,
    required ApplicationState appState,
    required DocumentSnapshot<Map<String, dynamic>> doc,
    // required String id,
    required String title,
    required String description,
    required IconData iconData,

  }) {
    final theme = Theme.of(context);

  return Card(
   margin: const EdgeInsets.symmetric(vertical: 8.0),
   child: InkWell(
    onTap: () {
     Navigator.push(
      context,
      MaterialPageRoute(
       builder: (context) => TherapyAreaDetailPage(
        title: title,
        description: description,
        iconName: doc.data()?['iconName'] ?? 'healing',
       ),
      ),
     );
    },

    borderRadius: BorderRadius.circular(15.0),
    child: Padding(
     padding: const EdgeInsets.all(16.0),
     child: Column(
      children: [
       Row(
        children: [
         Icon(iconData, size: 40.0, color: theme.primaryColor),
         const SizedBox(width: 16.0),
         Expanded(
          child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
            Text(
             title,
             style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
             ),
            ),

            const SizedBox(height: 6.0),
            Text(
             description,
             maxLines: 2,
             overflow: TextOverflow.ellipsis,
             style: TextStyle(
              fontSize: 14.0,
              color: Colors.green.shade700,
              height: 1.4,
             ),
            ),
           ],
          ),
         ),
         const Icon(Icons.arrow_forward_ios, size: 16.0, color: Colors.grey),
        ],
       ),

       // Admin-only buttons
       // [수정] 관리자일 때만 수정/삭제 버튼 Row가 보이도록 if문 추가
      if (appState.isManager)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 20),
              onPressed: () => _showTherapyAreaForm(context, appState, therapyDoc: doc),
              tooltip: '수정',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
              onPressed: () => _confirmDelete(context, appState, doc.id),
              tooltip: '삭제',
            ),
            ],
          )
      ],
     ),
    ),
   ),
  );

  }
}
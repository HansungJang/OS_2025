 // lib/Home.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'about_us.dart';
import 'therapist_page.dart';
import 'therapy_area.dart';
import 'consultation_page.dart';
import 'location.dart';

class HomePage extends StatelessWidget {
  final List<_NavItem> navItems = [
    _NavItem(title: '센터 소개', icon: Icons.info_outline, page: const AboutPage()),
    _NavItem(title: '상담사 소개', icon: Icons.psychology_outlined, page: const TherapistPage()),
    _NavItem(title: '상담 분야 안내', icon: Icons.spa_outlined, page: const TherapyPage()),
    _NavItem(title: '상담 신청하기', icon: Icons.edit_note_outlined, page: const ConsultationPage()),
    _NavItem(title: '찾아오시는 길', icon: Icons.location_on_outlined, page: const LocationPage()),
  ];

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<ApplicationState>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('마음 쉼'),
        actions: [
          Consumer<ApplicationState>(
            builder: (context, appState, child) {
              return IconButton(
                icon:  Icon( appState.isManager ? Icons.lock_open : Icons.lock_outline,),
                tooltip: appState.isManager ? '관리자 모드' : '관리자 로그인',
                onPressed: () {
                  // [수정] 관리자가 아닐 때만 로그인 다이얼로그 표시
                  if (!appState.isManager) {
                    appState.showManagerLogin(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('이미 관리자 모드로 로그인되어 있습니다.')),
                    );
                  }
                },
              );
            }
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('정말로 로그아웃 하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('로그아웃'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await appState.signOut();
                // Redirection is handled by the root widget (MindRestApp)
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset('assets/enviroment.png', fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Image.asset('assets/center_logo.png', height: 100),
                const SizedBox(height: 12),
                const Text(
                  '마음 쉼 상담 센터',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '조용한 숲 속에서 나를 찾는 시간',
                  style: TextStyle(
                      fontSize: 16, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView.builder(
                    itemCount: navItems.length,
                    itemBuilder: (context, index) {
                      final item = navItems[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(item.icon,
                              color: Theme.of(context).primaryColor),
                          title: Text(item.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => item.page),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String title;
  final IconData icon;
  final Widget page;

  _NavItem({required this.title, required this.icon, required this.page});
}
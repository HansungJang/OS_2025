 // lib/login.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
 
class LoginPage extends StatelessWidget { // stateful에서 stateless로 변경, 1번 로그인 
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F1),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/center_logo.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16.0),
                const Text(
                  '마음 쉼',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4B5F4A),
                  ),
                ),
                const SizedBox(height: 60.0),

                // '시작하기' 버튼 UI 개선
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50), // 버튼 크기 확장
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: () => signInAsGuest(context),
                  child: const Text('시작하기'),
                ),

                const SizedBox(height: 40),
                const Text(
                  '숲에서의 휴식처럼,\n조용히 나를 돌아보는 시간',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 익명 로그인 함수 (기존과 동일, 파일 하단에 유지)
Future<void> signInAsGuest(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signInAnonymously();
  } catch (e) {
    print('❌ 익명 로그인 실패: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('익명 로그인에 실패했습니다: $e')),
      );
    }
  }
}
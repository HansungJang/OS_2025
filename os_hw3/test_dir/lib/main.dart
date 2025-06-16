// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart'; // Your MindRestApp
import 'app_state.dart'; // Your ApplicationState
import 'firebase_options.dart'; // Firebase 설정 파일 import

void main() async  {
  // Flutter 엔진과 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화 (firebase_options.dart 사용)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // 이 부분을 꼭 확인해주세요!
  );

  // ChangeNotifierProvider를 사용하여 ApplicationState 제공
  runApp(
     ChangeNotifierProvider(
      create: (context) => ApplicationState(),
      child: MindRestApp(),
  ),);
}
// location_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart'; // Import for geocoding  (경도, 위도 표기)
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_state.dart';
class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _targetCoordinates;
  String _currentAddress = '';

  @override // 변경된 주소로 지도 위치를 업데이트하기 위해 initState에서 geocodeAddress 호출
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-geocode if the address changes in Firestore
    final appState = Provider.of<ApplicationState>(context);
    appState.getCenterInfo().listen((snapshot) {
      if (snapshot.exists && snapshot.data()?['address'] != null) {
        final newAddress = snapshot.data()!['address'];
        if (newAddress != _currentAddress) {
          _currentAddress = newAddress;
          _geocodeAddress(newAddress);
        }
      }
    });
  }


  // 주소를 위도/경도로 변환하는 함수
  Future<void> _geocodeAddress(String address) async {
    if (!mounted || address.isEmpty) return;
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        if (mounted) {
          setState(() {
            _targetCoordinates = LatLng(location.latitude, location.longitude);
            _markers.clear();
            _markers.add(
              Marker(
                markerId: MarkerId(address),
                position: _targetCoordinates!,
                infoWindow: InfoWindow(title: '상담센터 위치', snippet: address),
              ),
            );
            _mapController?.animateCamera(CameraUpdate.newLatLng(_targetCoordinates!));
          });
        }
      }
    } catch (e) {
      print('Geocoding Error: $e');
      // 오류 발생 시 UI에 알림 (선택 사항)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('주소를 변환할 수 없습니다: $address')),
      );
    }
  }

  // 외부 링크를 여는 함수
  void _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }
  
  // 정보 수정 폼을 보여주는 함수
  void _showInfoForm(BuildContext context, ApplicationState appState, DocumentSnapshot<Map<String, dynamic>>? infoDoc) {
    // ... (이전과 동일한 _showInfoForm 코드는 여기에 위치합니다)
    final formKey = GlobalKey<FormState>();
    final data = infoDoc?.data() ?? {};
    String address = data['address'] ?? '';
    String phone = data['phone'] ?? '';
    String email = data['email'] ?? '';
    String kakaoLink = data['kakaoLink'] ?? '';
    String googleMapsUrl = data['googleMapsUrl'] ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('센터 정보 수정'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(initialValue: address, decoration: const InputDecoration(labelText: '주소'), onSaved: (v) => address = v!),
                TextFormField(initialValue: phone, decoration: const InputDecoration(labelText: '전화번호'), onSaved: (v) => phone = v!),
                TextFormField(initialValue: email, decoration: const InputDecoration(labelText: '이메일'), onSaved: (v) => email = v!),
                TextFormField(initialValue: kakaoLink, decoration: const InputDecoration(labelText: '카카오톡 채널 링크'), onSaved: (v) => kakaoLink = v!),
                TextFormField(initialValue: googleMapsUrl, decoration: const InputDecoration(labelText: '구글맵 링크'), onSaved: (v) => googleMapsUrl = v!),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('취소')),
          ElevatedButton(
            child: const Text('저장'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                try {
                  await appState.updateCenterInfo(address: address, phone: phone, email: email, kakaoLink: kakaoLink, googleMapsUrl: googleMapsUrl);
                  Navigator.of(dialogContext).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<ApplicationState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('찾아오시는 길'),
        actions: [
        if (appState.isManager)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final doc = await appState.getCenterInfo().first;
                _showInfoForm(context, appState, doc);
              },
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: appState.getCenterInfo(),
        builder: (context, snapshot) {
          // 상태 1: 에러 발생
          if (snapshot.hasError) return Center(child: Text("오류가 발생했습니다: ${snapshot.error}"));

          // 상태 2: 데이터 기다리는 중
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 상태 3: 데이터는 도착했으나, 문서가 없는 경우 (초기 생성 중)
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('센터 정보를 초기화하는 중입니다...'),
                ],
              ),
            );
          }
          
          // 상태 4: 데이터 수신 성공
          final data = snapshot.data!.data()!;
          final newAddress = data['address'] as String? ?? '';

          // 주소가 변경되었을 때만 geocoding 재실행
          if (newAddress.isNotEmpty && newAddress != _currentAddress) {
            _currentAddress = newAddress;
            // build가 완료된 후 geocoding을 실행하여 UI 충돌 방지
            WidgetsBinding.instance.addPostFrameCallback((_) {
               _geocodeAddress(newAddress);
            });
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Address', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(data['address'] ?? '주소 정보 없음'),
                const SizedBox(height: 16),
                Expanded(
                  child: _targetCoordinates == null
                      ? const Center(child: Text('지도 위치를 변환하는 중입니다...'))
                      : GoogleMap(
                          mapType: MapType.normal,
                          initialCameraPosition: CameraPosition(target: _targetCoordinates!, zoom: 16.0),
                          markers: _markers,
                          onMapCreated: (controller) => _mapController = controller,
                        ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                          final address = data['address'] as String?;
                          if (address != null && address.isNotEmpty) {
                            // 주소 문자열을 URL에 사용 가능하도록 인코딩합니다.
                            final query = Uri.encodeComponent(address);
                            // Google Maps 검색을 위한 표준 URL 형식입니다.
                            final url = 'https://www.google.com/maps/search/?api=1&query=$query';
                            _launchUrl(url);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('주소 정보가 없어 지도를 열 수 없습니다.')),
                            );
                          }
                        },
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Google Maps에서 보기'),
                  ),
                ),
                const Divider(height: 32),
                const Text('Contact Us', style: TextStyle(fontWeight: FontWeight.bold)),
                ListTile(leading: const Icon(Icons.phone_outlined), title: Text(data['phone'] ?? ''), onTap: () => _launchUrl('tel:${data['phone']}')),
                ListTile(leading: const Icon(Icons.email_outlined), title: Text(data['email'] ?? ''), onTap: () => _launchUrl('mailto:${data['email']}')),
                ListTile(leading: const Icon(Icons.chat_bubble_outline), title: const Text('카카오톡 채널로 문의'), onTap: () => _launchUrl(data['kakaoLink'] ?? '')),
              ],
            ),
          );
        },
      ),
    );
  }
}
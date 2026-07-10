import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  // 📌 當前這台手機安裝的本地版本號（每次你改了介面、重新打包 APK 時，記得手動在這裡把號碼改大）
  static const String currentLocalVersion = "1.0.1";

  static Future<void> checkVersion(BuildContext context) async {
    try {
      // 遠端向 Firebase 撈取最新版號資訊
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('system')
          .doc('version_control')
          .get();

      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      String latestVersion = data['latestVersion'] ?? currentLocalVersion;
      String downloadUrl = data['downloadUrl'] ?? "";

      // 比對版本號。如果不一致，就觸發高級感彈窗
      if (latestVersion != currentLocalVersion && downloadUrl.isNotEmpty) {
        if (!context.mounted) return;
        _showUpdateDialog(context, latestVersion, downloadUrl);
      }
    } catch (e) {
      debugPrint("檢查更新時發生錯誤: $e");
    }
  }

  static void _showUpdateDialog(BuildContext context, String newVersion, String url) {
    showDialog(
      context: context,
      barrierDismissible: false, // 強制對齊更新，不能點擊外面關閉
      builder: (ctx) => Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.82,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 36, offset: const Offset(0, 12))
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 彈窗標頭
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                  color: const Color(0xFFFBFBFB),
                  child: const Row(
                    children: [
                      Icon(Icons.system_update_alt_rounded, color: Color(0xFF2D3436), size: 20),
                      const SizedBox(width: 12),
                      Text("NEW VERSION AVAILABLE", style: TextStyle(fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
                    ],
                  ),
                ),
                // 彈窗內文
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("發現新版本 v$newVersion", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2D3436))),
                      const SizedBox(height: 10),
                      const Text(
                        "為了確保你與對手擁有相同的對決規則與最精緻的畫面體驗，請花費數秒進行升級覆蓋。",
                        style: TextStyle(fontSize: 13, color: Color(0xFF636E72), height: 1.6),
                      ),
                    ],
                  ),
                ),
                // 動作按鈕列
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  color: const Color(0xFFFBFBFB),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('LATER', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D3436),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () async {
                          final Uri downloadUri = Uri.parse(url);
                          if (await canLaunchUrl(downloadUri)) {
                            await launchUrl(downloadUri, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: const Text("UPDATE NOW", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ],
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
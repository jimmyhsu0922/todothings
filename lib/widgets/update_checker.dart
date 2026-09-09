import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  // 📌 當前這台手機安裝的本地版本號
  // 每次你改了介面、重新打包 APK 時，記得手動在這裡把號碼改大（例如 "2.0.1"）
  static const String currentLocalVersion = "2.2.2";

  static Future<void> checkVersion(BuildContext context) async {
    try {
      // 遠端向 Firebase 撈取最新版號資訊
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('system')
          .doc('version_control')
          .get();

      if (!snapshot.exists) {
        debugPrint("【更新檢查】Firebase 中找不到 system/version_control 設定文件");
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;
      String latestVersion = data['latestVersion'] ?? currentLocalVersion;
      String downloadUrl = data['downloadUrl'] ?? "";

      // 比對版本號。如果不一致且網址不為空，就觸發高級感彈窗
      if (latestVersion != currentLocalVersion && downloadUrl.isNotEmpty) {
        if (!context.mounted) return;
        _showUpdateDialog(context, latestVersion, downloadUrl);
      }
    } catch (e) {
      debugPrint("【更新檢查】檢查更新時發生錯誤: $e");
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
                BoxShadow(
                  color: Colors.black.withOpacity(0.08), 
                  blurRadius: 36, 
                  offset: const Offset(0, 12)
                )
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
                      SizedBox(width: 12),
                      Text(
                        "NEW VERSION AVAILABLE", 
                        style: TextStyle(fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))
                      ),
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
                          // 🎯 防呆優化 1：自動自動清除可能不小心打到的前後空白鍵
                          final String cleanUrl = url.trim();
                          final Uri downloadUri = Uri.parse(cleanUrl);
                          
                          try {
                            // 🎯 防呆優化 2：檢查網頁是否能開啟
                            // 強制使用外部瀏覽器開啟（避免在 GitHub App 內因權限問題撞牆）
                            bool launched = await launchUrl(
                              downloadUri,
                              mode: LaunchMode.externalApplication,
                            );

                            if (await canLaunchUrl(downloadUri)) {
                              await launchUrl(
                                downloadUri, 
                                mode: LaunchMode.externalApplication // 強制喚醒手機獨立瀏覽器（如 Chrome）
                              );
                            } else {
                              debugPrint("【更新提示】canLaunchUrl 回傳 false，嘗試強行呼叫外部瀏覽器開啟。");
                              
                              // 🎯 防呆優化 3：有時候 Android 系統會誤判，在此直接進行強行開啟嘗試
                              await launchUrl(
                                downloadUri, 
                                mode: LaunchMode.externalApplication
                              );
                            }
                          } catch (e) {
                            debugPrint("【更新錯誤】無法跳轉至網址，原因: $e");
                            
                            // 畫面上彈出一個簡單的小提示，告訴使用者出錯了，不要讓他們呆等
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('無法開啟網頁，請手動至 GitHub 下載。錯誤: $e')),
                            );
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
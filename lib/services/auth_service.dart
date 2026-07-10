import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; 

class AuthService { 
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // 🎯 修正：恢復使用 .instance 以解決建構子不存在的紅字
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isInitialized = false;

  // 🎯 確保初始化，這能防止底層 Credential Manager 報錯
  Future<void> _initGoogleSignIn() async {
    if (!_isInitialized) {
      await _googleSignIn.initialize(); 
      _isInitialized = true;
    }
  }

  // 監聽目前的登入狀態
  Stream<User?> get userStream => _auth.authStateChanges();

  // 訪客登入邏輯
  Future<User?> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      return userCredential.user; 
    } catch (e) {
      print("訪客登入失敗報錯原因: $e");
      return null;
    }
  }

  // 🎯 完美符合 v7.2.0 的 Google 登入邏輯
  Future<User?> signInWithGoogle() async {
    try { 
      await _initGoogleSignIn();

      // v7 版觸發登入的方法是 authenticate()，不再是 signIn()
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      
      if (googleUser == null) return null; 

      // 取得驗證資料
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication; 

      // v7 配合 Firebase 的標準寫法：傳入 idToken
      final AuthCredential credential = GoogleAuthProvider.credential( 
        idToken: googleAuth.idToken, 
      ); 

      // 正式登入 Firebase Authentication
      final UserCredential userCredential = await _auth.signInWithCredential(credential); 
      
      return userCredential.user; 
    } catch (e) { 
      print("Google v7 登入失敗報錯原因: $e"); 
      return null; 
    } 
  } 

  // 登出功能
  Future<void> signOut() async {
    try {
      await _initGoogleSignIn();
      await _googleSignIn.signOut();
    } catch (e) {
      print("Google 登出快取失敗: $e");
    }
    await _auth.signOut();
  }
}
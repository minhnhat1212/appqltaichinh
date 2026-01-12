import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth để xác thực
import 'package:google_sign_in/google_sign_in.dart'; // Import Google Sign In
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/foundation.dart'
    show kIsWeb; // Import kIsWeb để kiểm tra platform

/// Service xử lý xác thực người dùng
/// Hỗ trợ: Email/Password, Google Sign In, Sign Out, Reset Password
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instance Firebase Auth
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Instance Google Sign In
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Instance Firestore

  Stream<User?> get authStateChanges =>
      _auth.authStateChanges(); // Stream theo dõi trạng thái đăng nhập
  User? get currentUser => _auth.currentUser; // Lấy user hiện tại

  /// Đăng nhập bằng Email và Password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Đăng ký tài khoản mới bằng Email và Password
  /// Tự động khởi tạo user document và ví mặc định
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (cred.user != null) {
      final batch = _firestore.batch(); // Sử dụng batch để ghi nhanh hơn
      final userId = cred.user!.uid;

      // 1. Tạo user document
      batch.set(_firestore.collection('users').doc(userId), {
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'currency': 'VND', // Tiền tệ mặc định
      }, SetOptions(merge: true));

      // 2. Khởi tạo ví mặc định
      final defaultWallets = [
        {
          'name': 'Tiền mặt',
          'balance': 0.0,
          'icon': '💰',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Ngân hàng',
          'balance': 0.0,
          'icon': '🏦',
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      for (var wallet in defaultWallets) {
        batch.set(
          _firestore
              .collection('users')
              .doc(userId)
              .collection('wallets')
              .doc(), // Tạo document ID tự động
          wallet,
        );
      }

      // Commit tất cả thay đổi trong một lần (nhanh hơn nhiều lần write riêng lẻ)
      try {
        await batch.commit();
      } catch (e) {
        print("Error initializing user data: $e");
        // Không fail registration nếu không tạo được defaults
      }
    }
    return cred;
  }

  /// Đăng nhập bằng Google
  /// Hỗ trợ cả Web (popup) và Native (native flow)
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      // Web: Sử dụng signInWithPopup
      GoogleAuthProvider authProvider = GoogleAuthProvider();
      final UserCredential cred = await _auth.signInWithPopup(authProvider);

      if (cred.user != null) {
        final userId = cred.user!.uid;
        final userDocRef = _firestore.collection('users').doc(userId);

        // Set user doc với merge (không await để login nhanh hơn)
        userDocRef
            .set({
              'email': cred.user!.email,
              'createdAt': FieldValue.serverTimestamp(),
              'currency': 'VND',
            }, SetOptions(merge: true))
            .catchError((e) {
              print("Error setting user doc: $e");
            });

        // Khởi tạo ví trong background (non-blocking)
        _initializeUserWalletsIfNeeded(userId).catchError((e) {
          print("Error initializing wallets in background: $e");
        });
      }
      return cred;
    }

    // Native Platforms (Android/iOS)
    final GoogleSignInAccount? googleUser = await _googleSignIn
        .signIn(); // Hiển thị màn hình chọn tài khoản Google
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'ABORTED',
        message: 'Sign in aborted by user',
      );
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication; // Lấy token

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential cred = await _auth.signInWithCredential(
      credential,
    ); // Đăng nhập Firebase

    if (cred.user != null) {
      final userId = cred.user!.uid;
      // Set user doc (non-blocking để login nhanh hơn)
      _firestore
          .collection('users')
          .doc(userId)
          .set({
            'email': cred.user!.email,
            'createdAt': FieldValue.serverTimestamp(),
            'currency': 'VND',
          }, SetOptions(merge: true))
          .catchError((e) {
            print("Error setting user doc: $e");
          });

      // Khởi tạo ví trong background (non-blocking)
      _initializeUserWalletsIfNeeded(userId).catchError((e) {
        print("Error initializing wallets in background: $e");
      });
    }

    return cred;
  }

  /// Helper method để khởi tạo ví trong background (non-blocking)
  /// Chỉ tạo ví nếu user chưa có ví nào
  Future<void> _initializeUserWalletsIfNeeded(String userId) async {
    try {
      // Kiểm tra xem user đã có ví chưa
      final walletsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wallets')
          .limit(1) // Chỉ cần kiểm tra 1 document
          .get();

      // Chỉ khởi tạo nếu user chưa có ví
      if (walletsSnapshot.docs.isEmpty) {
        final batch = _firestore.batch();
        final defaultWallets = [
          {
            'name': 'Tiền mặt',
            'balance': 0.0,
            'icon': '💰',
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'name': 'Ngân hàng',
            'balance': 0.0,
            'icon': '🏦',
            'createdAt': FieldValue.serverTimestamp(),
          },
        ];

        for (var wallet in defaultWallets) {
          batch.set(
            _firestore
                .collection('users')
                .doc(userId)
                .collection('wallets')
                .doc(),
            wallet,
          );
        }

        await batch.commit();
      }
    } catch (e) {
      // Silently fail - ví sẽ được tạo sau nếu cần
      print("Error in _initializeUserWalletsIfNeeded: $e");
    }
  }

  /// Đăng xuất
  /// Đăng xuất cả Google và Firebase
  Future<void> signOut() async {
    await _googleSignIn.signOut(); // Đăng xuất Google
    await _auth.signOut(); // Đăng xuất Firebase
  }

  /// Gửi email reset mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Cập nhật tên hiển thị và ảnh đại diện
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    if (currentUser != null) {
      if (displayName != null) {
        await currentUser!.updateDisplayName(displayName);
      }
      if (photoURL != null) await currentUser!.updatePhotoURL(photoURL);
    }
  }

  /// Cập nhật tiền tệ trong Firestore
  Future<void> updateCurrency(String currency) async {
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'currency': currency,
      });
    }
  }

  /// Lấy stream dữ liệu user từ Firestore
  /// Return: Stream chứa currency và các thông tin khác
  Stream<DocumentSnapshot> getUserStream() {
    if (currentUser != null) {
      return _firestore.collection('users').doc(currentUser!.uid).snapshots();
    }
    return const Stream.empty(); // Trả về stream rỗng nếu chưa đăng nhập
  }
}

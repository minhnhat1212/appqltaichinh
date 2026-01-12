# Hướng Dẫn Kiểm Tra Dữ Liệu Firebase

## Cách 1: Kiểm tra qua Firebase Console (Khuyên dùng) 🌐

### Bước 1: Truy cập Firebase Console
1. Mở trình duyệt và vào: https://console.firebase.google.com/
2. Đăng nhập bằng tài khoản Google của bạn
3. Chọn project: **appqltaichinh** (Project ID: appqltaichinh)

### Bước 2: Vào Firestore Database
1. Trong menu bên trái, click vào **"Firestore Database"** hoặc **"Build" > "Firestore Database"**
2. Bạn sẽ thấy giao diện Firestore với danh sách các collection

### Bước 3: Xem các Collection
Dự án của bạn có các collection chính sau:

#### 📁 **users** (Người dùng)
- Mỗi document là một user với ID = User ID (từ Firebase Auth)
- Trong mỗi user document có subcollection **wallets** (ví tiền)
- Cấu trúc:
  ```
  users/
    {userId}/
      - email: string
      - createdAt: timestamp
      - currency: string (VD: "VND")
      wallets/ (subcollection)
        {walletId}/
          - name: string
          - icon: string
          - balance: number
          - createdAt: timestamp
  ```

#### 💰 **transactions** (Giao dịch)
- Mỗi document là một giao dịch (thu/chi)
- Các trường chính:
  - userId: string
  - walletId: string
  - categoryId: string
  - type: "income" | "expense"
  - amount: number
  - date: timestamp
  - description: string

#### 📊 **budgets** (Ngân sách)
- Mỗi document là một ngân sách
- Các trường: userId, categoryId, amount, startDate, endDate, period, isRecurring

#### 🎯 **savings_goals** (Mục tiêu tiết kiệm)
- Mỗi document là một mục tiêu tiết kiệm
- Có subcollection **contributions** (khoản đóng góp)

#### 🏷️ **categories** (Danh mục)
- Các danh mục thu/chi mặc định

### Bước 4: Lọc và Tìm kiếm
- Click vào collection để xem danh sách documents
- Sử dụng thanh tìm kiếm để filter documents
- Click vào document để xem chi tiết các trường (fields)
- Click vào subcollection để xem dữ liệu con

### Bước 5: Sửa/Xóa dữ liệu (Nếu cần)
- Click vào một document để chỉnh sửa
- Click vào biểu tượng bút chì để sửa field
- Click vào biểu tượng thùng rác để xóa document
- ⚠️ **Cẩn thận**: Xóa dữ liệu có thể ảnh hưởng đến ứng dụng

---

## Cách 2: Sử dụng Firebase CLI 🔧

### Cài đặt Firebase CLI
```bash
npm install -g firebase-tools
```

### Đăng nhập
```bash
firebase login
```

### Xem dữ liệu từ command line
```bash
# Xem tất cả collections
firebase firestore:get

# Export dữ liệu
firebase firestore:export gs://your-bucket-name/backup
```

---

## Cách 3: Kiểm tra từ Code (Debug) 💻

Xem file `lib/utils/firebase_debug_helper.dart` để có script debug trong ứng dụng.

### Sử dụng trong code:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

// In tất cả users
final users = await FirebaseFirestore.instance.collection('users').get();
for (var doc in users.docs) {
  print('User ID: ${doc.id}');
  print('Data: ${doc.data()}');
}
```

---

## Lưu ý quan trọng ⚠️

1. **Quyền truy cập**: Đảm bảo bạn có quyền truy cập vào Firebase project
2. **Firestore Rules**: Kiểm tra Firestore Security Rules nếu không thấy dữ liệu
3. **Index**: Một số query cần composite index, Firebase sẽ gợi ý tạo index
4. **Backup**: Nên export dữ liệu trước khi thực hiện thay đổi lớn

---

## Cấu trúc Database tổng quan

```
Firestore Database
├── users/
│   └── {userId}/
│       ├── email, createdAt, currency
│       └── wallets/ (subcollection)
│           └── {walletId}/
│               └── name, icon, balance, createdAt
├── transactions/
│   └── {transactionId}/
│       └── userId, walletId, categoryId, type, amount, date, description
├── budgets/
│   └── {budgetId}/
│       └── userId, categoryId, amount, startDate, endDate, period, isRecurring
├── savings_goals/
│   └── {goalId}/
│       ├── userId, name, targetAmount, currentAmount, targetDate
│       └── contributions/ (subcollection)
│           └── {contributionId}/
│               └── amount, date
└── categories/
    └── {categoryId}/
        └── name, icon, type, userId
```

---

## Liên kết hữu ích 🔗

- Firebase Console: https://console.firebase.google.com/project/appqltaichinh
- Firestore Documentation: https://firebase.google.com/docs/firestore
- Firestore Rules: https://console.firebase.google.com/project/appqltaichinh/firestore/rules


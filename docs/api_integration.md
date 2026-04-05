# 🔗 API & Tích hợp — G13 Money

Tài liệu này mô tả chi tiết các tích hợp bên ngoài của ứng dụng G13 Money.

---

## 1. Google Gemini AI

### 1.1 Tổng quan

G13 Money tích hợp **Google Gemini AI** để cung cấp hai tính năng chính:
- **Gợi ý tài chính tự động**: Phân tích dữ liệu thu chi và đưa ra 3 gợi ý hành động
- **Chat trợ lý AI**: Trò chuyện tương tác với AI về vấn đề tài chính

### 1.2 Cấu hình

```json
// flutter.env.json
{
  "GEMINI_API_KEY": "<your-api-key>",
  "GEMINI_MODEL": "gemini-1.5-flash"
}
```

**Lấy API key**: [Google AI Studio](https://aistudio.google.com/apikey)

### 1.3 API Endpoint

```
POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={apiKey}
```

### 1.4 Chức năng `generateAdvice()`

Phân tích dữ liệu tài chính và tạo 3 gợi ý cá nhân hóa.

**Input:**
| Tham số | Kiểu | Mô tả |
|---|---|---|
| `transactions` | `List<MoneyTransaction>` | Toàn bộ giao dịch |
| `wallets` | `List<Account>` | Danh sách ví/tài khoản |

**Dữ liệu gửi đến AI:**
- Số dư hiện tại tổng hợp
- Thu nhập tháng hiện tại
- Chi tiêu tháng hiện tại
- Top 3 danh mục chi lớn nhất
- Tổng số giao dịch

**Prompt template:**
```
Bạn là cố vấn tài chính cá nhân cho người dùng Việt Nam.
Hãy trả lời bằng tiếng Việt, ngắn gọn, rõ ràng.
Đưa ra đúng 3 gợi ý hành động cụ thể, đánh số 1-3.
Mỗi gợi ý tối đa 2 câu, ưu tiên thực tế và dễ làm trong 7 ngày.
```

### 1.5 Chức năng `chatWithAssistant()`

Chat tương tác với AI trợ lý tài chính.

**Input:**
| Tham số | Kiểu | Mô tả |
|---|---|---|
| `userMessage` | `String` | Tin nhắn người dùng |
| `recentMessages` | `List<String>` | Lịch sử chat gần đây |
| `transactions` | `List<MoneyTransaction>` | Giao dịch để AI tham chiếu |
| `wallets` | `List<Account>` | Ví/tài khoản |

### 1.6 Fallback Strategy

Khi AI không khả dụng (không có API key, lỗi mạng, timeout), hệ thống tự động chuyển sang phân tích local:

```
AI Available?
├── Yes → Gọi Gemini API (timeout 20s)
│   ├── Success → Trả về kết quả AI
│   └── Error → Fallback local
└── No → Fallback local ngay lập tức
```

**Fallback local** phân tích:
- Tỷ lệ chi/thu (cảnh báo nếu > 85%)
- Danh mục chi cao nhất
- Tình trạng số dư (âm hay dương)
- Keyword matching cho chat (ngân sách, tiết kiệm, chi tiêu)

---

## 2. Firebase Services

### 2.1 Firebase Authentication

**Phương thức xác thực:** Email/Password

| Chức năng | Method |
|---|---|
| Đăng nhập | `AuthService.login(email, password)` |
| Đăng ký | `AuthService.register(fullName, phone, email, password)` |
| Đăng xuất | `AuthService.logout()` |
| Khôi phục phiên | `AuthService.restoreSession()` |
| Đổi mật khẩu | `AuthService.changePassword(old, new)` |
| Cập nhật hồ sơ | `AuthService.updateCurrentUserProfile(...)` |

**Khi đăng ký mới**, hệ thống tự động tạo:
1. User document trong `users/{uid}`
2. Profile settings: `users/{uid}/settings/profile`
3. Preferences: `users/{uid}/settings/preferences`
4. 11 danh mục mặc định: `users/{uid}/categories/*`
   - Chi tiêu: Ăn uống, Di chuyển, Mua sắm, Nhà ở, Giải trí, Sức khỏe, Giáo dục, Hóa đơn
   - Thu nhập: Lương, Thưởng, Thu nhập khác

### 2.2 Cloud Firestore

**Cấu trúc dữ liệu:** Xem chi tiết tại [Firestore Schema](firestore_schema.md)

**Security Rules Summary:**
```javascript
// Mỗi user chỉ đọc/ghi dữ liệu của mình
match /users/{userId} {
  allow read, write: if request.auth.uid == userId;
  match /{document=**} {
    allow read, write: if request.auth.uid == userId;
  }
}
```

### 2.3 Firebase Cloud Messaging (FCM)

**Khởi tạo:** `PushNotificationService.initialize()` được gọi trong `main()`.

**Chức năng:**
- Nhận push notification cho cảnh báo ngân sách
- Nhận thông báo giao dịch mới từ SePay
- Quản lý FCM token

### 2.4 Firebase Cloud Functions

Chứa SePay webhook handler. Xem chi tiết tại [SePay Setup](sepay_setup.md).

---

## 3. Supabase Storage

### 3.1 Mục đích

Lưu trữ file (ảnh đại diện, ảnh hóa đơn giao dịch) với Supabase Storage thay cho Firebase Storage cho một số use case.

### 3.2 Cấu hình

```json
// flutter.env.json
{
  "SUPABASE_URL": "https://xxx.supabase.co",
  "SUPABASE_ANON_KEY": "eyJ..."
}
```

### 3.3 Khởi tạo

```dart
// main.dart
await SupabaseStorageService.initialize();
```

---

## 4. SePay Webhook

### 4.1 Tổng quan

SePay cho phép nhận webhook khi có giao dịch ngân hàng mới, tự động ghi nhận vào hệ thống.

### 4.2 Hai phương thức triển khai

| Phương thức | Ưu điểm | Nhược điểm |
|---|---|---|
| **Firebase Functions** | Dễ deploy, cùng hệ sinh thái | Cần Blaze plan |
| **Cloudflare Workers** | Miễn phí, không cần Blaze | Cần cấu hình thêm |

### 4.3 Luồng xử lý

```
SePay POST → Verify token → Lookup binding → Write:
  → users/{uid}/transactions/sepay_{id}
  → users/{uid}/notifications/sepay_{id}_notification
  → sepay_events/sepay_{id}  (audit log)
```

### 4.4 Tài liệu chi tiết

- [SePay Firebase Functions Setup](sepay_setup.md)
- [SePay Cloudflare Workers Setup](sepay_cloudflare_worker.md)

---

## 5. Xác thực Sinh trắc học

### 5.1 Thư viện

Package `local_auth` (v2.3.0)

### 5.2 Chức năng

```dart
class BiometricAuthService {
  static Future<bool> isAvailable() async { ... }
  static Future<bool> authenticate() async { ... }
}
```

- Kiểm tra thiết bị có hỗ trợ sinh trắc học
- Xác thực bằng vân tay hoặc FaceID
- Sử dụng khi mở app có session đã lưu (quick login)

---

## 6. Biểu đồ (fl_chart)

### 6.1 Các loại biểu đồ

| Loại | Trang | Mô tả |
|---|---|---|
| **Bar Chart** | `OverviewPage` | Thu/chi theo tháng |
| **Pie Chart** | `ReportsScreen` | Phân bổ chi tiêu theo danh mục |

### 6.2 Thư viện

Package `fl_chart` (v0.70.2) — Biểu đồ hiệu năng cao cho Flutter.

---

## 7. Tóm tắt Environment Variables

| Biến | Bắt buộc | Mô tả |
|---|---|---|
| `GEMINI_API_KEY` | Không | API key cho Gemini AI (có fallback local) |
| `GEMINI_MODEL` | Không | Model Gemini (mặc định: `gemini-1.5-flash`) |
| `SUPABASE_URL` | Có | URL Supabase project |
| `SUPABASE_ANON_KEY` | Có | Anonymous key Supabase |

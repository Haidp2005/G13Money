<p align="center">
  <img src="assets/icons/app_icon.png" alt="G13 Money" width="120"/>
</p>

<h1 align="center">G13 Money</h1>

<p align="center">
  <b>Ứng dụng quản lý tài chính cá nhân thông minh</b><br/>
  <i>Smart Personal Finance Management App</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart" alt="Dart"/>
  <img src="https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20Storage-FFCA28?logo=firebase" alt="Firebase"/>
  <img src="https://img.shields.io/badge/Supabase-Storage-3ECF8E?logo=supabase" alt="Supabase"/>
  <img src="https://img.shields.io/badge/Gemini%20AI-Integrated-4285F4?logo=google" alt="Gemini AI"/>
  <img src="https://img.shields.io/badge/version-1.0.0-brightgreen" alt="Version"/>
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License"/>
</p>

---

## 📖 Giới thiệu

**G13 Money** là ứng dụng quản lý tài chính cá nhân được xây dựng bằng Flutter, hỗ trợ đa nền tảng (Android, iOS, Web, Desktop). Ứng dụng giúp người dùng theo dõi thu chi hàng ngày, quản lý ngân sách, phân tích tài chính qua biểu đồ, và nhận tư vấn tài chính thông minh từ AI.

### Tại sao chọn G13 Money?

- 🎨 **Giao diện hiện đại** — Material Design 3 với hỗ trợ Light/Dark theme
- 🌐 **Đa ngôn ngữ** — Tiếng Việt & English
- 🤖 **Tích hợp AI** — Tư vấn tài chính cá nhân hóa bằng Gemini AI
- 🔔 **Thông báo thông minh** — Cảnh báo chi tiêu vượt ngân sách
- 🏦 **Tích hợp ngân hàng** — Tự động ghi nhận giao dịch qua SePay webhook
- 🔒 **Bảo mật** — Xác thực sinh trắc học & mã hóa dữ liệu

---

## ✨ Tính năng chính

| Tính năng | Mô tả |
|---|---|
| 📊 **Tổng quan tài chính** | Dashboard hiển thị tổng thu, chi, số dư theo tháng với biểu đồ cột |
| 💰 **Quản lý giao dịch** | Thêm, sửa, xóa giao dịch thu/chi/nợ với đầy đủ thông tin |
| 📁 **Danh mục tùy chỉnh** | Tạo và quản lý danh mục giao dịch theo ý thích |
| 💳 **Đa ví/tài khoản** | Quản lý nhiều ví tiền, tài khoản ngân hàng, ví điện tử |
| 📈 **Báo cáo chi tiết** | Biểu đồ tròn phân tích chi tiêu theo danh mục, so sánh thu/chi |
| 🎯 **Ngân sách** | Đặt hạn mức chi tiêu theo danh mục với thanh tiến độ |
| 🤖 **Trợ lý AI** | Chat tư vấn tài chính & gợi ý tiết kiệm bằng Gemini AI |
| 🔔 **Thông báo** | Cảnh báo vượt ngân sách, nhắc nhập giao dịch hàng ngày |
| 🏦 **SePay Webhook** | Tự động ghi nhận giao dịch ngân hàng qua SePay |
| 👤 **Quản lý hồ sơ** | Chỉnh sửa thông tin cá nhân, ảnh đại diện |
| 🔐 **Bảo mật** | Đăng nhập bằng email/mật khẩu, xác thực sinh trắc học |
| 🌙 **Dark Mode** | Hỗ trợ giao diện sáng/tối |
| 🌐 **Đa ngôn ngữ** | Tiếng Việt & English |

---

## 🏗️ Kiến trúc dự án

Dự án sử dụng kiến trúc **Feature-First** kết hợp với **Riverpod** cho state management:

```
lib/
├── main.dart                          # Entry point
├── firebase_options.dart              # Firebase config (auto-gen)
├── app/
│   ├── app.dart                       # MaterialApp, theme, routes
│   └── routes.dart                    # Định tuyến tập trung
├── core/
│   ├── models/                        # Data models dùng chung
│   │   ├── user_model.dart            # Model người dùng
│   │   └── app_notification.dart      # Model thông báo
│   ├── services/                      # Business logic & API services
│   │   ├── auth_service.dart          # Xác thực Firebase Auth
│   │   ├── ai_finance_service.dart    # Tích hợp Gemini AI
│   │   ├── biometric_auth_service.dart# Xác thực sinh trắc học
│   │   ├── language_service.dart      # Đa ngôn ngữ (vi/en)
│   │   ├── theme_service.dart         # Quản lý theme sáng/tối
│   │   ├── notification_service.dart  # Thông báo local
│   │   ├── push_notification_service.dart # Push notification (FCM)
│   │   └── supabase_storage_service.dart  # Lưu trữ file Supabase
│   └── state/
│       └── app_settings_providers.dart # Riverpod providers cài đặt
├── features/
│   ├── auth/                          # 🔐 Xác thực
│   │   ├── ui/
│   │   │   ├── splash_screen.dart     # Splash screen có animation
│   │   │   └── login_page.dart        # Đăng nhập/Đăng ký
│   │   └── state/
│   ├── overview/                      # 📊 Tổng quan
│   │   ├── ui/
│   │   │   ├── overview_page.dart     # Dashboard tài chính
│   │   │   └── ai_chat_page.dart      # Chat với AI trợ lý
│   │   └── state/
│   ├── transactions/                  # 💰 Giao dịch
│   │   ├── models/transaction.dart    # Model giao dịch
│   │   ├── data/transactions_repository.dart # Firestore CRUD
│   │   ├── ui/
│   │   │   ├── transaction_screen.dart        # Danh sách giao dịch
│   │   │   ├── add_transaction_form_page.dart # Form thêm/sửa
│   │   │   ├── transaction_detail_page.dart   # Chi tiết giao dịch
│   │   │   └── reports_screen.dart            # Báo cáo & biểu đồ
│   │   └── state/
│   ├── budgets/                       # 🎯 Ngân sách
│   │   ├── models/budget.dart         # Model ngân sách
│   │   ├── data/budgets_repository.dart # Firestore CRUD
│   │   ├── ui/
│   │   │   ├── budgets_page.dart      # Danh sách ngân sách
│   │   │   └── budget_form.dart       # Form thêm/sửa ngân sách
│   │   └── state/
│   ├── accounts/                      # 👤 Tài khoản & Cài đặt
│   │   ├── models/
│   │   │   ├── account.dart           # Model ví/tài khoản
│   │   │   └── category_item.dart     # Model danh mục
│   │   ├── data/
│   │   │   ├── accounts_repository.dart   # CRUD ví
│   │   │   └── categories_repository.dart # CRUD danh mục
│   │   ├── ui/
│   │   │   ├── accounts_page.dart             # Trang cài đặt/hồ sơ
│   │   │   ├── edit_profile_page.dart         # Chỉnh sửa hồ sơ
│   │   │   ├── change_password_page.dart      # Đổi mật khẩu
│   │   │   ├── manage_wallets_page.dart       # Quản lý ví
│   │   │   ├── manage_categories_page.dart    # Quản lý danh mục
│   │   │   ├── notification_settings_page.dart# Cài đặt thông báo
│   │   │   ├── notifications_page.dart        # Danh sách thông báo
│   │   │   └── about_page.dart                # Giới thiệu ứng dụng
│   │   └── state/
│   └── shared/                        # 🧩 Dùng chung
│       ├── ui/main_shell_page.dart    # Shell chính (Bottom Nav)
│       └── widgets/
│           ├── bottom_nav.dart        # Bottom navigation bar
│           └── category_helper.dart   # Helper icon/màu danh mục
```

---

## 🛠️ Công nghệ sử dụng

### Frontend
| Công nghệ | Phiên bản | Mục đích |
|---|---|---|
| **Flutter** | 3.10+ | Framework UI đa nền tảng |
| **Dart** | 3.10+ | Ngôn ngữ lập trình |
| **flutter_riverpod** | 2.6.1 | State management |
| **fl_chart** | 0.70.2 | Biểu đồ (cột, tròn) |
| **Material Design 3** | — | Hệ thống thiết kế |

### Backend & Cloud
| Công nghệ | Mục đích |
|---|---|
| **Firebase Auth** | Xác thực người dùng (email/password) |
| **Cloud Firestore** | Cơ sở dữ liệu NoSQL realtime |
| **Firebase Storage** | Lưu trữ ảnh đại diện |
| **Firebase Cloud Messaging** | Push notification |
| **Firebase Cloud Functions** | SePay webhook handler |
| **Supabase Storage** | Lưu trữ file bổ sung |
| **Cloudflare Workers** | SePay webhook (alternative) |

### AI & Tích hợp
| Công nghệ | Mục đích |
|---|---|
| **Google Gemini AI** | Tư vấn tài chính & chat trợ lý |
| **SePay API** | Webhook nhận giao dịch ngân hàng tự động |

### Bảo mật
| Công nghệ | Mục đích |
|---|---|
| **local_auth** | Xác thực sinh trắc học (vân tay/FaceID) |
| **flutter_secure_storage** | Lưu trữ token an toàn |

---

## 🚀 Cài đặt & Chạy

### Yêu cầu hệ thống

- Flutter SDK ≥ 3.10
- Dart SDK ≥ 3.10
- Android Studio / VS Code
- Firebase project đã cấu hình
- (Tùy chọn) Gemini API key

### 1. Clone dự án

```bash
git clone https://github.com/Haidp2005/G13Money.git
cd G13Money
```

### 2. Cài đặt dependencies

```bash
flutter pub get
```

### 3. Cấu hình Firebase

Dự án đã bao gồm file `firebase_options.dart`. Nếu cần cấu hình lại:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-project-id>
```

### 4. Cấu hình biến môi trường

Tạo file `flutter.env.json` ở thư mục gốc:

```json
{
  "GEMINI_API_KEY": "<your-gemini-api-key>",
  "GEMINI_MODEL": "gemini-1.5-flash",
  "SUPABASE_URL": "<your-supabase-url>",
  "SUPABASE_ANON_KEY": "<your-supabase-anon-key>"
}
```

### 5. Chạy ứng dụng

```bash
# Chạy với biến môi trường
flutter run --dart-define-from-file=flutter.env.json

# Chạy trên thiết bị cụ thể
flutter run -d chrome --dart-define-from-file=flutter.env.json
flutter run -d android --dart-define-from-file=flutter.env.json
```

### 6. Build release

```bash
# Android APK
flutter build apk --dart-define-from-file=flutter.env.json

# Android App Bundle
flutter build appbundle --dart-define-from-file=flutter.env.json

# iOS
flutter build ios --dart-define-from-file=flutter.env.json

# Web
flutter build web --dart-define-from-file=flutter.env.json
```

---

## 📚 Tài liệu chi tiết

| Tài liệu | Mô tả |
|---|---|
| [📐 Kiến trúc hệ thống](docs/architecture.md) | Chi tiết kiến trúc, design patterns, luồng dữ liệu |
| [🗄️ Cơ sở dữ liệu](docs/firestore_schema.md) | Schema Firestore, collection/document, ER diagram |
| [🔗 API & Tích hợp](docs/api_integration.md) | Gemini AI, SePay webhook, Supabase, FCM |
| [📱 Hướng dẫn sử dụng](docs/user_guide.md) | Hướng dẫn từng tính năng cho người dùng cuối |
| [🏦 SePay Setup](docs/sepay_setup.md) | Cấu hình webhook SePay + Firebase Functions |
| [☁️ Cloudflare Worker](docs/sepay_cloudflare_worker.md) | Setup SePay qua Cloudflare Workers |

---

## 🔐 Bảo mật

- Dữ liệu người dùng được cách ly hoàn toàn (`users/{uid}/...`)
- Firestore Security Rules đảm bảo chỉ owner mới đọc/ghi dữ liệu
- Token xác thực Firebase Auth cho mọi request
- Xác thực sinh trắc học tùy chọn
- API key được quản lý qua biến môi trường, không hardcode

---

## 👥 Nhóm phát triển

**Nhóm G13** — Dự án môn học

---

## 📄 Giấy phép

Dự án được phát hành dưới giấy phép [MIT](LICENSE).

---

<p align="center">
  Được xây dựng với ❤️ bởi <b>Nhóm G13</b>
</p>

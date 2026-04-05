# 📱 Hướng dẫn sử dụng — G13 Money

Tài liệu hướng dẫn chi tiết cách sử dụng từng tính năng của ứng dụng G13 Money.

---

## Mục lục

1. [Bắt đầu sử dụng](#1-bắt-đầu-sử-dụng)
2. [Màn hình Tổng quan](#2-màn-hình-tổng-quan)
3. [Quản lý Giao dịch](#3-quản-lý-giao-dịch)
4. [Quản lý Ngân sách](#4-quản-lý-ngân-sách)
5. [Tài khoản & Cài đặt](#5-tài-khoản--cài-đặt)
6. [Trợ lý AI](#6-trợ-lý-ai)
7. [Thông báo](#7-thông-báo)

---

## 1. Bắt đầu sử dụng

### 1.1 Splash Screen

Khi mở ứng dụng, bạn sẽ thấy màn hình splash với logo G13 Money có hiệu ứng animation. Ứng dụng sẽ tự động:
- Kiểm tra phiên đăng nhập trước đó
- Nếu đã đăng nhập → chuyển đến Trang chủ
- Nếu chưa đăng nhập → chuyển đến Trang đăng nhập

### 1.2 Đăng ký tài khoản

1. Tại trang đăng nhập, nhấn **"Đăng ký"**
2. Điền thông tin:
   - **Họ và tên** (bắt buộc)
   - **Số điện thoại** (tùy chọn)
   - **Email** (bắt buộc)
   - **Mật khẩu** (tối thiểu 6 ký tự)
3. Nhấn **"Đăng ký"**
4. Hệ thống tự động tạo:
   - Tài khoản Firebase Auth
   - Hồ sơ người dùng
   - 11 danh mục giao dịch mặc định

### 1.3 Đăng nhập

1. Nhập **Email** và **Mật khẩu**
2. Nhấn **"Đăng nhập"**
3. Nếu thiết bị hỗ trợ sinh trắc học và đã đăng nhập trước đó:
   - Có thể sử dụng **vân tay/FaceID** để đăng nhập nhanh

### 1.4 Đăng nhập nhanh (Quick Login)

Khi đã đăng nhập trước đó, ứng dụng hiển thị giao diện đơn giản:
- Chỉ cần nhập **mật khẩu** hoặc dùng **sinh trắc học**
- Nhấn *"Đổi tài khoản"* để quay lại trang đăng nhập đầy đủ

---

## 2. Màn hình Tổng quan

Đây là trang chính khi mở app, hiển thị snapshot tài chính.

### 2.1 Thông tin hiển thị

| Mục | Mô tả |
|---|---|
| **Tổng số dư** | Tổng hợp số dư từ tất cả ví/tài khoản |
| **Thu nhập tháng** | Tổng thu nhập trong tháng hiện tại |
| **Chi tiêu tháng** | Tổng chi tiêu trong tháng hiện tại |
| **Biểu đồ cột** | So sánh thu/chi theo tháng |
| **Gợi ý AI** | 3 gợi ý tài chính cá nhân hóa (nếu có dữ liệu) |
| **Giao dịch gần đây** | 5 giao dịch mới nhất |

### 2.2 Các hành động

- **Nhấn vào biểu đồ** → Chuyển đến trang Báo cáo chi tiết
- **Nhấn vào giao dịch** → Xem chi tiết giao dịch
- **Nhấn icon AI** → Mở chat với trợ lý AI

---

## 3. Quản lý Giao dịch

### 3.1 Xem danh sách giao dịch

Tab **Giao dịch** (tab thứ 2) hiển thị:
- Danh sách giao dịch theo ngày (mới nhất trước)
- Bộ lọc theo thời gian, loại (thu/chi), danh mục
- Tìm kiếm theo tên giao dịch

### 3.2 Thêm giao dịch mới

1. Nhấn nút **"+"** ở giữa bottom navigation
2. Điền thông tin:

| Trường | Bắt buộc | Mô tả |
|---|---|---|
| **Tên giao dịch** | ✅ | Ví dụ: "Cà phê sáng" |
| **Số tiền** | ✅ | Nhập số tiền |
| **Loại** | ✅ | Chi tiêu / Thu nhập |
| **Danh mục** | ✅ | Chọn từ danh sách |
| **Ví** | ✅ | Chọn ví/tài khoản |
| **Ngày** | ✅ | Mặc định: hôm nay |
| **Ghi chú** | ❌ | Thông tin bổ sung |

3. Nhấn **"Lưu"**
4. Số dư ví sẽ tự động cập nhật

### 3.3 Sửa/Xóa giao dịch

- **Sửa**: Nhấn vào giao dịch → Nhấn icon chỉnh sửa
- **Xóa**: Nhấn vào giao dịch → Nhấn icon xóa → Xác nhận

### 3.4 Báo cáo tài chính

Tại tab Tổng quan hoặc trang Báo cáo:
- **Biểu đồ tròn**: Phân bổ chi tiêu theo danh mục (%)
- **Danh sách danh mục**: Số tiền & phần trăm từng danh mục
- **Chuyển tháng**: Xem báo cáo các tháng trước/sau

---

## 4. Quản lý Ngân sách

### 4.1 Xem ngân sách

Tab **Ngân sách** (tab thứ 4) hiển thị:
- Danh sách ngân sách đang hoạt động
- Thanh tiến độ chi tiêu (đã chi / hạn mức)
- Trạng thái: An toàn / Cảnh báo / Vượt ngân sách

### 4.2 Tạo ngân sách mới

1. Nhấn nút **"+"** hoặc **"Tạo ngân sách"**
2. Điền thông tin:

| Trường | Bắt buộc | Mô tả |
|---|---|---|
| **Tên ngân sách** | ✅ | Ví dụ: "Ăn uống tháng 4" |
| **Danh mục** | ✅ | Chọn danh mục áp dụng |
| **Hạn mức** | ✅ | Số tiền tối đa |
| **Ví** | ✅ | Ví áp dụng |
| **Thời gian** | ✅ | Ngày bắt đầu — Ngày kết thúc |

3. Nhấn **"Lưu"**

### 4.3 Theo dõi ngân sách

| Trạng thái | Mô tả |
|---|---|
| 🟢 **An toàn** | Đã chi < 80% hạn mức |
| 🟡 **Cảnh báo** | Đã chi 80–100% hạn mức |
| 🔴 **Vượt** | Đã chi > 100% hạn mức |

Hệ thống tự động gửi thông báo khi chi tiêu vượt 80% hạn mức.

---

## 5. Tài khoản & Cài đặt

### 5.1 Hồ sơ cá nhân

Nhấn tab **Tài khoản** (tab cuối) → Xem thông tin:
- Họ và tên
- Email
- Số điện thoại
- Ngày tham gia

**Chỉnh sửa**: Nhấn icon ✏️ ở góc phải trên.

### 5.2 Quản lý Ví/Tài khoản

Đường dẫn: Cài đặt → Ví/Tài khoản

- **Thêm ví mới**: Nhấn "+" → Điền tên, loại (tiền mặt/ngân hàng/ví điện tử), số dư ban đầu
- **Sửa ví**: Nhấn vào ví → Chỉnh sửa thông tin
- **Ẩn ví**: Soft delete (lưu trữ) — dữ liệu giao dịch không bị mất

### 5.3 Quản lý Danh mục

Đường dẫn: Cài đặt → Danh mục

- **Thêm danh mục**: Nhấn "+" → Chọn tên, icon, màu, loại (thu/chi)
- **Sửa danh mục**: Nhấn vào danh mục → Chỉnh sửa
- Danh mục mặc định không xóa được

### 5.4 Cài đặt thông báo

Đường dẫn: Cài đặt → Thông báo

| Tùy chọn | Mô tả |
|---|---|
| **Cảnh báo ngân sách** | Thông báo khi vượt hạn mức |
| **Nhắc nhập giao dịch** | Nhắc ghi chép hàng ngày |
| **Nhắc hóa đơn** | Nhắc thanh toán hóa đơn |
| **Thông báo giao dịch** | Thông báo khi SePay nhận được giao dịch |

### 5.5 Đổi mật khẩu

Đường dẫn: Cài đặt → Bảo mật

1. Nhập mật khẩu hiện tại
2. Nhập mật khẩu mới (≥ 6 ký tự)
3. Xác nhận mật khẩu mới
4. Nhấn **"Lưu"**

### 5.6 Ngôn ngữ

Đường dẫn: Cài đặt → Ngôn ngữ

- **Tiếng Việt** (mặc định)
- **English**

Thay đổi có hiệu lực ngay lập tức cho toàn bộ ứng dụng.

### 5.7 Giao diện

Đường dẫn: Cài đặt → Giao diện

- **Chủ đề sáng** (Light)
- **Chủ đề tối** (Dark)

### 5.8 Giới thiệu ứng dụng

Đường dẫn: Cài đặt → Giới thiệu ứng dụng

Xem thông tin chi tiết về ứng dụng:
- Mô tả ứng dụng
- Các tính năng nổi bật
- Nhóm phát triển
- Thông tin phiên bản

### 5.9 Đăng xuất

Nhấn **"Đăng xuất"** ở cuối trang Tài khoản → Xác nhận.

---

## 6. Trợ lý AI

### 6.1 Gợi ý tự động

Tại trang Tổng quan, nếu bạn có dữ liệu giao dịch, AI sẽ tự động:
- Phân tích xu hướng chi tiêu
- Đưa ra 3 gợi ý hành động cụ thể
- Cập nhật theo dữ liệu mới nhất

### 6.2 Chat với AI

1. Nhấn icon AI tại trang Tổng quan
2. Nhập câu hỏi, ví dụ:
   - *"Mình nên tiết kiệm bao nhiêu mỗi tháng?"*
   - *"Danh mục nào đang chi quá tay?"*
   - *"Lập ngân sách tuần này giúp mình"*
3. AI sẽ trả lời dựa trên dữ liệu tài chính thực tế của bạn

> **Lưu ý**: Khi không có kết nối AI (hoặc chưa cấu hình API key), hệ thống vẫn hoạt động bình thường với phân tích local.

---

## 7. Thông báo

### 7.1 Các loại thông báo

| Loại | Mô tả |
|---|---|
| 🔔 **Cảnh báo ngân sách** | Khi chi tiêu vượt 80% hoặc 100% hạn mức |
| 📝 **Nhắc giao dịch** | Nhắc ghi chép thu chi hàng ngày |
| 💰 **Giao dịch SePay** | Khi nhận được giao dịch ngân hàng tự động |
| 🔧 **Hệ thống** | Thông báo chung từ ứng dụng |

### 7.2 Xem thông báo

Đường dẫn: Cài đặt → Thông báo → Xem danh sách thông báo

- Thông báo chưa đọc được đánh dấu nổi bật
- Nhấn vào thông báo để đánh dấu đã đọc

---

## 8. Mẹo sử dụng hiệu quả

1. **Ghi chép ngay**: Thêm giao dịch ngay khi phát sinh để không quên
2. **Đặt ngân sách**: Tạo ngân sách cho các danh mục chi lớn
3. **Kiểm tra thường xuyên**: Xem trang Tổng quan hàng tuần
4. **Hỏi AI**: Sử dụng trợ lý AI để nhận tư vấn cá nhân hóa
5. **Phân loại đúng**: Chọn đúng danh mục cho mỗi giao dịch để báo cáo chính xác
6. **Dùng nhiều ví**: Tách ví tiền mặt, ngân hàng, ví điện tử để theo dõi dễ hơn

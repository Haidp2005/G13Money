# Transactions Feature

Contains UI and models for transaction list and entry.

## Kiến trúc thư mục
- `models/`: Định nghĩa các cấu trúc dữ liệu giao dịch.
- `ui/`: Các giao diện tương tác người dùng.

## Tổng quan các File

### `ui/transactions_page.dart` (Màn hình Sổ giao dịch / Lịch sử giao dịch)
Đây là màn hình chính đại diện cho tính năng Lịch sử giao dịch, được code hoàn toàn theo thiết kế Dark Mode cao cấp.

**Nhiệm vụ chính:**
1. **Header & Amount Display**: Quản lý và hiển thị Số dư tổng quát cỡ lớn, thanh điều hướng trạng thái thời gian (Tháng này, Tháng trước), cùng với tiện ích thanh điều hướng trên cùng (Search, More).
2. **Summary Card**: Chịu trách nhiệm render dòng thông tin thu chi (Tiền vào, Tiền ra) kết hợp với đường link tắt "Xem báo cáo".
3. **Transaction List Structure**: Sử dụng cấu trúc linh hoạt kết hợp giữa `ListView.builder` cho danh sách cuộn dọc và `Column` cho dữ liệu dạng khối (group). Dữ liệu được bóc tách và nhóm gọn gàng theo từng ngày (Date block) hiển thị rất tường minh cho tài chính cá nhân.
4. **Bottom Navigation Bar**: Nơi gắn kết tính năng thanh điều hướng dưới đáy để người dùng tiện lợi nhảy qua các trang (Tổng quan, Thêm mới, Ngân sách...).

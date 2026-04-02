# Transaction History Feature (Lịch sử giao dịch)

Đây là mã nguồn cho tính năng "Lịch sử giao dịch" (Transaction History) thiết kế theo phong cách Dark Mode hiện đại.

Mã nguồn được viết bằng **Flutter**, tuân thủ nguyên tắc Clean Code và được chia nhỏ thành các Component riêng biệt để dễ dàng bảo trì và khả năng tái sử dụng cao.

## Cấu trúc thư mục

```
transaction_history/
├── models/
│   └── transaction_model.dart       # Định nghĩa kiểu dữ liệu cho Transaction (ID, loại giao dịch, số tiền, icon...)
├── components/
│   ├── header_section.dart          # Hiển thị số dư tổng, tìm kiếm, menu mở rộng và tab thời gian.
│   ├── summary_card.dart            # Hiển thị thẻ tóm tắt "Tiền vào" (Xanh dương) và "Tiền ra" (Đỏ cam).
│   ├── transaction_group.dart       # Gom nhóm danh sách giao dịch theo ngày (VD: "31 Thứ Ba").
│   ├── transaction_item.dart        # Component tái sử dụng hiển thị một dòng giao dịch chi tiết cụ thể.
│   └── bottom_nav_bar.dart          # Thanh điều hướng dưới cùng Bottom AppBar hỗ trợ FAB cut-out.
└── screens/
    └── transaction_history_screen.dart  # Màn hình chính lắp ráp tất cả các component, chứa mock data và định dạng Dark Theme Scaffold.
```

## Vai trò từng file

1. **`models/transaction_model.dart`**: Mô tả đối tượng `TransactionModel` nhằm quản lý dữ liệu cho mỗi giao dịch thay vì dùng map tuỳ tiện. Enum `TransactionType` giúp tách biệt rõ ràng luồng Thu/Chi.
2. **`components/header_section.dart`**: `StatelessWidget` giúp tách biệt phần giao diện số tiền, các tab để controller không bị lẫn với main build method.
3. **`components/summary_card.dart`**: Một widget đóng gói hoàn chỉnh báo cáo tổng Thu/Chi.
4. **`components/transaction_group.dart`**: Render khối thông tin cho một cụm ngày cụ thể thay vì viết vòng lặp For dài dòng trong màn hình chính.
5. **`components/transaction_item.dart`**: Chứa logic UI riêng biệt để đổi màu (xanh/đỏ) tự động tuỳ thuộc vào bản thân Transaction Data.
6. **`components/bottom_nav_bar.dart`**: Tách BottomNavigationBar logic, kết hợp `BottomAppBar` dễ dàng tạo vị trí chứa `FloatingActionButton` ngay giữa.
7. **`screens/transaction_history_screen.dart`**: "Nhạc trưởng" gọi và ráp các component con. Đồng thời khởi tạo `ThemeData.dark()` và mock dữ liệu phục vụ giao diện hiển thị mẫu.

## Hướng dẫn sử dụng
Copy thư mục `transaction_history` dán vào thư mục `lib/features/` của dự án. 
Gọi mở màn hình `TransactionHistoryScreen` ở main hoặc file router của bạn.

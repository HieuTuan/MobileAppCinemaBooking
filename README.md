# CineLuxe Booking

Ứng dụng Flutter mô phỏng hệ thống mobile mua bán vé xem phim theo SRS: Khách hàng, Nhân viên và Quản trị viên trong cùng một FE để demo nghiệp vụ nhanh.

## Tài khoản demo

| Vai trò | Email | Mật khẩu |
| --- | --- | --- |
| Khách hàng | `user@cineluxe.vn` | `123456` |
| Nhân viên | `staff@cineluxe.vn` | `123456` |
| Quản trị viên | `admin@cineluxe.vn` | `123456` |

## Chức năng chính

- Khách hàng: đăng ký/đăng nhập/quên mật khẩu/OAuth demo, xem và lọc phim, xem chi tiết/trailer, chọn rạp/suất/ghế, giữ ghế 10 phút, tối đa 8 ghế, chọn combo, thanh toán VNPay demo, nhận vé QR, hủy/hoàn vé, lịch sử giao dịch, đánh giá phim, cài đặt thông báo và hồ sơ.
- Nhân viên: đăng nhập nội bộ, quét/nhập QR, xác thực vé, tra cứu booking, hỗ trợ đổi/hủy/in/gửi lại vé, cập nhật trạng thái phòng, báo cáo sự cố và xem danh sách ghế theo suất.
- Quản trị viên: quản lý phim/thể loại/rạp/phòng/lịch chiếu, quản lý user/staff/RBAC, booking/refund, thống kê vé/doanh thu, xuất báo cáo Excel/PDF demo, cấu hình giá vé/banner/VNPay.

## Cấu trúc

```text
lib/
  main.dart
  src/
    app.dart
    core/              Theme, màu sắc, formatter, label tiếng Việt.
    data/              Dữ liệu demo.
    models/            Entity và enum nghiệp vụ.
    state/             CinemaStore quản lý state in-memory.
    shared/widgets/    Scaffold, card, metric, button dùng chung.
    features/
      auth/            Đăng nhập, đăng ký, OTP/OAuth demo.
      customer/        Phim, booking, vé QR, hồ sơ.
      staff/           Soát vé và hỗ trợ quầy.
      admin/           Quản trị nội dung, user, finance, system.
```

## Chạy và kiểm tra

```bash
flutter pub get
flutter run
flutter analyze
flutter test
flutter build web
```

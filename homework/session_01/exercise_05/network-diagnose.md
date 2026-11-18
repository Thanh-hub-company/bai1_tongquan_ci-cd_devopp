# Báo cáo: Xử lý trùng cổng 8080 và chẩn đoán kết nối mạng

- **Môi trường thực hiện:** Ubuntu (WSL) trên Windows
- **Dịch vụ liên quan:** user-service (Java Spring Boot)

---

## Tình huống 1: Lỗi `Address already in use` do trùng cổng 8080

**Hiện tượng:** user-service khởi động thất bại vì cổng 8080 đã bị một tiến trình khác chiếm dụng.

### Các lệnh đã sử dụng

| Bước | Lệnh | Mục đích |
|---|---|---|
| 0 (giả lập sự cố) | `python3 -m http.server 8080 &` | Chạy một web server nhỏ ở nền để chiếm cổng 8080, tạo lại tình huống của đề bài. |
| 1 | `sudo ss -tulpn \| grep :8080` | Liệt kê các cổng đang lắng nghe rồi lọc riêng cổng 8080 để tìm PID của tiến trình đang chiếm cổng. |
| 2 | `sudo kill -9 <PID>` | Buộc dừng tiến trình theo PID tìm được ở bước 1 (tín hiệu SIGKILL) để giải phóng cổng. |
| 3 | `sudo ss -tulpn \| grep :8080` | Kiểm tra lại. Không còn dòng nào được in ra nghĩa là cổng 8080 đã được giải phóng. |

### Giải thích các tùy chọn của `ss -tulpn`

- `-t`: hiển thị cổng TCP
- `-u`: hiển thị cổng UDP
- `-l`: chỉ hiển thị các cổng đang lắng nghe (listening)
- `-p`: hiển thị tiến trình (tên và PID) sử dụng cổng
- `-n`: hiển thị số cổng thay vì tên dịch vụ

### Kết quả

- **Trước khi tắt:** lệnh ở bước 1 in ra một dòng trạng thái `LISTEN` chứa thông tin tiến trình, ví dụ `users:(("python3",pid=<PID>,fd=3))`. Ảnh minh chứng: `port_fix.png`.
- **Sau khi tắt:** lệnh ở bước 3 không in ra kết quả nào, user-service có thể khởi động lại bình thường.

### Lưu ý an toàn

`kill -9` không cho tiến trình kịp dọn dẹp tài nguyên. Trong thực tế nên thử `kill <PID>` (SIGTERM) trước, chỉ dùng `-9` khi tiến trình không chịu dừng.

---

## Tình huống 2: Không kết nối được Database PostgreSQL tại 10.0.1.20

**Hiện tượng:** user-service báo lỗi không kết nối được tới PostgreSQL tại IP `10.0.1.20`.

### Các lệnh đã sử dụng

| Bước | Lệnh | Mục đích |
|---|---|---|
| 1 | `ping -c 4 10.0.1.20` | Kiểm tra đường truyền (tầng mạng) tới máy chủ DB bằng 4 gói tin ICMP. Xác định máy chủ có đến được hay không. |
| 2 | `nc -zv -w 3 10.0.1.20 5432` | Thăm dò cổng 5432 (PostgreSQL): `-z` chỉ quét không gửi dữ liệu, `-v` hiển thị chi tiết, `-w 3` chờ tối đa 3 giây. |
| 2 (thay thế) | `curl -v telnet://10.0.1.20:5432` | Cách khác để thử mở kết nối TCP tới cổng 5432. Thấy dòng `Connected to` là cổng mở. |

### Cách đọc kết quả

| Kết quả | Ý nghĩa |
|---|---|
| `ping` có phản hồi, `0% packet loss` | Máy chủ DB tồn tại và đường truyền mạng ổn. |
| `ping` báo `100% packet loss` hoặc `Destination Host Unreachable` | Không đến được máy chủ: sai IP, mất kết nối mạng hoặc bị chặn ICMP. |
| `nc` báo `succeeded` | Cổng 5432 đang mở, PostgreSQL đang lắng nghe. |
| `nc` báo `Connection refused` | Máy chủ đến được nhưng PostgreSQL chưa chạy hoặc không lắng nghe ở cổng 5432. |
| `nc` báo `timed out` | Gói tin bị bỏ qua, thường do firewall chặn cổng 5432 hoặc sai đường đi. |

### Kết luận chẩn đoán

- Nếu `ping` thông nhưng `nc` thất bại: lỗi nằm ở dịch vụ PostgreSQL hoặc firewall, không phải do đường truyền vật lý.
- Nếu `ping` không thông: cần kiểm tra IP, cấu hình mạng, định tuyến trước khi xét tới dịch vụ.
- Lưu ý: `10.0.1.20` là địa chỉ giả định theo đề bài, nên khi chạy trên máy cá nhân kết quả thường là timeout hoặc unreachable.

---

## Tệp liên quan

- `port_fix.png`: ảnh chụp terminal hiển thị dòng PID chiếm cổng 8080 trước khi tắt.

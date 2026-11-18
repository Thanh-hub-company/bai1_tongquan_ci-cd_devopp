# BÁO CÁO THỰC HÀNH TỔNG HỢP - BUỔI 01

- **Chủ đề:** Thiết lập hạ tầng Linux, Quản trị phân quyền và Tự động hóa Deploy môi trường Development (Hệ thống QuickBite)
- **Người thực hiện:** [Họ và tên sinh viên]
- **Mã sinh viên / Lớp:** [Mã SV / Tên lớp]
- **Hệ điều hành:** Ubuntu Linux (24.04 LTS)

---

## 1. Toàn bộ câu lệnh Linux sử dụng ở Nhiệm vụ 1

Nhiệm vụ 1 tập trung vào việc chuẩn bị môi trường vận hành cô lập, áp dụng nguyên tắc đặc quyền tối thiểu (*Principle of Least Privilege*) cho dịch vụ **User Service** trên môi trường Development.

### 1.1. Tạo nhóm và tài khoản người dùng hệ thống chuyên trách

```bash
# 1. Tạo nhóm hệ thống (system group) tên là quickbite-apps
sudo groupadd -r quickbite-apps

# 2. Tạo tài khoản người dùng hệ thống (system user) tên là user-svc
#    -r             : Tạo system account (UID < 1000)
#    -g             : Chỉ định nhóm chính (primary group) là quickbite-apps
#    -M             : Không tạo thư mục cá nhân (/home/user-svc)
#    -s /bin/false  : Vô hiệu hóa quyền đăng nhập tương tác qua shell
sudo useradd -r -g quickbite-apps -M -s /bin/false user-svc
```

### 1.2. Tạo cấu trúc thư mục lưu trữ dịch vụ môi trường Dev

```bash
# Tạo phân cấp thư mục chứa mã thực thi của User Service (-p tự động tạo các thư mục cha)
sudo mkdir -p /opt/quickbite/dev/user-service
```

### 1.3. Thiết lập quyền sở hữu và phân quyền bảo mật

```bash
# Thay đổi quyền sở hữu (ownership) thư mục user-service cho user-svc và nhóm quickbite-apps
sudo chown -R user-svc:quickbite-apps /opt/quickbite/dev/user-service

# Thiết lập quyền truy cập 750:
# - Chủ sở hữu (user-svc)      : Đọc, Ghi, Thực thi (7 = rwx)
# - Nhóm (quickbite-apps)      : Đọc, Thực thi (5 = r-x)
# - Người dùng khác (Others)   : Không có quyền truy cập (0 = ---)
sudo chmod -R 750 /opt/quickbite/dev/user-service
```

### 1.4. Các câu lệnh kiểm tra, xác minh cấu hình sau khi thiết lập

```bash
# Kiểm tra thông tin UID, GID của user-svc
id user-svc

# Kiểm tra thông tin shell đăng nhập và đường dẫn home trong /etc/passwd
getent passwd | grep user-svc

# Kiểm tra quyền sở hữu và quyền truy cập (permission bits) của thư mục triển khai
ls -ld /opt/quickbite/dev/user-service
```

---

## 2. Bảng giải thích tham số kỹ thuật & Ý nghĩa bảo mật

| Câu lệnh / Tham số | Chức năng kỹ thuật | Ý nghĩa bảo mật |
| :--- | :--- | :--- |
| `groupadd -r quickbite-apps` | Khởi tạo nhóm hệ thống với GID dưới ngưỡng `1000`. | Tách biệt nhóm quản lý tiến trình dịch vụ khỏi nhóm người dùng thông thường trên máy chủ. |
| `useradd -r -M ...` | Khởi tạo tài khoản dịch vụ không có thư mục `/home/user-svc`. | Giảm thiểu bề mặt lưu trữ dữ liệu cá nhân không cần thiết trên hệ thống. |
| `-s /bin/false` | Gán trình thông dịch đăng nhập là `/bin/false`. | Ngăn chặn tuyệt đối việc đăng nhập trực tiếp qua SSH hoặc chuyển đổi phiên bằng lệnh `su` vào tài khoản dịch vụ. |
| `chown -R user-svc:quickbite-apps` | Chuyển quyền sở hữu đệ quy toàn bộ thư mục triển khai. | Đảm bảo tiến trình Java chỉ hoạt động dưới danh nghĩa `user-svc`, không sử dụng quyền tối cao `root`. |
| `chmod -R 750` | Cấp quyền `rwxr-x---` cho thư mục dịch vụ. | Ngăn người dùng khác trên cùng máy chủ đọc trộm file cấu hình, mã nguồn đóng gói (`.jar`) hoặc log ứng dụng. |

---

## 3. Tóm tắt kết quả vận hành & Kiểm thử (Nhiệm vụ 2 - 4)

- **Biên dịch mã nguồn:** Kéo mã nguồn từ kho lưu trữ Git về `~/workspace/` và đóng gói thành công tệp thực thi `.jar` thông qua `./gradlew clean bootJar`.
- **Tự động hóa triển khai (`deploy-dev.sh`):**
  - Cơ chế **Fail-fast** hoạt động chính xác: khi mã nguồn Java phát sinh lỗi biên dịch (`$? != 0`), kịch bản tự động ngắt ngay lập tức và giữ nguyên phiên bản ứng dụng đang vận hành.
  - Khi biên dịch thành công, kịch bản tự động giải phóng cổng `8080`, sao chép file `.jar` mới vào `/opt/quickbite/dev/user-service`, gán quyền sở hữu `user-svc:quickbite-apps` và khởi chạy ngầm ứng dụng.
- **Chẩn đoán mạng:**
  - Lệnh `ss -tulpn | grep java` xác nhận tiến trình Java đang lắng nghe (`LISTEN`) tại cổng `8080`.
  - Lệnh `curl http://localhost:8080` nhận được phản hồi HTTP hợp lệ từ Web Server.
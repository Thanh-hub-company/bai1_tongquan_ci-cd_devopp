#!/bin/bash

# Định nghĩa mã màu ANSI để in thông báo
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Kiểm tra quyền root/sudo
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[LỖI] Vui lòng chạy script bằng quyền sudo: sudo ./deploy-dev.sh <tên_dịch_vụ>${NC}"
  exit 1
fi

SERVICE_NAME=$1

# 3. Xác định cấu hình dịch vụ theo tham số đầu vào
if [ "$SERVICE_NAME" == "user" ]; then
    PORT=8080
    TARGET_DIR="/opt/quickbite/dev/user-service"
    APP_USER="user-svc"
    APP_GROUP="quickbite-apps"
    # Tự động tìm thư mục dự án trong ~/workspace hoặc dùng đường dẫn mặc định
    if [ -n "$SUDO_USER" ]; then
        USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    else
        USER_HOME="$HOME"
    fi
    WORKSPACE_DIR="$USER_HOME/workspace"
    # Tìm thư mục con chứa file gradlew đầu tiên trong workspace
    PROJECT_DIR=$(find "$WORKSPACE_DIR" -maxdepth 2 -name "gradlew" -printf "%h\n" | head -n 1)
    if [ -z "$PROJECT_DIR" ]; then
        PROJECT_DIR="$WORKSPACE_DIR/quickbite-user-service"
    fi
else
    echo -e "${RED}[LỖI] Tham số dịch vụ không hợp lệ! Sử dụng: sudo ./deploy-dev.sh user${NC}"
    exit 1
fi

echo -e "${YELLOW}=== BẮT ĐẦU TRIỂN KHAI DỊCH VỤ: $SERVICE_NAME (PORT: $PORT) ===${NC}"

# Di chuyển vào thư mục mã nguồn
cd "$PROJECT_DIR" || { echo -e "${RED}[LỖI] Không tìm thấy thư mục dự án: $PROJECT_DIR${NC}"; exit 1; }

# 1. Cập nhật mã nguồn mới nhất
echo -e "${YELLOW}[1/4] Đang kéo mã nguồn mới nhất (git pull)...${NC}"
git pull

# 2. Biên dịch Fail-fast
echo -e "${YELLOW}[2/4] Đang biên dịch ứng dụng (./gradlew clean bootJar)...${NC}"
chmod +x ./gradlew
./gradlew clean bootJar

# Bắt buộc kiểm tra mã lỗi ($?) ngay sau lệnh build
if [ $? -ne 0 ]; then
    echo -e "${RED}[THẤT BẠI] Quá trình biên dịch gặp lỗi! Dừng kịch bản ngay lập tức (Fail-fast).${NC}"
    exit 1
fi
echo -e "${GREEN}      -> Biên dịch thành công!${NC}"

# 4. Triển khai ứng dụng
echo -e "${YELLOW}[3/4] Kiểm tra và dừng tiến trình cũ đang chiếm cổng $PORT...${NC}"
OLD_PID=$(ss -tulpn | grep ":$PORT " | grep -oP 'pid=\K\d+' | head -n 1)

if [ -n "$OLD_PID" ]; then
    echo "      -> Phát hiện tiến trình cũ (PID: $OLD_PID). Đang thực hiện kill -9..."
    kill -9 "$OLD_PID"
    sleep 2
else
    echo "      -> Cổng $PORT đang trống."
fi

echo -e "${YELLOW}[4/4] Sao chép file JAR và khởi chạy dịch vụ dưới quyền user '$APP_USER'...${NC}"
JAR_FILE=$(find build/libs -name "*.jar" ! -name "*-plain.jar" | head -n 1)

if [ -z "$JAR_FILE" ]; then
    echo -e "${RED}[LỖI] Không tìm thấy file .jar sau khi build!${NC}"
    exit 1
fi

# Xóa file jar cũ trong thư mục đích (nếu có) và copy file mới vào
rm -f "$TARGET_DIR"/*.jar
cp "$JAR_FILE" "$TARGET_DIR/app.jar"

# Phân quyền sở hữu cho file app.jar
chown "$APP_USER":"$APP_GROUP" "$TARGET_DIR/app.jar"
chmod 750 "$TARGET_DIR/app.jar"

# Chạy ngầm ứng dụng bằng user chuyên biệt (sử dụng sudo -u và nohup)
sudo -u "$APP_USER" nohup java -jar "$TARGET_DIR/app.jar" --server.port="$PORT" > "$TARGET_DIR/app.log" 2>&1 &

echo -e "${GREEN}=== TRIỂN KHAI THÀNH CÔNG! Dịch vụ '$SERVICE_NAME' đang khởi chạy ngầm tại cổng $PORT ===${NC}"

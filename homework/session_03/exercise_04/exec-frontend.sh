#!/bin/bash

# Bước 1: Dọn dẹp container cũ nếu đã tồn tại (tránh lỗi trùng tên khi chạy lại)
docker rm -f rikkei-frontend-qa 2>/dev/null

# Bước 2: Khởi chạy container nginx ở chế độ chạy ngầm (-d) với biến môi trường (-e)
docker run -d \
  --name rikkei-frontend-qa \
  -e API_ENDPOINT=https://qa-api.rikkei.edu.vn \
  nginx

# Bước 3: Mở bash shell tương tác (-it) vào bên trong container và in biến môi trường
docker exec -it rikkei-frontend-qa bash -c 'echo "API_ENDPOINT hiện tại là: $API_ENDPOINT"; exec bash'

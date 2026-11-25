#!/bin/bash

# 1. Tao user he thong rikkeilms
sudo useradd -m -s /bin/bash rikkeilms

# 2. Tao thu muc goc chua ma nguon va cau hinh
sudo mkdir -p /opt/rikkei/course-service

# 3. Chuyen quyen so huu thu muc cho user va group rikkeilms
sudo chown -R rikkeilms:rikkeilms /opt/rikkei/course-service

# 4. Cap quyen chi chu so huu co quyen ghi (755 -> drwxr-xr-x)
sudo chmod 755 /opt/rikkei/course-service

# 5. Kiem tra ket qua thiet lap
ls -ld /opt/rikkei/course-service

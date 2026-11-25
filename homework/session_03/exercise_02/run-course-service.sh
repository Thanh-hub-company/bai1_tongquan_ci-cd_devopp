#!/bin/bash

# 1. Khoi chay container o che do ngam (-d), dat ten (--name), anh xa cong (-p 8081:80)
docker run -d --name rikkei-course-service -p 8081:80 nginxdemos/hello

# 2. Kiem tra trang thai container dang hoat dong
docker ps

# 3. Kiem thu dich vu qua cong 8081
curl -I http://localhost:8081

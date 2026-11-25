#!/bin/bash

# 1. Tao du lieu truy cap mau (15 request) de dam bao log co du 15 dong
for i in {1..15}; do
    curl -s http://localhost:8081 > /dev/null
done

# 2. Trich xuat chinh xac 15 dong log cuoi cung kem moc thoi gian (timestamps)
docker logs --tail 15 -t rikkei-course-service

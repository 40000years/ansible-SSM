#!/bin/bash
mkdir -p semaphore/data
cat <<EOF > semaphore/docker-compose.yml
version: '3.8'
services:
  semaphore:
    image: semaphoreui/semaphore:latest
    ports:
      - "3000:3000"
    environment:
      SEMAPHORE_DB_DIALECT: sqlite
      SEMAPHORE_ADMIN: admin
      SEMAPHORE_ADMIN_PASSWORD: password123
      SEMAPHORE_ADMIN_NAME: Admin
      SEMAPHORE_ADMIN_EMAIL: admin@localhost
    volumes:
      - ./data:/var/lib/semaphore
    restart: unless-stopped
EOF
cd semaphore
docker-compose up -d
echo "Semaphore กำลังรันอยู่ที่ http://localhost:3000"

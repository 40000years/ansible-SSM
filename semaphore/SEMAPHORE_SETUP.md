# Semaphore Setup Guide — AWS EC2 Private + SSM (No SSH Key)

## Prerequisites

- Docker และ Docker Compose ติดตั้งแล้ว
- **S3 Bucket** สำหรับ Ansible โอนไฟล์ (`thanaphat-web-app-bucket-2026-858039354188-ap-southeast-1-an`)
- **IAM User (`Ansible`)** หรือ Role มีสิทธิ์อ่าน/เขียน/ลิสต์ S3 Bucket นี้
- **EC2 Target Instance** มี IAM Role ที่มีสิทธิ์:
  - `AmazonSSMManagedInstanceCore`
  - สิทธิ์ในการอ่าน/เขียน S3 Bucket ข้างต้น

---

## 1. Start Semaphore

```bash
cd semaphore/
docker-compose up -d

# ตรวจสอบ log
docker-compose logs -f semaphore
```

เปิด Browser → `http://localhost:3000`  
Login: `admin` / `password123`

---

## 2. ตั้งค่า Key Store (ไม่ต้องใช้ SSH Key แล้ว!)

> **Semaphore UI** → `Key Store` → `New Key`

เนื่องจากเราใช้ SSM ล้วนๆ ไม่ต้องตั้งค่า SSH Key เลย แต่ Semaphore อาจบังคับให้เลือก Key ตอนสร้าง Inventory ให้สร้างเป็น "None" Type แทน
| Field | Value |
|---|---|
| Name | `No-Key` |
| Type | `None` |

---

## 3. ตั้งค่า Repository

> **Semaphore UI** → `Repositories` → `New Repository`

| Field | Value |
|---|---|
| Name | `ansible-SSM` |
| URL | `/home/semaphore/ansible-SSM` |
| Branch | `main` |
| Access Key | `None` (local path ไม่ต้องใช้ key) |

---

## 4. ตั้งค่า Inventory

> **Semaphore UI** → `Inventory` → `New Inventory`

| Field | Value |
|---|---|
| Name | `AWS EC2 Dynamic (SSM)` |
| Type | `File` |
| Path | `semaphore/inventory/aws_ec2.yml` |
| SSH Key | `None` (หรือชื่อของ None-Key ที่สร้างไว้) |

---

## 5. ตั้งค่า Environment (ถ้าต้องการ)

> **Semaphore UI** → `Environment` → `New Environment`

| Field | Value |
|---|---|
| Name | `AWS ap-southeast-1` |
| Extra Variables | `{"AWS_DEFAULT_REGION": "ap-southeast-1"}` |

---

## 6. สร้าง Task Template

> **Semaphore UI** → `Task Templates` → `New Template`

### NIST Compliance Check

| Field | Value |
|---|---|
| Name | `NIST Compliance Check` |
| Playbook Filename | `playbooks/nist_check.yml` (หรือ `main.yml` ตามที่คุณใช้งาน) |
| Inventory | `AWS EC2 Dynamic (SSM)` |
| Repository | `ansible-SSM` |
| Environment | `AWS ap-southeast-1` |

---

## 7. ทดสอบการเชื่อมต่อ (SSM Ping)

สามารถทดสอบว่า Ansible วิ่งผ่าน SSM ไปยัง EC2 โดยใช้ S3 Bucket สำเร็จหรือไม่:

```bash
docker exec $(docker-compose ps -q semaphore) \
  ansible all \
  -i /home/semaphore/ansible-SSM/semaphore/inventory/aws_ec2.yml \
  -m ping
```

---

## Troubleshooting

### ❌ `HeadBucket operation: Forbidden`
แปลว่า IAM User ของ Semaphore ไม่มีสิทธิ์ `s3:ListBucket` ที่ตัว Bucket ต้องแนบ Policy ให้ครอบคลุมการ List Bucket ด้วย (ระดับ Resource ที่เป็น ARN ของ Bucket โดยตรง ไม่ใช่แค่ `/*`)

### ❌ `failed to transfer file to ...`
แปลว่า EC2 ปลายทาง ดาวน์โหลด/อัปโหลดไฟล์ไปที่ S3 Bucket ไม่ได้ ให้ตรวจสอบ IAM Role ของ EC2 ปลายทางว่ามีสิทธิ์ S3 `PutObject`, `GetObject` หรือไม่

### ❌ `amazon.aws.aws_ssm` plugin ไม่ทำงาน
Plugin ติดตั้งมาพร้อม Docker Image แล้ว แต่หากหาไม่เจอ ให้ตรวจสอบใน Inventory file ว่าระบุ `ansible_connection: "'amazon.aws.aws_ssm'"` ถูกต้อง

# semaphore/Dockerfile
# Extends Semaphore image with AWS CLI + SSM connection plugin
# ใช้ community.aws.aws_ssm — ไม่ต้อง SSH key เลย!

FROM semaphoreui/semaphore:latest

USER root

# Install dependencies
# - gcompat + libc6-compat: glibc compatibility สำหรับ SSM plugin binary
RUN apk add --no-cache curl bash dpkg gcompat libc6-compat

# Install AWS CLI v1 via pip (musl-compatible)
RUN pip3 install --no-cache-dir awscli && \
    aws --version

# Install AWS Session Manager Plugin (ดาวน์โหลดจาก Ubuntu DEB — รองรับ ARM64/x86_64)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        SSM_DEB="ubuntu_arm64"; \
    else \
        SSM_DEB="ubuntu_64bit"; \
    fi && \
    echo "Downloading SSM plugin for $ARCH ($SSM_DEB)" && \
    curl -sSL "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/${SSM_DEB}/session-manager-plugin.deb" \
        -o /tmp/ssm-plugin.deb && \
    dpkg-deb --extract /tmp/ssm-plugin.deb /tmp/ssm-extract && \
    cp /tmp/ssm-extract/usr/local/sessionmanagerplugin/bin/session-manager-plugin \
        /usr/local/bin/session-manager-plugin && \
    chmod +x /usr/local/bin/session-manager-plugin && \
    rm -rf /tmp/ssm-plugin.deb /tmp/ssm-extract && \
    echo "SSM plugin: $(ls -la /usr/local/bin/session-manager-plugin)"

# Install Ansible collections
# - amazon.aws: Dynamic Inventory (aws_ec2 plugin)
# - community.aws: SSM connection plugin (aws_ssm)
RUN ansible-galaxy collection install amazon.aws community.aws \
    -p /usr/share/ansible/collections

# Copy entrypoint script (รัน as root เพื่อ fix AWS credentials permissions)
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

USER root
ENTRYPOINT ["/sbin/tini", "--", "/docker-entrypoint.sh"]

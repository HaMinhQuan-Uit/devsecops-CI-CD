# Dockerfile

# ========== STAGE 1: Build ==========
# Tải image Python 3.11 bản nhẹ (slim) làm nền
# Multi-stage build: stage này chỉ để cài dependencies
# Sau khi cài xong, chỉ copy kết quả sang stage 2
# → Image cuối nhỏ hơn, ít CVE hơn (vì không chứa build tools)
FROM python:3.11-slim AS builder

WORKDIR /build
COPY app/requirements.txt .
# --prefix=/install: cài vào thư mục riêng, để copy sang stage sau
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# ========== STAGE 2: Runtime ==========
# Image mới, sạch, chỉ có Python runtime
FROM python:3.11-slim AS runtime

# TẠO USER RIÊNG — không chạy app bằng root
# Nếu attacker exploit được app, họ chỉ có quyền appuser
# chứ không phải root → giảm damage
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy libraries đã cài từ stage 1
COPY --from=builder /install /usr/local
# Copy source code
COPY app/ .

# Đổi ownership cho appuser
RUN chown -R appuser:appuser /app
# Từ đây trở đi, mọi lệnh chạy bằng appuser (không phải root)
USER appuser

# Khai báo app lắng nghe port 5000
EXPOSE 5000

# HEALTHCHECK — Docker tự kiểm tra app có sống không
# Mỗi 30 giây gọi /health, nếu fail 3 lần → đánh dấu unhealthy
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost:5000/health || exit 1

# Lệnh chạy khi container start
# gunicorn: production web server (không dùng flask dev server)
# --workers 2: 2 process xử lý request song song
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]

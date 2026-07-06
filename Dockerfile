# 使用 Python 3.13 作为基础镜像
FROM python:3.13-slim

# 设置工作目录
WORKDIR /app

# 复制项目文件
COPY pyproject.toml .
COPY README.md .
COPY main.py .
COPY freebuff2api/ freebuff2api/

# 安装项目依赖
RUN pip install --no-cache-dir .

# 创建非 root 用户运行应用
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# 暴露服务端口
EXPOSE 8000

# 设置健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/healthz')" || exit 1

# 启动命令
CMD ["python", "-m", "uvicorn", "freebuff2api.app:app", "--host", "0.0.0.0", "--port", "8000"]

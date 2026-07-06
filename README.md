# freebuff2api

Codebuff Freebuff 的 OpenAI-compatible API

## 接口

- `GET /v1/models`
- `POST /v1/chat/completions`
- `GET /healthz`

## 配置

### 获取 Token

无需安装 Freebuff / Codebuff CLI，可以直接打开公开页面自动获取 token：

```text
https://freebuff.071129.xyz/
```

使用方式：

1. 打开上面的地址
2. 选择 Freebuff
3. 点击“开始认证”，在跳转页面完成授权
4. 回到页面复制展示的 token
5. 将复制结果写入本项目 `.env`

示例：

```dotenv
FREEBUFF_TOKEN=你的 Freebuff Bearer token
```

多账号可用英文逗号分隔；并发请求会优先分配到空闲账号，避免单个
Freebuff 账号的全局 active free session 被并发切模型请求互相覆盖：

```dotenv
FREEBUFF_TOKEN=token-a,token-b,token-c
```

复制 `.env.example` 为 `.env`，然后填写上游 token：

```powershell
Copy-Item .env.example .env
```

`.env` 示例：

```dotenv
FREEBUFF_TOKEN=你的 Freebuff Bearer token
FREEBUFF_API_KEY=本地 OpenAI API key，可留空
FREEBUFF_AD_PROVIDERS=gravity,zeroclick
FREEBUFF_PROXY_ENABLED=false
FREEBUFF_PROXY_URL=
FREEBUFF_DEBUG=false
FREEBUFF_LOG_LEVEL=INFO
FREEBUFF_LOG_BODY_CHARS=2000
FREEBUFF_LOG_COLOR=true
FREEBUFF_HOST=0.0.0.0
FREEBUFF_PORT=8000
```

默认不启用代理，所有上游请求直连，且不会读取系统 `HTTP_PROXY` / `HTTPS_PROXY`。

需要让所有上游请求经过代理时，在 `.env` 中开启：

```dotenv
FREEBUFF_PROXY_ENABLED=true
FREEBUFF_PROXY_URL=http://127.0.0.1:7890
```

支持 HTTP 和 SOCKS 代理，例如：

```dotenv
FREEBUFF_PROXY_URL=http://127.0.0.1:7890
FREEBUFF_PROXY_URL=socks5://127.0.0.1:1080
FREEBUFF_PROXY_URL=socks5h://127.0.0.1:1080
```

当前内置 Freebuff 模型：

- `deepseek/deepseek-v4-flash`
- `deepseek/deepseek-v4-pro`
- `moonshotai/kimi-k2.6`
- `minimax/minimax-m2.7`
- `minimax/minimax-m3`
- `google/gemini-2.5-flash-lite`
- `google/gemini-3.1-flash-lite-preview`
- `google/gemini-3.1-pro-preview`
- `mimo/mimo-v2.5`
- `mimo/mimo-v2.5-pro`

调试空返回或上游异常时：

```dotenv
FREEBUFF_DEBUG=true
FREEBUFF_LOG_LEVEL=DEBUG
FREEBUFF_LOG_BODY_CHARS=0
```

## 运行

```powershell
uv sync
uv run freebuff2api
```

或：

```powershell
python -m pip install -e .
python main.py
```

## 调用示例

```powershell
curl http://127.0.0.1:8000/v1/chat/completions `
  -H "Authorization: Bearer $env:FREEBUFF_API_KEY" `
  -H "Content-Type: application/json" `
  -d '{
    "model": "deepseek/deepseek-v4-flash",
    "messages": [{"role": "user", "content": "你好"}],
    "stream": false
  }'
```

流式：

```powershell
curl -N http://127.0.0.1:8000/v1/chat/completions `
  -H "Authorization: Bearer $env:FREEBUFF_API_KEY" `
  -H "Content-Type: application/json" `
  -d '{
    "model": "deepseek/deepseek-v4-flash",
    "messages": [{"role": "user", "content": "写一个 Python 快排"}],
    "stream": true
  }'
```

## Docker

### 本地构建镜像

```powershell
docker build -t freebuff2api .
```

### 运行容器

```powershell
docker run -d --name freebuff2api `
  -p 8000:8000 `
  --env-file .env `
  freebuff2api
```

或者直接通过环境变量传递配置：

```powershell
docker run -d --name freebuff2api `
  -p 8000:8000 `
  -e FREEBUFF_TOKEN=your_token_here `
  -e FREEBUFF_API_KEY=sk-local `
  freebuff2api
```

### 多账号并发

```powershell
docker run -d --name freebuff2api `
  -p 8000:8000 `
  -e FREEBUFF_TOKEN=token-a,token-b,token-c `
  freebuff2api
```

### Docker Compose

创建 `compose.yml`：

```yaml
services:
  freebuff2api:
    build: .
    container_name: freebuff2api
    ports:
      - "8000:8000"
    env_file:
      - .env
    restart: unless-stopped
```

启动：

```powershell
docker compose up -d
```

### 使用 GitHub Actions 构建并推送至 GHCR

项目已配置 GitHub Actions 工作流，支持手动触发构建并推送镜像到 GitHub Container Registry。

触发方式：

1. 在 GitHub 仓库页面点击 **Actions**
2. 选择 **Build and Push Docker Image**
3. 点击 **Run workflow**
4. 填写参数：
   - **branch**: 要构建的分支（默认 `main`）
   - **version**: 镜像版本标签（可选，例如 `v1.0`、`v1.2.3`，留空则使用分支名作为标签）
5. 点击 **Run workflow** 开始构建

构建特性：

- 多平台构建：自动构建 `linux/amd64` 和 `linux/arm64` 架构镜像
- 层缓存：利用 GitHub Actions 缓存加速重复构建
- 构建 attestation：自动生成构建 provenance 证书，提升镜像供应链安全
- `latest` 标签：使用 `main` 分支构建时自动打上 `latest` 标签

运行从 GHCR 拉取的镜像：

```powershell
docker run -d --name freebuff2api `
  -p 8000:8000 `
  -e FREEBUFF_TOKEN=your_token_here `
  ghcr.io/gmcf111/freebuff2api:latest
```

### 健康检查

容器内置健康检查（每 30 秒检测 `/healthz` 端点），Docker 会自动管理容器状态。

### 运行非 root 用户

容器默认以非 root 用户（`appuser`，UID 1000）运行，提升安全性。

## 感谢

> [FreeBuff](https://freebuff.com)

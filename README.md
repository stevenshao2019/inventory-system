# Inventory Management System

进销存管理系统 - 多Agent协作开发

## 技术栈

- **后端**: FastAPI (Python)
- **数据库**: SQLite (开发) / PostgreSQL (生产)
- **前端**: React
- **容器化**: Docker & Docker Compose
- **认证**: JWT

## 项目结构

```
inventory-system/
├── backend/          # FastAPI 后端
├── frontend/         # React 前端
├── docs/             # 文档
├── docker-compose.yml
└── README.md
```

## 快速开始

### 使用 Docker

```bash
docker-compose up --build
```

### 本地开发

后端:
```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

前端:
```bash
cd frontend
npm install
npm run dev
```

## 分支策略

- `main` — 稳定发布版本
- `dev/backend` — 后端开发
- `dev/testing` — 测试开发

# 系统架构设计

## 整体架构：三层架构

```
┌─────────────────────────────────────────────────┐
│                  前端 (React)                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │ Dashboard│ │ 采购/销售 │ │ 工序流程图/统计   │  │
│  └────┬─────┘ └────┬─────┘ └────────┬─────────┘  │
│       │            │                │            │
└───────┼────────────┼────────────────┼────────────┘
        │  HTTP/JWT  │                │
┌───────┼────────────┼────────────────┼────────────┐
│       ▼            ▼                ▼            │
│              API 层 (FastAPI Router)              │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │ Auth API │ │ Product  │ │ Order / Report    │  │
│  │ /api/auth│ │ /api/prod│ │ /api/orders       │  │
│  └────┬─────┘ └────┬─────┘ └────────┬─────────┘  │
│       │            │                │            │
│       ▼            ▼                ▼            │
│            服务层 (Service Layer)                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │AuthService│ │Inventory │ │ Dashboard        │  │
│  │ JWT签发   │ │ 库存管理  │ │ 统计/图表数据    │  │
│  └────┬─────┘ └────┬─────┘ └────────┬─────────┘  │
│       │            │                │            │
│       ▼            ▼                ▼            │
│           数据层 (SQLAlchemy ORM)                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │  User    │ │ Product  │ │ Order/OrderItem   │  │
│  │  Supplier│ │ Category │ │ InventoryLog      │  │
│  └──────────┘ └──────────┘ └──────────────────┘  │
│                       │                          │
│                       ▼                          │
│              SQLite / PostgreSQL                   │
└─────────────────────────────────────────────────┘
```

## 1. 登录认证 (JWT)

- 使用 `python-jose` 签发和验证 JWT token
- 流程：登录 → 验证用户名密码 → 返回 access_token + refresh_token
- access_token 过期时间：60 分钟
- refresh_token 过期时间：7 天
- 前端在 Authorization header 携带 `Bearer <token>`
- 角色：admin, manager, operator

### Token 结构
```json
{
  "sub": "user_id",
  "username": "admin",
  "role": "admin",
  "exp": 1718000000
}
```

## 2. Dashboard（统计卡片 + 图表）

- **统计卡片**：
  - 今日销售额
  - 本月采购额
  - 库存总金额
  - 低库存预警数量
  - 待处理订单数

- **图表**：
  - 近7/30天销售趋势（折线图）
  - 品类占比（饼图/环形图）
  - 库存周转率（柱状图）
  - 采购 vs 销售对比（双轴图）

- 前端使用 `recharts` 渲染图表
- 后端提供聚合查询接口 `/api/dashboard/*`

## 3. 工序流程图

进销存核心流程：

```
采购 ──→ 入库 ──→ 库存管理 ──→ 销售 ──→ 出库
 │                    │            │
 └── 创建采购单        │            └── 创建销售单
     └── 审核          │                └── 审核
     └── 到货入库      │                └── 出库发货
                       │
                ┌──────┴──────┐
                │ 库存盘点     │
                │ 库存调拨     │
                │ 低库存预警   │
                └─────────────┘
```

### 状态流转
- **采购单状态**: `待审核 → 已审核 → 部分到货 → 已完成 → 已取消`
- **销售单状态**: `待审核 → 已审核 → 部分出库 → 已完成 → 已取消`
- **库存日志**: 记录每一次入库/出库/盘点操作

## API 路由设计

| 模块 | 路径 | 说明 |
|------|------|------|
| Auth | `POST /api/auth/login` | 登录获取 JWT |
| Auth | `POST /api/auth/refresh` | 刷新 Token |
| Auth | `GET /api/auth/me` | 获取当前用户 |
| Products | `GET/POST /api/products` | 产品 CRUD |
| Products | `GET/PUT/DELETE /api/products/{id}` | 产品详情 |
| Orders | `GET/POST /api/orders` | 订单 CRUD |
| Orders | `GET /api/orders/{id}/status` | 订单状态 |
| Dashboard | `GET /api/dashboard/summary` | 统计卡片数据 |
| Dashboard | `GET /api/dashboard/trends` | 趋势图表数据 |
| Inventory | `GET /api/inventory/logs` | 库存变动日志 |

## 数据模型（主要实体）

- **User**: id, username, email, hashed_password, role, is_active, created_at
- **Product**: id, name, sku, category_id, unit_price, stock_quantity, min_stock, supplier_id
- **Category**: id, name, description
- **Supplier**: id, name, contact, phone, address
- **Customer**: id, name, contact, phone, address
- **PurchaseOrder**: id, supplier_id, status, total_amount, created_by, created_at
- **PurchaseOrderItem**: id, order_id, product_id, quantity, unit_price
- **SalesOrder**: id, customer_id, status, total_amount, created_by, created_at
- **SalesOrderItem**: id, order_id, product_id, quantity, unit_price
- **InventoryLog**: id, product_id, type(in/out), quantity, reference_type, reference_id, created_at

## 前端路由

| 路径 | 页面 | 说明 |
|------|------|------|
| `/login` | Login | 登录页 |
| `/` | Dashboard | 仪表盘首页 |
| `/products` | ProductList | 产品列表 |
| `/products/new` | ProductForm | 新增产品 |
| `/purchase` | PurchaseList | 采购单列表 |
| `/purchase/new` | PurchaseForm | 新建采购单 |
| `/sales` | SalesList | 销售单列表 |
| `/sales/new` | SalesForm | 新建销售单 |
| `/inventory` | Inventory | 库存管理/日志 |
| `/reports` | Reports | 报表统计 |

# 彩虹易支付系统

**彩虹易支付系统** 一款开源的免签约支付产品，能够帮助开发者一站式接入支付宝、微信、财付通、QQ钱包等多种支付方式，实现高效的支付集成。

---

## 功能特色

- **多渠道支付集成**：支持支付宝、微信、财付通、QQ钱包、微信WAP、银联等多种支付方式  
- **便捷的支付解决方案**：简化支付流程，支持快速集成和上线，提供完整的 API 接口  
- **后台管理和数据统计**：提供支付统计、代付统计、利润分析等多种后台管理功能  
- **安全可靠**：采用 RSA 公私钥验证，支持风控检测和黑名单管理  
- **插件扩展**：支持丰富的支付插件，可根据需求灵活扩展  
- **移动端优化**：全新的手机版支付页面，支持各种移动端支付场景  

## 推荐插件

推荐使用 **Bepusdt** 插件进行 USDT（TRC20）收款。
Bepusdt 是适用于彩虹易支付系统的 USDT 收款插件，收到的货币直接转入商户钱包，不经过任何第三方。

**插件开源地址**：
🔗 [https://github.com/v03413/bepusdt](https://github.com/v03413/bepusdt)

---

## Docker 部署

### 1. 前置要求

- 已安装 Docker
- 已安装 Docker Compose（或使用 `docker compose`）
- 生产环境请提前准备好域名、反向代理和 HTTPS 证书

### 2. 配置环境变量

本项目的 `docker-compose.yml` 已移除默认数据库密码，启动前请先设置环境变量。

可以在项目根目录创建 `.env` 文件，示例：

```env
EPAY_MYSQL_ROOT_PASSWORD=请替换为强随机root密码
EPAY_DB_USER=epay_prod
EPAY_DB_PASSWORD=请替换为强随机数据库密码
EPAY_DB_NAME=epay
EPAY_DB_PREFIX=pay
```

建议：

- 不要在生产环境使用简单密码
- `EPAY_DB_USER` 建议按环境区分
- `.env` 不要提交到公开仓库

### 3. 启动服务

在项目根目录执行：

```bash
docker compose up -d --build
```

启动后默认映射端口：

- `http://服务器IP:9099`

### 4. 首次初始化说明

容器启动后会自动完成以下操作：

- 等待 MySQL 就绪
- 写入 `config.php`
- 首次启动时自动导入 `install/install.sql`
- 自动创建 `install/install.lock`

说明：

- 生产环境已经在 Nginx 层禁止访问 `/install` 和 `/install/update.php`
- `install/update.php` 文件本身也已被禁用，避免误暴露后执行升级逻辑

### 5. 管理后台登录

后台地址：

- `/admin/`

注意：

- 新初始化实例默认管理员密码占位值为 `CHANGE_ME_NOW`
- 首次部署后请立即修改管理员密码与支付密码
- 不要将后台直接暴露在公网，建议通过反向代理、访问控制或 VPN 保护

### 6. 生产环境建议

- 为站点配置 HTTPS
- 将 9099 仅绑定到内网或通过 Nginx / Caddy 反向代理暴露
- 限制 `/admin/` 访问来源 IP
- 定期备份数据库和 `assets/upload`
- 不要把 `.env`、数据库备份、日志文件暴露到 Web 根目录
- 如使用云服务器安全组，请仅开放必要端口

### 7. 更新与重建

代码更新后可以执行：

```bash
docker compose down
docker compose up -d --build
```

如仅需重建应用容器，也可以执行：

```bash
docker compose up -d --build app
```

### 8. 数据持久化

`docker-compose.yml` 已配置以下持久化卷：

- `epay_mysql_data`：MySQL 数据
- `epay_uploads`：上传文件
- `epay_plugins`：插件目录

迁移或备份生产环境时，请重点保留这些数据。

---


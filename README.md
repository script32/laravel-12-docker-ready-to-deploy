# Production-Ready Laravel 12 + Docker Boilerplate

Setting up a new Laravel project for production is often a major friction point. Most online Docker setups are built strictly for local development. When pushed to cloud providers or a VPS, they break due to permission mismatches, missing production headers, non-optimized asset routing, or unmanaged background queue workers.

This repository provides an enterprise-grade, highly optimized **Laravel 12 + Docker Starter Kit** designed to seamlessly bridge the gap between lightning-fast local development and secure, high-performance production environments.

---

## Architecture & Key Features

- **Multi-Stage Dockerfile:** Separates build dependencies from the final image, drastically reducing size and removing development overhead in production.

- **Production-Grade Nginx:** Pre-configured with security headers, client caching policies, Gzip compression, and optimized asset handling.

- **Process Management via Supervisor:** Native management for background tasks inside the container, keeping `queue:work` and the Laravel Task Scheduler alive and self-healing.

- **Zero-Friction Linux/Ubuntu Permissions:** Docker volumes and configurations mapped natively to prevent `storage` or `bootstrap/cache` write-permission blocks.

- **Robust CI/CD Workflow:** Complete GitHub Actions pipeline executing code style checks (Laravel Pint), static analysis (Larastan), and automated testing on every push or pull request.

---

## ⚡ Quick Start (Up in 60 Seconds)

Get your optimized development stack running locally by following these simple steps:

### 1. Clone the repository

```bash
git clone https://github.com/your-username/laravel-12-docker-production-boilerplate.git
cd laravel-12-docker-production-boilerplate
```

### 2. Environment Setup

```bash
cp .env.example .env
```

### 3. Build and Start the Stack

```bash
docker compose up -d --build
```

That's it! Your production-ready stack is live. Access your application via your browser at:
**http://localhost:8080**

---

## Services Included

The local development ecosystem manages four highly isolated services:

| Service | Description |
|---|---|
| **App (PHP-FPM)** | Running the latest PHP engine with essential extensions configured (`pdo_mysql`, `mbstring`, `bcmath`, `gd`, `opcache`, `xml`). |
| **Webserver (Nginx)** | Serving as the fast, reverse-proxy front-facing gateway. |
| **Database (MySQL 8.0)** | Isolated relational storage with dedicated persistent data volumes. |
| **Cache/Queue (Redis)** | Lighting-fast in-memory cache layer to process queues instantly. |

---

## Production Deployment Pipeline

When shifting this stack towards your live servers, the container initializes using a dedicated automated script. Every container startup performs the following operations safely:

1. Waits for DB connectivity verification.
2. Forces isolated database migrations (`php artisan migrate --force`).
3. Clears developer environment noise (`php artisan optimize:clear`).
4. Caches routes, configurations, views, and events (`php artisan optimize`).
5. Boots Supervisor to manage long-running queue processes.

---

## Contributing & Feedback

This boilerplate is completely open-source and ready for community expansion. If you find a bug, want to suggest structural performance tuning, or want to enhance the multi-stage CI/CD workflow, please feel free to open an **Issue** or submit a **Pull Request**!

If this starter kit saves you hours of DevOps setup on your next deploy, please drop a ⭐ star on this repository to help keep it visible and actively maintained!

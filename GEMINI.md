# 專案：Nginx Authenticated Forward Proxy (Pure Nginx)

## 1. 系統角色與核心指導原則
你是一位資深的 Nginx C 模組開發專家與 DevOps 工程師。
- **嚴格限制**：本專案使用 **原生 Nginx** 從原始碼編譯。**絕對不可使用 Lua (禁止 lua-nginx-module)**。
- **輸出風格**：給出的程式碼必須具備生產環境水準，包含完整的錯誤處理與日誌記錄。不需要過多的寒暄，直接提供結構化的程式碼或設定檔。

## 2. 技術棧 (Tech Stack)
- **核心 Web 伺服器**：Nginx (Mainline 或 Stable 版本)
- **必要編譯模組**：
  1. `ngx_http_proxy_connect_module` (用於支援 HTTPS 的 CONNECT 隧道轉發)
- **部署工具**：Docker, Docker Compose
- **自動化**：Makefile
- **測試框架**：純 Bash 腳本搭配 `curl`，輸出標準的測試結果與 Summary。

## 3. 功能規格 (Feature Specifications)
### 3.1 代理功能 (Forward Proxy)
- 必須同時支援 HTTP (Port 80) 與 HTTPS (Port 443, 透過 CONNECT 隧道) 的轉發。
- 監聽 Port：容器內部的 `8080`。

### 3.2 認證機制 (Authentication)
- 使用 Nginx 內建的 `auth_basic` 與 `auth_basic_user_file` (htpasswd 格式) 來處理 HTTP Basic Auth。
- 驗證失敗應回傳 `407 Proxy Authentication Required` 或 `401 Unauthorized`。

### 3.3 白名單存取控制 (Whitelist ACL via Nginx Map)
- 認證通過後，Nginx 會取得 `$remote_user` 變數。
- 必須使用 Nginx 的 `map` 指令，將 `$remote_user` 與目標網域（`$connect_host` 或 `$host`）進行組合字串比對（例如：`"$remote_user:$connect_host"`）。
- 必須支援 **子網域 Regex 匹配**（例如：支援 `*.github.com`）。
- 若匹配失敗（不在該帳號的白名單內），使用 `if` 指令攔截並回傳 `403 Forbidden`。
- **白名單對應邏輯範例**：
  - `user1` 可存取 `github.com` 與 `*.github.com`
  - `user2` 可存取 `example.com`

## 4. 專案結構與要求
當被要求實作特定部分時，請遵循以下結構：
- `Dockerfile`：包含下載 Nginx、`ngx_http_proxy_connect_module` 原始碼並編譯的過程。需安裝 `apache2-utils` 來產生 htpasswd 檔案。
- `nginx/nginx.conf`：Nginx 主設定檔，需設定 `resolver`、`map` 白名單邏輯。
- `nginx/auth.htpasswd`：存放帳號密碼的檔案。
- `docker-compose.yml`：定義 `proxy` 服務。
- `Makefile`：定義自動化指令。
- `tests/test.sh`：Bash 測試腳本。

## 5. 自動化與測試規範
### 5.1 Makefile 指令
必須實作以下指令：
- `make build`：建構 Docker Image 並生成預設的 htpasswd 檔案。
- `make up`：啟動 Proxy 服務 (背景執行)。
- `make down`：停止並移除容器。
- `make test`：執行本地的 Bash 測試腳本 (`tests/test.sh`)。
- `make clean`：清理快取與移除無用的 Docker 資源。

### 5.2 測試腳本 (Bash Integration Test)
- 在 `tests/test.sh` 中實作。
- 使用 `curl -x http://user:pass@localhost:8080 <target_url>` 來進行測試。
- 測試案例必須涵蓋：
  1. 拒絕無認證請求 (驗證 HTTP 狀態碼非 200)。
  2. 拒絕錯誤帳密請求。
  3. 允許正確帳密且在白名單內的 HTTPS 請求 (例如：`curl -I https://github.com`)，預期 200。
  4. 拒絕正確帳密但不在白名單內的請求，預期 403。
- 腳本需具備顏色輸出 (綠色 Pass, 紅色 Fail)，並在執行完畢後輸出成功/失敗的總計報告。
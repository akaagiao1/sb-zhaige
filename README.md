# Snell v6 一键安装脚本

这个仓库只保留 Snell v6 的一键安装脚本。

Snell 是 Surge 团队开发的轻量加密代理协议。v6 的核心变化是根据 PSK 自动派生部署级协议特征，让不同服务器产生不同的流量特征。当前脚本默认安装 Snell Server `6.0.0b3`，客户端和服务端建议保持同一代 Beta 版本。

## 适用环境

- Debian 11/12
- Ubuntu 20.04/22.04/24.04
- CentOS 7/8/Stream/9
- Rocky Linux / AlmaLinux / RHEL 系发行版
- root 用户或可使用 sudo 的用户
- Surge Mac Beta 或 Surge iOS TestFlight，且客户端需要支持 `version=6`

## 一键安装

在服务器上运行：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/akaagiao1/sb-zhaige/main/snell-v6)
```

如果服务器没有 `curl`：

```bash
# Debian / Ubuntu
apt update && apt install -y curl

# CentOS / RHEL / Rocky / AlmaLinux
dnf install -y curl || yum install -y curl

bash <(curl -fsSL https://raw.githubusercontent.com/akaagiao1/sb-zhaige/main/snell-v6)
```

脚本会自动完成：

- 下载 Snell v6 服务端
- 首次安装随机生成端口
- 首次安装随机生成 PSK 密钥
- 重新安装时默认保留已有端口和 PSK
- 创建 `/etc/snell-v6/snell-server.conf`
- 写入 `mode = default`
- 创建并启动 systemd 服务 `snell-v6`
- 自动处理 UFW / firewalld 放行
- 输出 Surge 客户端配置

安装完成后，客户端配置会保存到：

```bash
/root/snell-v6-client.conf
```

## Surge 客户端配置

把脚本输出的这一行加入 Surge 配置的 `[Proxy]` 区域：

```ini
Snell-v6 = snell, 服务器IP, 随机端口, psk=随机密钥, version=6
```

示例：

```ini
Snell-v6 = snell, 1.2.3.4, 34567, psk=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef, version=6
```

不建议默认添加 `reuse=true` 或其他多路复用参数。Surge 官方手册目前把 Snell 的 `reuse` 标注为 Snell v4 的可选连接复用参数，v6 先保持默认最稳。

## 可选参数

指定端口：

```bash
SNELL_PORT=7177 bash <(curl -fsSL https://raw.githubusercontent.com/akaagiao1/sb-zhaige/main/snell-v6)
```

指定 PSK：

```bash
SNELL_PSK='your-strong-psk' bash <(curl -fsSL https://raw.githubusercontent.com/akaagiao1/sb-zhaige/main/snell-v6)
```

开启 IPv6 监听：

```bash
ENABLE_IPV6=1 bash <(curl -fsSL https://raw.githubusercontent.com/akaagiao1/sb-zhaige/main/snell-v6)
```

指定 DNS 出口 IP 偏好：

```bash
DNS_IP_PREFERENCE=prefer-ipv4 bash <(curl -fsSL https://raw.githubusercontent.com/akaagiao1/sb-zhaige/main/snell-v6)
```

`DNS_IP_PREFERENCE` 支持：

```text
default
prefer-ipv4
prefer-ipv6
ipv4-only
ipv6-only
```

指定 Snell v6 mode：

```bash
SNELL_MODE=default bash <(curl -fsSL https://raw.githubusercontent.com/akaagiao1/sb-zhaige/main/snell-v6)
```

## 常用命令

查看服务状态：

```bash
systemctl status snell-v6 --no-pager
```

查看日志：

```bash
journalctl -u snell-v6 -n 80 --no-pager
```

查看服务端配置：

```bash
cat /etc/snell-v6/snell-server.conf
```

查看客户端配置：

```bash
cat /root/snell-v6-client.conf
```

## 排错

如果连接失败，优先检查：

1. VPS 厂商安全组是否放行脚本输出的 TCP 端口。
2. 服务器防火墙是否放行该 TCP 端口。
3. Surge 客户端是否支持 Snell v6。
4. 客户端里的 `psk` 是否和 `/etc/snell-v6/snell-server.conf` 完全一致。
5. Snell v6 Beta 期间可能有不兼容更新，客户端和服务端需要保持更新。

## 官方说明

- https://nssurge.com/blog/snell-v6/
- https://kb.nssurge.com/surge-knowledge-base/release-notes/snell

# Snell v6 一键安装脚本

适用环境：Debian 12，root 用户，Surge Beta / TestFlight 客户端。

Snell v6 当前仍是 Beta，脚本默认安装官方 `6.0.0b2` 服务端。Snell v6 的主要变化是由 PSK 自动派生部署级协议特征，所以建议每台服务器使用不同随机 PSK。

## 使用方法

```bash
wget -O snell-v6 https://raw.githubusercontent.com/akaagiao1/sb-zhaige/main/snell-v6
bash snell-v6
```

安装完成后，脚本会输出 Surge 客户端配置，并保存到服务器：

```bash
/root/snell-client.conf
```

## 客户端配置格式

把下面这一行加入 Surge 配置的 `[Proxy]` 区域：

```ini
Snell-v6 = snell, 你的服务器IP, 随机端口, psk=随机密钥, version=6
```

脚本实际输出类似：

```ini
Snell-v6 = snell, 1.2.3.4, 34567, psk=0123456789abcdef..., version=6
```

## 可选参数

指定端口：

```bash
SNELL_PORT=7177 bash snell-v6
```

指定 PSK：

```bash
SNELL_PSK='your-strong-psk' bash snell-v6
```

开启 IPv6 监听：

```bash
ENABLE_IPV6=1 bash snell-v6
```

指定 DNS 出口 IP 偏好：

```bash
DNS_IP_PREFERENCE=prefer-ipv4 bash snell-v6
```

支持值：

```text
default
prefer-ipv4
prefer-ipv6
ipv4-only
ipv6-only
```

## 常用命令

查看状态：

```bash
systemctl status snell --no-pager
```

查看日志：

```bash
journalctl -u snell -n 50 --no-pager
```

查看客户端配置：

```bash
cat /root/snell-client.conf
```

## 注意

如果连不上，优先检查：

1. VPS 厂商安全组是否放行脚本输出的 TCP 端口。
2. Surge 客户端是否支持 Snell v6。
3. 客户端 `psk` 是否和 `/etc/snell/snell-server.conf` 完全一致。
4. Snell v6 Beta 期间可能出现不兼容更新，客户端和服务端需要保持同一代 Beta。

官方说明：

- https://nssurge.com/blog/snell-v6/
- https://kb.nssurge.com/surge-knowledge-base/release-notes/snell

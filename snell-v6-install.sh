#!/usr/bin/env bash
set -Eeuo pipefail

SNELL_VERSION="${SNELL_VERSION:-6.0.0b2}"
SNELL_PORT="${SNELL_PORT:-}"
SNELL_PSK="${SNELL_PSK:-}"
ENABLE_IPV6="${ENABLE_IPV6:-0}"
DNS_IP_PREFERENCE="${DNS_IP_PREFERENCE:-default}"

CONFIG_DIR="/etc/snell"
CONFIG_FILE="${CONFIG_DIR}/snell-server.conf"
SERVICE_FILE="/etc/systemd/system/snell.service"
BIN_FILE="/usr/local/bin/snell-server"
CLIENT_FILE="/root/snell-client.conf"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

need_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    die "Please run as root, for example: sudo bash snell-v6-install.sh"
  fi
}

detect_arch() {
  local machine
  machine="$(uname -m)"

  case "${machine}" in
    x86_64 | amd64)
      echo "amd64"
      ;;
    aarch64 | arm64)
      echo "aarch64"
      ;;
    armv7l | armv7)
      echo "armv7l"
      ;;
    i386 | i686)
      echo "i386"
      ;;
    *)
      die "Unsupported architecture: ${machine}"
      ;;
  esac
}

random_port() {
  local port

  while true; do
    port="$(shuf -i 20000-60999 -n 1)"
    if ! ss -lntH 2>/dev/null | awk '{print $4}' | grep -Eq "[:.]${port}$"; then
      echo "${port}"
      return
    fi
  done
}

random_psk() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
  else
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c 48
    echo
  fi
}

install_deps() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y ca-certificates wget unzip curl openssl iproute2 coreutils
}

install_snell() {
  local arch url tmp_dir zip_file
  arch="$(detect_arch)"
  url="https://dl.nssurge.com/snell/snell-server-v${SNELL_VERSION}-linux-${arch}.zip"
  tmp_dir="$(mktemp -d)"
  zip_file="${tmp_dir}/snell-server.zip"

  echo "Downloading Snell Server v${SNELL_VERSION} for linux-${arch}..."
  wget -qO "${zip_file}" "${url}" || die "Download failed: ${url}"
  unzip -oq "${zip_file}" -d "${tmp_dir}"

  if [[ ! -f "${tmp_dir}/snell-server" ]]; then
    die "snell-server binary was not found in the downloaded archive"
  fi

  install -m 755 "${tmp_dir}/snell-server" "${BIN_FILE}"
  rm -rf "${tmp_dir}"
}

write_config() {
  local listen_value

  if [[ -z "${SNELL_PORT}" ]]; then
    SNELL_PORT="$(random_port)"
  fi

  if [[ -z "${SNELL_PSK}" ]]; then
    SNELL_PSK="$(random_psk)"
  fi

  mkdir -p "${CONFIG_DIR}"

  if [[ "${ENABLE_IPV6}" == "1" || "${ENABLE_IPV6}" == "true" ]]; then
    listen_value="0.0.0.0:${SNELL_PORT},[::]:${SNELL_PORT}"
  else
    listen_value="0.0.0.0:${SNELL_PORT}"
  fi

  cat >"${CONFIG_FILE}" <<EOF
[snell-server]
listen = ${listen_value}
psk = ${SNELL_PSK}
dns-ip-preference = ${DNS_IP_PREFERENCE}
EOF

  chmod 600 "${CONFIG_FILE}"
}

write_service() {
  cat >"${SERVICE_FILE}" <<EOF
[Unit]
Description=Snell Proxy Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=nobody
Group=nogroup
LimitNOFILE=32768
ExecStart=${BIN_FILE} -c ${CONFIG_FILE}
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
}

open_firewall_if_needed() {
  if command -v ufw >/dev/null 2>&1 && ufw status | grep -qi "Status: active"; then
    ufw allow "${SNELL_PORT}/tcp"
  fi
}

public_ip() {
  local ip
  ip="$(curl -4fsS --max-time 5 https://api.ipify.org 2>/dev/null || true)"

  if [[ -z "${ip}" ]]; then
    ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
  fi

  echo "${ip:-YOUR_SERVER_IP}"
}

write_client_config() {
  local server_ip
  server_ip="$(public_ip)"

  cat >"${CLIENT_FILE}" <<EOF
# Surge client configuration
# Add this line under the [Proxy] section:

Snell-v6 = snell, ${server_ip}, ${SNELL_PORT}, psk=${SNELL_PSK}, version=6
EOF

  chmod 600 "${CLIENT_FILE}"
}

start_service() {
  systemctl daemon-reload
  systemctl enable --now snell
  systemctl restart snell
}

print_result() {
  echo
  echo "Snell v6 server has been installed."
  echo
  echo "Server config:"
  echo "  ${CONFIG_FILE}"
  echo
  echo "Surge client config:"
  sed 's/^/  /' "${CLIENT_FILE}"
  echo
  echo "Useful commands:"
  echo "  systemctl status snell --no-pager"
  echo "  journalctl -u snell -n 50 --no-pager"
  echo
  echo "If your VPS provider has a cloud firewall/security group, allow TCP ${SNELL_PORT} there too."
}

main() {
  need_root
  install_deps
  install_snell
  write_config
  write_service
  open_firewall_if_needed
  start_service
  write_client_config
  print_result
}

main "$@"

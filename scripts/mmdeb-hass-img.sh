#!/bin/bash
set -ex

# 1. 环境变量
PYTHON_VERSION=3.13
HASS_VERSION=2025.6.3



apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu binutils-aarch64-linux-gnu python3-dev build-essential

chown -R haos:haos /homeassistant

mkdir -p /home/haos/uv-cache
chown -R 1000:1000 /home/haos
cd /homeassistant
su haos -c'
python3.13 -m venv venv
source venv/bin/activate
export UV_LINK_MODE=copy
export TMPDIR=/home/haos/tmp
export PIP_NO_CACHE_DIR=1
export UV_CONCURRENT_DOWNLOADS=1
mkdir -p ${TMPDIR}
export UV_CACHE_DIR=/home/haos/uv-cache
pip3 install uv==0.7.1
pip install --upgrade pip
pip install -r requirements.txt -c homeassistant/package_constraints.txt

# 安装前端、matter-server、aiodiscover

VENV_PATH="/homeassistant/venv"
REQUIREMENTS_FILE="requirements_all.txt"
CONSTRAINTS_FILE="/homeassistant/homeassistant/package_constraints.txt"
UV_PIP="$VENV_PATH/bin/uv pip"

dependencies=(
    "python-matter-server"
    "aiodiscover"
    "aiodhcpwatcher"
    "av"
    "PyNaCl"
    "pyotp"
    "PyQRCode"
    "home-assistant-frontend"
    "aiousbwatcher"
    "async-upnp-client"
    "go2rtc-client"
)

for dep in "${dependencies[@]}"; do
    version=$(grep -E "^${dep}==" "$REQUIREMENTS_FILE" | awk -F'==' '{print $2}')
    $UV_PIP install "${dep}==${version}" --index-strategy unsafe-first-match --upgrade --constraint "$CONSTRAINTS_FILE"
done

# 可选：预编译前端资源
if [ -f script/frontend.py ]; then
    python3 -m script.frontend
fi'

# 清理
rm -rf pip-cache tests/ requirements_test*.txt .pylintrc mypy.ini
rm -rf pip-build-env-* homeassistant.egg-info uv-cache build/ dist/
rm -f CLA.md CODE_OF_CONDUCT.md CONTRIBUTING.md codecov.yml .coveragerc Dockerfile*
find . -name "__pycache__" -exec rm -rf {} +
rm -rf /home/haos/tmp ${UV_CACHE_DIR}
exit





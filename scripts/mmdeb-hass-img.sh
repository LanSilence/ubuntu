#!/bin/bash
set -ex

# 1. 环境变量
PYTHON_VERSION=3.13
HASS_VERSION=2025.5.3
FRONTEND_VERSION=20250516.0
MATTER_SERVER_VERSION=7.0.0
AIODISCOVER_VERSION=2.7.0


apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu binutils-aarch64-linux-gnu python3-dev build-essential

chown -R haos:haos /homeassistant

mkdir -p /home/haos/uv-cache
cd /homeassistant
su haos -c'
python${PYTHON_VERSION} -m venv venv
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

/homeassistant/venv/bin/uv pip install python-matter-server==${MATTER_SERVER_VERSION} --index-strategy unsafe-first-match --upgrade --constraint /homeassistant/homeassistant/package_constraints.txt
/homeassistant/venv/bin/uv pip install aiodiscover==${AIODISCOVER_VERSION} --index-strategy unsafe-first-match --upgrade --constraint /homeassistant/homeassistant/package_constraints.txt
/homeassistant/venv/bin/uv pip install --quiet aiodhcpwatcher==1.1.1 --index-strategy unsafe-first-match --upgrade --constraint /homeassistant/homeassistant/package_constraints.txt
/homeassistant/venv/bin/uv pip install --quiet av==13.1.0 --index-strategy unsafe-first-match --upgrade --constraint /homeassistant/homeassistant/package_constraints.txt
/homeassistant/venv/bin/uv pip install --quiet PyNaCl==1.5.0 --index-strategy unsafe-first-match --upgrade --constraint /homeassistant/homeassistant/package_constraints.txt
/homeassistant/venv/bin/uv pip install --quiet pyotp==2.8.0 --index-strategy unsafe-first-match --upgrade --constraint /homeassistant/homeassistant/package_constraints.txt
/homeassistant/venv/bin/uv pip install --quiet PyQRCode==1.2.1 --index-strategy unsafe-first-match --upgrade --constraint /homeassistant/homeassistant/package_constraints.txt
/homeassistant/venv/bin/uv pip install --quiet home-assistant-frontend==20250516.0 --index-strategy unsafe-first-match --upgrade --constraint /homeassistant/homeassistant/package_constraints.txt
/homeassistant/venv/bin/uv pip install --quiet aiousbwatcher==1.1.1 --index-strategy unsafe-first-match --upgrade --constraint /homeassistant/homeassistant/package_constraints.txt
/homeassistant/venv/bin/uv pip install --quiet async-upnp-client==0.44.0 --index-strategy unsafe-first-match --upgrade --constraint /homeassistant/homeassistant/package_constraints.txt
/homeassistant/venv/bin/python3.13 -m uv pip install --quiet go2rtc-client==0.1.2 --index-strategy unsafe-first-match --upgrade --constraint /homeassistant/homeassistant/package_constraints.txt
/homeassistant/venv/bin/uv pip install --quiet go2rtc-client==0.1.2 --index-strategy unsafe-first-match --upgrade --constraint /homeassistant/homeassistant/package_constraints.txt


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





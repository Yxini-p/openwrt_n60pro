#!/bin/bash

# Set default IP to 192.168.2.1 (matching user's current network)
sed -i 's/192.168.6.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# Create a first-boot script that displays ShellCrash install instructions
mkdir -p files/etc/banner
cat > files/etc/banner/shellcrash.txt << 'EOF'
========================================
ShellCrash 安装（SSH 执行一次即可）：
  curl -s https://raw.githubusercontent.com/juewuy/ShellCrash/master/install.sh | sh
========================================
EOF

# Remove unwanted packages from config
echo "# CONFIG_PACKAGE_htop is not set" >> .config
echo "# CONFIG_PACKAGE_nano is not set" >> .config
echo "# CONFIG_PACKAGE_luci-app-ssr-plus is not set" >> .config
echo "# CONFIG_PACKAGE_luci-app-passwall is not set" >> .config
echo "# CONFIG_PACKAGE_luci-app-vssr is not set" >> .config
echo "# CONFIG_PACKAGE_luci-app-wrtbwmon is not set" >> .config
echo "# CONFIG_PACKAGE_luci-app-eqos-mtk is not set" >> .config
echo "# CONFIG_PACKAGE_ksmbd is not set" >> .config
echo "# CONFIG_PACKAGE_miniupnpd is not set" >> .config

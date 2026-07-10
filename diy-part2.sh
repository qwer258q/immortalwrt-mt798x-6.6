#!/bin/bash

# =====================================================================
# diy-part2.sh - 适用于 qwer258q/immortalwrt-mt798x-6.6 (openwrt-24.10)
# 本地编译优化版（集成 mosdns 官方推荐的 v2ray-geodata 依赖）
# =====================================================================

echo "========== 开始执行 diy-part2.sh =========="

# =====================================================================
# 0. 自动应用 MT7986 默认配置
# =====================================================================
echo "正在复制 mt7986-ax6000.config ..."
if [ -f "defconfig/mt7986-ax6000.config" ]; then
    cp -f defconfig/mt7986-ax6000.config .config
    echo "✅ .config 配置文件已应用！"
else
    echo "⚠️ 未找到 defconfig/mt7986-ax6000.config"
fi

# =====================================================================
# 1. Golang 升级（前置处理，确保依赖正确覆盖）
# =====================================================================
echo "升级 Golang 到 26.x ..."
if [ -d "feeds/packages" ]; then
    rm -rf feeds/packages/lang/golang
    git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang
    echo "✅ Golang 26.x 源码已替换"
fi

# =====================================================================
# 2. 修改默认 LAN IP 为 192.168.31.1
# =====================================================================
echo "修改默认后台 IP 为 192.168.31.1 ..."
sed -i 's/192.168.6.1/192.168.31.1/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate
echo "✅ IP 修改完成"

# =====================================================================
# 3. 第三方插件处理 (遵循官方教程 & 清理本地缓存)
# =====================================================================

# 🛑 核心：彻底清理本地旧的 feeds 缓存和软链接（防止 package redefined 报错）
echo "正在清理旧的 mosdns 与 geodata 冲突残留..."
rm -rf feeds/packages/net/mosdns feeds/packages/net/v2ray-geodata
rm -rf package/feeds/packages/mosdns package/feeds/packages/v2ray-geodata

# 📦 安装 mosdns (sbwml版)
echo "安装 luci-app-mosdns ..."
rm -rf package/mosdns
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns

# 📦 安装 v2ray-geodata (sbwml版 - 官方教程要求)
echo "安装 v2ray-geodata ..."
rm -rf package/v2ray-geodata
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# 📦 安装 netspeedtest
echo "安装 luci-app-netspeedtest ..."
rm -rf package/netspeedtest
git clone --depth=1 https://github.com/muink/luci-app-netspeedtest.git package/netspeedtest

# 📦 安装 OpenClash (精准提取子目录，防止本地找不到 Makefile 导致不显示插件)
echo "安装 luci-app-openclash ..."
rm -rf package/luci-app-openclash
git clone --depth=1 https://github.com/vernesong/OpenClash.git /tmp/openclash
mv /tmp/openclash/luci-app-openclash package/luci-app-openclash
rm -rf /tmp/openclash

# =====================================================================
# 4. 赋予预置内核可执行权限
# =====================================================================
if [ -f "files/etc/openclash/core/clash_meta" ]; then
    echo "正在为预置的 clash_meta 内核赋予执行权限 ..."
    chmod +x files/etc/openclash/core/clash_meta
    echo "✅ 内核权限赋予成功"
else
    echo "ℹ️ 未在 files/etc/openclash/core/ 下找到 clash_meta，跳过权限赋予"
fi

# =====================================================================
# 5. 本地编译核心：重新安装和刷新 feeds 索引
# =====================================================================
echo "正在重新刷新本地 feeds 索引树..."
./scripts/feeds update -i
./scripts/feeds install -a

echo "========== diy-part2.sh 执行完成 =========="

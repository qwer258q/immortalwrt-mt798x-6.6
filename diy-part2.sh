#!/bin/bash

# =====================================================================
# diy-part2.sh - 适用于 qwer258q/immortalwrt-mt798x-6.6 (openwrt-24.10)
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
# 1. 修改默认 LAN IP 为 192.168.31.1
# =====================================================================
echo "修改默认后台 IP 为 192.168.31.1 ..."
sed -i 's/192.168.6.1/192.168.31.1/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate
echo "✅ IP 修改完成"

# =====================================================================
# 2. 第三方插件处理
# =====================================================================

# mosdns
echo "安装 luci-app-mosdns ..."
rm -rf package/mosdns feeds/luci/applications/luci-app-mosdns
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns

# v2ray-geodata（推荐使用 sbwml 版）
echo "安装 v2ray-geodata ..."
rm -rf feeds/packages/net/v2ray-geodata package/feeds/v2ray-geodata
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# netspeedtest
echo "安装 luci-app-netspeedtest ..."
rm -rf package/netspeedtest
git clone --depth=1 https://github.com/muink/luci-app-netspeedtest.git package/netspeedtest

# OpenClash
echo "安装 luci-app-openclash ..."
rm -rf package/luci-app-openclash
git clone --depth=1 https://github.com/vernesong/OpenClash.git package/luci-app-openclash

# =====================================================================
# 4. Golang 升级（解决依赖问题）
# =====================================================================
echo "升级 Golang 到 26.x ..."
if [ -d "feeds/packages" ]; then
    rm -rf feeds/packages/lang/golang
    git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang
    
    # 清理可能冲突的包
    rm -rf feeds/packages/net/mosdns feeds/packages/net/v2ray-geodata
    echo "✅ Golang 26.x 已替换"
fi

echo "========== diy-part2.sh 执行完成 =========="

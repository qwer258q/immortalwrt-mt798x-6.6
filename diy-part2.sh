#!/bin/bash

# =====================================================================
# diy-part2.sh - 适用于 qwer258q/immortalwrt-mt798x-6.6 (openwrt-24.10)
# 本地编译【强力清理·强制最新版】优化脚本
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
# 3. 强力清理源码自带旧插件 & 清理本地缓存
# =====================================================================
echo "正在强力斩草除根：清理源码自带的旧版 mosdns、geodata 以及历史残留..."

# 1. 彻底删除 feeds 目录下的旧源码
rm -rf feeds/packages/net/mosdns
rm -rf feeds/packages/net/v2ray-geodata

# 2. 彻底删除 package/feeds/ 软链接映射
rm -rf package/feeds/packages/mosdns
rm -rf package/feeds/packages/v2ray-geodata

# 3. 预防性删除 package 核心目录下可能同名的历史旧文件夹
rm -rf package/mosdns
rm -rf package/v2ray-geodata
rm -rf package/luci-app-mosdns
rm -rf package/luci-app-openclash
rm -rf package/netspeedtest

# 4. 清理编译临时索引缓存（极其关键！不删它，menuconfig里还是旧索引）
rm -rf tmp

echo "✅ 旧版源码与编译缓存清理完毕！"

# =====================================================================
# 4. 拉取全套最新版第三方插件
# =====================================================================

# 📦 安装 mosdns (sbwml最新版)
echo "正在拉取最新 luci-app-mosdns v5 ..."
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns

# 📦 安装 v2ray-geodata (sbwml最新版)
echo "正在拉取最新 v2ray-geodata ..."
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# 📦 安装 netspeedtest
echo "正在拉取最新 luci-app-netspeedtest ..."
git clone --depth=1 https://github.com/muink/luci-app-netspeedtest.git package/netspeedtest

# 📦 安装 OpenClash (精准提取最新版子目录)
echo "正在拉取最新 luci-app-openclash ..."
git clone --depth=1 https://github.com/vernesong/OpenClash.git /tmp/openclash
mv /tmp/openclash/luci-app-openclash package/luci-app-openclash
rm -rf /tmp/openclash

# =====================================================================
# 5. 赋予预置内核可执行权限
# =====================================================================
if [ -f "files/etc/openclash/core/clash_meta" ]; then
    echo "正在为预置的 clash_meta 内核赋予执行权限 ..."
    chmod +x files/etc/openclash/core/clash_meta
    echo "✅ 内核权限赋予成功"
else
    echo "ℹ️ 未在 files/etc/openclash/core/ 下找到 clash_meta，跳过权限赋予"
fi

# =====================================================================
# 6. 刷新并重新建立 feeds 索引
# =====================================================================
echo "正在重新刷新本地 feeds 索引树..."
./scripts/feeds update -a && ./scripts/feeds install -a

echo "========== diy-part2.sh 执行完成 =========="

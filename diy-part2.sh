#!/bin/bash

# =====================================================================
# diy-part2.sh - 适用于 qwer258q/immortalwrt-mt798x-6.6 (openwrt-24.10)
# 本地编译【一键自动化·完全体】脚本
# =====================================================================

echo "========== 开始执行 diy-part2.sh =========="

# =====================================================================
# 1. 【核心第一步】执行官方标准的全局 feeds 更新与安装（正如你所说）
# =====================================================================
echo "正在执行全局 feeds update ＆ install..."
./scripts/feeds update -a
./scripts/feeds install -a
echo "✅ 全局基础 feeds 树建立完毕"

# =====================================================================
# 2. 强力清理源码自带旧插件 & 清理本地缓存（破）
# =====================================================================
echo "正在强力斩草除根：清理源码自带的旧版 mosdns、geodata 以及历史残留..."

# 彻底删除刚刚 update/install 生成的旧源码索引
rm -rf feeds/packages/net/mosdns
rm -rf feeds/packages/net/v2ray-geodata

# 彻底删除 package/feeds/ 中的旧软链接映射
rm -rf package/feeds/packages/mosdns
rm -rf package/feeds/packages/v2ray-geodata

# 预防性删除核心目录下的历史同名文件夹
rm -rf package/mosdns
rm -rf package/v2ray-geodata
rm -rf package/luci-app-mosdns
rm -rf package/luci-app-openclash
rm -rf package/netspeedtest

# 清理旧的编译临时索引缓存
rm -rf tmp

echo "✅ 旧版源码与编译缓存清理完毕！"

# =====================================================================
# 3. 拉取全套最新版第三方插件（立）
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
# 4. 升级 Golang 到 26.x（确保新插件编译不报错）
# =====================================================================
echo "升级 Golang 到 26.x ..."
if [ -d "feeds/packages" ]; then
    rm -rf feeds/packages/lang/golang
    git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang
    echo "✅ Golang 26.x 源码已替换"
fi

# =====================================================================
# 5. 修改默认 LAN IP 为 192.168.31.1 并应用硬件配置
# =====================================================================
echo "正在复制 mt7986-ax6000.config ..."
if [ -f "defconfig/mt7986-ax6000.config" ]; then
    cp -f defconfig/mt7986-ax6000.config .config
    echo "✅ .config 配置文件已应用！"
else
    echo "⚠️ 未找到 defconfig/mt7986-ax6000.config"
fi

echo "修改默认后台 IP 为 192.168.31.1 ..."
sed -i 's/192.168.6.1/192.168.31.1/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate
echo "✅ IP 修改完成"

# =====================================================================
# 6. 赋予预置内核可执行权限
# =====================================================================
if [ -f "files/etc/openclash/core/clash_meta" ]; then
    echo "正在为预置的 clash_meta 内核赋予执行权限 ..."
    chmod +x files/etc/openclash/core/clash_meta
    echo "✅ 内核权限赋予成功"
else
    echo "ℹ️ 未在 files/etc/openclash/core/ 下找到 clash_meta，跳过权限赋予"
fi

# =====================================================================
# 7. 【核心最后一步】重新刷新本地 feeds 索引树，登记新换上的最新版插件
# =====================================================================
echo "正在重新刷新本地 feeds 索引树..."
./scripts/feeds update -i
./scripts/feeds install -a

echo "========== diy-part2.sh 执行完成 =========="

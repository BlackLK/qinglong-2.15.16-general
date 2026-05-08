##########################################################################################
#
# Magisk模块安装脚本
#
##########################################################################################
##########################################################################################
#
# 使用说明:
#
# 1. 将文件放入系统文件夹(删除placeholder文件)
# 2. 在module.prop中填写您的模块信息
# 3. 在此文件中配置和调整
# 4. 如果需要开机执行脚本，请将其添加到post-fs-data.sh或service.sh
# 5. 将其他或修改的系统属性添加到system.prop
#
##########################################################################################
##########################################################################################
#
# 安装框架将导出一些变量和函数。
# 您应该使用这些变量和函数来进行安装。
#
# !请不要使用任何Magisk的内部路径，因为它们不是公共API。
# !请不要在util_functions.sh中使用其他函数，因为它们也不是公共API。
# !不能保证非公共API在版本之间保持兼容性。
#
# 可用变量:
#
# MAGISK_VER (string):当前已安装Magisk的版本的字符串(字符串形式的Magisk版本)
# MAGISK_VER_CODE (int):当前已安装Magisk的版本的代码(整型变量形式的Magisk版本)
# BOOTMODE (bool):如果模块当前安装在Magisk Manager中，则为true。
# MODPATH (path):你的模块应该被安装到的路径
# TMPDIR (path):一个你可以临时存储文件的路径
# ZIPFILE (path):模块的安装包（zip）的路径
# ARCH (string): 设备的体系结构。其值为arm、arm64、x86、x64之一
# IS64BIT (bool):如果$ARCH(上方的ARCH变量)为arm64或x64，则为true。
# API (int):设备的API级别（Android版本）
#
# 可用函数:
#
# ui_print <msg>
#     打印(print)<msg>到控制台
#     避免使用'echo'，因为它不会显示在定制recovery的控制台中。
#
# abort <msg>
#     打印错误信息<msg>到控制台并终止安装
#     避免使用'exit'，因为它会跳过终止的清理步骤
#
##########################################################################################

##########################################################################################
# SKIPUNZIP
##########################################################################################

# 如果您需要更多的自定义，并且希望自己做所有事情
# 请在custom.sh中标注SKIPUNZIP=1
# 以跳过提取操作并应用默认权限/上下文上下文步骤。
# 请注意，这样做后，您的custom.sh将负责自行安装所有内容。
SKIPUNZIP=0

##########################################################################################
# 替换列表
##########################################################################################

# 列出你想在系统中直接替换的所有目录
# 查看文档，了解更多关于Magic Mount如何工作的信息，以及你为什么需要它


# 按照以下格式构建列表
# 这是一个示例
REPLACE_EXAMPLE="

"

# 在这里建立您自己的清单
REPLACE="
"
##########################################################################################
# 安装设置
##########################################################################################

# 如果SKIPUNZIP=1您将会需要使用以下代码
# 当然，你也可以自定义安装脚本
# 需要时请删除#
# 将 $ZIPFILE 提取到 $MODPATH
#  ui_print "- 解压模块文件"
#  unzip -o "$ZIPFILE" -x 'META-INF/*' -d $MODPATH >&2
# 删除多余文件
# rm -rf \
# $MODPATH/system/placeholder $MODPATH/customize.sh \
# $MODPATH/*.md $MODPATH/.git* $MODPATH/LICENSE 2>/dev/null

if [ -x /data/adb/magisk/busybox ]; then
busybox=/data/adb/magisk/busybox
ui_print "- 检测到 Magisk 环境"
elif [ -x /data/adb/ksu/bin/busybox ]; then
busybox=/data/adb/ksu/bin/busybox
ui_print "- 检测到 KernelSU / SukiSU Ultra 环境"
elif [ -x /data/adb/ap/bin/busybox ]; then
busybox=/data/adb/ap/bin/busybox
ui_print "- 检测到 APatch 环境"
elif command -v busybox >/dev/null 2>&1; then
busybox=$(command -v busybox)
ui_print "- 检测到系统 BusyBox"
else
abort "- 未找到可用的 BusyBox！"
fi
ui_print "- 正在初始化 BusyBox 环境"
rm -rf /dev/busybox
mkdir -p /dev/busybox || abort "- 创建 BusyBox 目录失败！"
$busybox --install -s /dev/busybox || abort "- 初始化 BusyBox 失败！"
export PATH=/dev/busybox:$PATH
export rootfs=/data/local/debian
export installlog=/data/adb/qinglong-install.log
export installlog2=/data/local/tmp/qinglong-install.log
rm -f "$installlog"
rm -f "$installlog2"
touch "$installlog"
touch "$installlog2"

device_model=$(getprop ro.product.model 2>/dev/null)
device_name=$(getprop ro.product.name 2>/dev/null)
device_abi=$(getprop ro.product.cpu.abi 2>/dev/null)
android_version=$(getprop ro.build.version.release 2>/dev/null)
kernel_arch=$(uname -m 2>/dev/null)
ui_print "- 设备型号：${device_model:-unknown}"
ui_print "- 设备代号：${device_name:-unknown}"
ui_print "- Android 版本：${android_version:-unknown}"
ui_print "- CPU ABI：${device_abi:-unknown}"
ui_print "- 内核架构：${kernel_arch:-unknown}"
ui_print "- 64 位设备同样需要 Debian rootfs，当前将使用 arm64 Linux 用户态环境"
ui_print "- rootfs 临时路径：$rootfs"
echo "[设备] 型号：${device_model:-unknown}" >> "$installlog"
echo "[设备] 代号：${device_name:-unknown}" >> "$installlog"
echo "[设备] Android：${android_version:-unknown}" >> "$installlog"
echo "[设备] CPU ABI：${device_abi:-unknown}" >> "$installlog"
echo "[设备] 内核架构：${kernel_arch:-unknown}" >> "$installlog"
echo "[说明] 64 位 Android 设备仍需要 arm64 Debian rootfs 作为青龙运行环境" >> "$installlog"

print_log_tail()
{
  ui_print "- 最近安装日志："
  tail -60 "$installlog" 2>/dev/null | while read line
  do
    ui_print "  $line"
  done
  if [ ! -s "$installlog" ] && [ -s "$installlog2" ]; then
    tail -60 "$installlog2" 2>/dev/null | while read line
    do
      ui_print "  $line"
    done
  fi
  if [ -f "$rootfs/root/qinglong-install.log" ]; then
    tail -60 "$rootfs/root/qinglong-install.log" 2>/dev/null | while read line
    do
      ui_print "  $line"
    done
  fi
}

log_msg()
{
  echo "$1" >> "$installlog"
  echo "$1" >> "$installlog2"
  [ -d "$rootfs/root" ] && echo "$1" >> "$rootfs/root/qinglong-install.log"
}

run_chroot()
{
  step="$1"
  cmd="$2"
  ui_print "- $step"
  log_msg "[$step] 开始"
  chroot $rootfs /usr/bin/env -i HOME=/root PATH=/usr/local/node18/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin PNPM_HOME=/usr/local/bin NPM_CONFIG_PREFIX=/usr/local TERM=linux SHELL=/bin/bash LANG=zh_CN.utf8 /bin/bash -lc "$cmd" >> "$installlog" 2>&1
  rc=$?
  cat "$installlog" > "$installlog2" 2>/dev/null
  [ -d "$rootfs/root" ] && cat "$installlog" > "$rootfs/root/qinglong-install.log" 2>/dev/null
  if [ "$rc" != "0" ]; then
    log_msg "[$step] 失败，退出码：$rc"
    print_log_tail
    abort "- $step 失败，退出码：$rc，详细日志：/data/adb/qinglong-install.log"
  fi
  log_msg "[$step] 完成"
}

unmountdir()
{
  fuser -k $rootfs 2>/dev/null

  for umount_dir in $(cat /proc/mounts | awk '{print $2}' | grep "^$rootfs" | sort -r)
  do
    umount -f ${umount_dir} 2>/dev/null || umount -l ${umount_dir} 2>/dev/null
    wait
  done
}

if [ -e "$rootfs/proc/1" ]; then
ui_print "- 检测到旧 Debian 环境残留，正在尝试清理"
unmountdir
if [ -e "$rootfs/proc/1" ]; then
abort "- 旧 Debian 环境仍被占用，请重启平板后再次安装！"
fi
fi
rm -rf $rootfs
ui_print "- 正在释放 Debian 根文件系统"
echo "[解包] 开始释放 Debian 根文件系统" >> "$installlog"
tar -xf $MODPATH/debian.tar.bz2 -C /data/local >> "$installlog" 2>&1 || {
print_log_tail
abort "- Debian 根文件系统释放失败！"
}
rm -f $rootfs/root/qinglong-install.log
touch $rootfs/root/qinglong-install.log
rm -f $MODPATH/debian.tar.bz2

ui_print "- 正在安装预置 Node.js 18 arm64"
log_msg "[Node.js] 正在安装预置 Node.js 18 arm64"
mkdir -p $rootfs/usr/local
rm -rf $rootfs/usr/local/node18 $rootfs/usr/local/node-v18.20.8-linux-arm64
tar -xzf $MODPATH/preload/nodejs.tar.gz -C $rootfs/usr/local >> "$installlog" 2>&1 || {
print_log_tail
abort "- 预置 Node.js 18 解压失败！"
}
mv $rootfs/usr/local/node-v18.20.8-linux-arm64 $rootfs/usr/local/node18 >> "$installlog" 2>&1 || {
print_log_tail
abort "- 预置 Node.js 18 安装失败！"
}
mkdir -p $rootfs/usr/local/bin
ln -sf /usr/local/node18/bin/node $rootfs/usr/local/bin/node
ln -sf /usr/local/node18/bin/npm $rootfs/usr/local/bin/npm
ln -sf /usr/local/node18/bin/npx $rootfs/usr/local/bin/npx
ln -sf /usr/local/node18/bin/corepack $rootfs/usr/local/bin/corepack
rm -rf $rootfs/usr/local/lib/node_modules/pnpm
log_msg "[Node.js] 预置 Node.js 18 安装完成"

ui_print "- 正在修复 Debian 软件源"
echo "[软件源] 正在修复 Debian 软件源" >> "$installlog"
rm -f $rootfs/etc/apt/sources.list.d/nodesource.list
cat > $rootfs/etc/apt/sources.list << EOF
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main contrib non-free
EOF
cat $rootfs/etc/apt/sources.list >> "$installlog" 2>&1

if [ -d "/data/debian/ql/data" ]
then
ui_print "- 正在迁移已有青龙数据"
rm -rf /data/debian/ql/data/scripts/node_modules
cp /data/debian/ql/data -R $rootfs/ql >> "$installlog" 2>&1 || {
print_log_tail
abort "- 迁移已有青龙数据失败！"
}
fi
if [ -d "/data/alpine/ql/data" ]
then
ui_print "- 正在迁移 Alpine 青龙数据"
rm -rf /data/alpine/ql/data/scripts/node_modules
cp /data/alpine/ql/data -R $rootfs/ql >> "$installlog" 2>&1 || {
print_log_tail
abort "- 迁移 Alpine 青龙数据失败！"
}
fi

ui_print "- 正在调整青龙运行配置"
echo "[配置] 正在调整青龙运行配置" >> "$installlog"
sed -i 's/var\/log\/nginx\/error.log/dev\/null/g' $rootfs/ql/docker/nginx.conf >> "$installlog" 2>&1 || {
print_log_tail
abort "- 调整 nginx 配置失败！"
}
sed -i 's/nginx -s reload 2>\/dev\/null || nginx -c \/etc\/nginx\/nginx.conf/pm2 start \"nginx -c \/etc\/nginx\/nginx.conf\"/' $rootfs/ql/docker/docker-entrypoint.sh >> "$installlog" 2>&1 || {
print_log_tail
abort "- 调整青龙启动脚本失败！"
}
sed -i 's/pip3 install/pip3 install --no-cache/g' $rootfs/ql/static/build/data/dependence.js >> "$installlog" 2>&1 || {
print_log_tail
abort "- 调整依赖安装配置失败！"
}
set_perm $MODPATH/init 0 0 0755

ui_print "- 正在初始化 Debian 环境"
echo "[初始化] 正在初始化 Debian 环境" >> "$installlog"
$MODPATH/init $rootfs >> "$installlog" 2>&1 || {
print_log_tail
abort "- 初始化 Debian 环境失败！"
}
ui_print "- 正在尝试重新挂载 Debian 根目录"
chroot $rootfs /usr/bin/env -i HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=linux SHELL=/bin/bash LANG=zh_CN.utf8 /bin/bash -lc 'mount -o remount,exec,suid,dev /' >> "$installlog" 2>&1 || ui_print "- Debian 根目录重新挂载失败，继续安装并记录日志"
ui_print "- 正在安装青龙面板依赖，耗时较长请耐心等待"
run_chroot "依赖 1/17：打印系统信息" "cat /etc/os-release 2>/dev/null || true; uname -m 2>/dev/null || true"
run_chroot "依赖 2/17：打印 APT 软件源" "cat /etc/apt/sources.list 2>/dev/null || true; ls -la /etc/apt/sources.list.d 2>/dev/null || true"
run_chroot "依赖 3/17：执行 apt update" "apt update"
run_chroot "依赖 4/17：检查预置 Node / npm" "node -v; npm -v"
run_chroot "依赖 5/17：安装 netcat-openbsd" "apt install --no-install-recommends -y netcat-openbsd"
run_chroot "依赖 6/17：安装 build-essential" "apt install --no-install-recommends -y build-essential"
run_chroot "依赖 7/17：安装 libc6-dev" "apt install --no-install-recommends -y libc6-dev"
run_chroot "依赖 8/17：安装 python3-dev" "apt install --no-install-recommends -y python3-dev"
run_chroot "依赖 9/17：安装 python-is-python3" "apt install --no-install-recommends -y python-is-python3"
run_chroot "依赖 10/17：安装 python3-pip" "apt install --no-install-recommends -y python3-pip"
run_chroot "依赖 11/17：检查 Node / npm / Python" "node -v; npm -v; python3 --version"
run_chroot "依赖 12/17：安装 pnpm 8" "npm config set prefix /usr/local && npm --registry https://registry.npmmirror.com i -g pnpm@8.15.9"
run_chroot "依赖 13/17：配置 pnpm 镜像" "pnpm config set -g registry https://registry.npmmirror.com"
run_chroot "依赖 14/17：安装 pm2" "pnpm add -g pm2"
run_chroot "依赖 15/17：安装 tsx" "pnpm add -g tsx"
run_chroot "依赖 16/17：安装青龙生产依赖" "cd /ql && pnpm install --prod"
run_chroot "依赖 17/17：修复青龙配置并清理缓存" "cd /ql && . /ql/shell/share.sh && fix_config && update_depend && rm -rf /root/.pnpm-store /root/.local/share/pnpm/store /root/.cache /root/.npm"

unmountdir
ui_print "- 青龙面板模块安装完成，重启后访问 http://127.0.0.1:5700"
ui_print "- 已启用开机保护机制：服务将在晚启动阶段运行"
ui_print "- 关键启动步骤超时时间：60 秒"
ui_print "- 连续 3 次启动失败后模块会自动禁用，避免反复卡开机"
ui_print "- 开机服务日志：/data/adb/qinglong-module.log"
##########################################################################################
# 权限设置
##########################################################################################

  #如果添加到此功能，请将其删除

  # 请注意，magisk模块目录中的所有文件/文件夹都有$MODPATH前缀-在所有文件/文件夹中保留此前缀
  # 一些例子:
  
  # 对于目录(包括文件):
  # set_perm_recursive  <目录>                <所有者> <用户组> <目录权限> <文件权限> <上下文> (默认值是: u:object_r:system_file:s0)
  
  # set_perm_recursive $MODPATH/system/lib 0 0 0755 0644
  # set_perm_recursive $MODPATH/system/vendor/lib/soundfx 0 0 0755 0644

  # 对于文件(不包括文件所在目录)
  # set_perm  <文件名>                         <所有者> <用户组> <文件权限> <上下文> (默认值是: u:object_r:system_file:s0)
  
  # set_perm $MODPATH/system/lib/libart.so 0 0 0644
  # set_perm /data/local/tmp/file.txt 0 0 644

  # 默认权限请勿删除
  #set_perm_recursive $MODPATH 0 0 0755 0644

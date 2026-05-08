#!/system/bin/sh
# 不要假设您的模块将位于何处。
# 如果您需要知道此防跳和模块的放置位置，请使用$MODDIR
# 这将确保您的模块仍能正常工作
# 即使Magisk将来更改其挂载点
MODDIR=${0%/*}
export rootfs=/data/local/debian
logfile=/data/adb/qinglong-module.log
failfile=/data/adb/qinglong-module.fail
maxfails=3

if [ -x /data/adb/magisk/busybox ]; then
busybox=/data/adb/magisk/busybox
elif [ -x /data/adb/ksu/bin/busybox ]; then
busybox=/data/adb/ksu/bin/busybox
elif [ -x /data/adb/ap/bin/busybox ]; then
busybox=/data/adb/ap/bin/busybox
elif command -v busybox >/dev/null 2>&1; then
busybox=$(command -v busybox)
else
exit 1
fi

(
sleep 45

echo "$(date '+%Y-%m-%d %H:%M:%S') 青龙模块服务启动" >> "$logfile"

fails=0
[ -f "$failfile" ] && fails=$(cat "$failfile" 2>/dev/null)
[ -z "$fails" ] && fails=0
if [ "$fails" -ge "$maxfails" ]; then
echo "$(date '+%Y-%m-%d %H:%M:%S') 连续启动失败，已自动禁用模块" >> "$logfile"
touch "$MODDIR/disable"
exit 1
fi

if [ ! -d "$rootfs" ]; then
echo "$(date '+%Y-%m-%d %H:%M:%S') Debian 根目录不存在，退出" >> "$logfile"
exit 1
fi

if [ ! -d "$rootfs/sys/kernel" ]; then
$busybox timeout 60 "$MODDIR/init" "$rootfs" >> "$logfile" 2>&1 || {
fails=$((fails + 1))
echo "$fails" > "$failfile"
echo "$(date '+%Y-%m-%d %H:%M:%S') 初始化 Debian 环境失败，失败次数：$fails" >> "$logfile"
exit 1
}
fi

$busybox timeout 45 chroot $rootfs /usr/bin/env -i HOME=/root PATH=/usr/local/node18/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=linux SHELL=/bin/bash LANG=zh_CN.utf8 /bin/su - root -c 'mount -o remount,exec,suid,dev / && ls -1 /etc/init.d | xargs -I {} service {} start' >> "$logfile" 2>&1 || {
fails=$((fails + 1))
echo "$fails" > "$failfile"
echo "$(date '+%Y-%m-%d %H:%M:%S') 启动系统服务失败，失败次数：$fails" >> "$logfile"
exit 1
}

$busybox start-stop-daemon -S -b chroot -- $rootfs /bin/su - root -c "source /root/.bashrc && cd /ql && /ql/docker/docker-entrypoint.sh" >> "$logfile" 2>&1 || {
fails=$((fails + 1))
echo "$fails" > "$failfile"
echo "$(date '+%Y-%m-%d %H:%M:%S') 启动青龙面板失败，失败次数：$fails" >> "$logfile"
exit 1
}

rm -f "$failfile"
echo "$(date '+%Y-%m-%d %H:%M:%S') 青龙模块服务启动完成" >> "$logfile"

#酷友提供
echo "PowerManagerService.noSuspend" > /sys/power/wake_lock
dumpsys deviceidle disable

) >/dev/null 2>&1 &

exit 0

#!/system/bin/sh
# 不要假设您的模块将位于何处。
# 如果您需要知道此防跳和模块的放置位置，请使用$MODDIR
# 这将确保您的模块仍能正常工作
# 即使Magisk将来更改其挂载点
export rootfs=/data/debian

if [ ! -d "$rootfs/sys/kernel" ]
then
${0%/*}/init "$rootfs"
fi

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

chroot $rootfs /usr/bin/env -i HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=linux SHELL=/bin/bash LANG=zh_CN.utf8 /bin/su - root -c 'mount -o remount,exec,suid,dev / && ls -1 /etc/init.d | xargs -I {} service {} start'
$busybox start-stop-daemon -S -b chroot -- $rootfs /bin/su - root -c "source /root/.bashrc && cd /ql && /ql/docker/docker-entrypoint.sh"

#酷友提供
echo "PowerManagerService.noSuspend" > /sys/power/wake_lock
dumpsys deviceidle disable

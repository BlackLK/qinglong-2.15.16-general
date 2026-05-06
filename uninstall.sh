# 该脚本将在卸载期间执行，您可以编写自定义卸载规则
export rootfs=/data/debian

unmountdir()
{
  fuser -k $rootfs

  for umount_dir in $(cat /proc/mounts | awk '{print $2}' | grep "^$rootfs" | sort -r)
  do
    umount -f ${umount_dir}
    wait
  done
}

unmountdir
rm -rf $rootfs
rm -rf /data/local/debian

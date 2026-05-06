# 青龙面板 Magisk / KernelSU / SukiSU Ultra 模块

这是从原始 `2.15.16(20230622).zip` 展开的模块源码目录，已针对新版 Magisk 安装器以及 KernelSU/SukiSU Ultra 兼容性做调整。

模块作者：`stuka`

## 主要调整

- 更新 `META-INF/com/google/android/update-binary` 为 Magisk 官方推荐的新版安装入口形式。
- 刷入过程使用中文日志输出，便于在管理器安装界面查看进度。
- `customize.sh` 不再只依赖固定的 Magisk/KernelSU BusyBox 路径，会自动探测：
  - `/data/adb/magisk/busybox`
  - `/data/adb/ksu/bin/busybox`
  - `/data/adb/ap/bin/busybox`
  - 系统 `busybox`
- `service.sh` 使用同样的 BusyBox 探测逻辑，兼容 Magisk、KernelSU、SukiSU Ultra 以及 APatch 类环境。
- 开机启动加入保护机制：重型初始化移到晚启动阶段，关键步骤带 60 秒超时，连续 3 次失败会自动禁用模块。
- 仓库 `.gitignore` 已排除 zip 包。

## 已知注意事项

- `debian.tar.bz2` 约 136MB，超过 GitHub 普通单文件 100MB 限制，不能直接用普通 Git 上传。
- 如果需要上传完整源码，建议使用 Git LFS 管理 `debian.tar.bz2`，或者把该文件放到 GitHub Release 附件中。
- 安装过程中会执行 `apt`、`npm`、`pnpm` 等联网安装步骤，刷入设备需要能访问对应源。
- 开机服务日志路径：`/data/adb/qinglong-module.log`。

## 打包方式

在本目录内打包时，确保 zip 根目录直接包含 `module.prop`、`customize.sh`、`META-INF` 等文件。

PowerShell 示例：

```powershell
Compress-Archive -Path .\* -DestinationPath ..\qinglong-2.15.16-magisk27-sukisu.zip -Force
```

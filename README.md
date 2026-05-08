# 青龙面板 Magisk / KernelSU / SukiSU Ultra 模块

这是从原始 `2.15.16(20230622).zip` 展开的青龙面板模块源码目录，已针对新版 Magisk、KernelSU、SukiSU Ultra 以及 APatch 类环境做兼容性调整。

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
- 预置官方 Linux arm64 `Node.js 18`，避免 Debian rootfs 自带 `Node.js 12` 与新版 `pnpm` 不兼容。
- 固定安装 `pnpm@8.15.9`，并使用国内镜像源。
- 生产依赖安装使用更详细的 `pnpm` 输出，便于观察 `sqlite3` 等原生依赖编译进度。
- 开机启动加入保护机制：服务脚本会立即返回，后台延迟 45 秒启动青龙，连续 3 次失败会自动禁用模块。
- 仓库 `.gitignore` 已排除 zip 包。

## 使用方法

1. 将打包好的模块 zip 复制到设备。
2. 在 Magisk、KernelSU、SukiSU Ultra 或 APatch 的模块管理页面中刷入。
3. 刷入过程中会显示中文安装日志，请等待依赖安装完成。
4. 刷入完成后重启设备。
5. 设备开机后等待约 1 分钟，让后台服务完成启动。
6. 在设备本机浏览器中打开：

```text
http://127.0.0.1:5700
```

如果需要从同一局域网其他设备访问，请先确认设备 IP，并访问：

```text
http://设备IP:5700
```

部分系统或网络环境可能限制外部访问，优先使用设备本机 `127.0.0.1:5700` 验证。

## 启动与日志

- 青龙 rootfs 安装时位于 `/data/local/debian`。
- 开机早期会由 `post-fs-data.sh` 移动到 `/data/debian`。
- 青龙服务由 `service.sh` 在晚启动阶段后台启动。
- 面板默认端口为 `5700`。
- 安装日志路径：

```text
/data/adb/qinglong-install.log
/data/local/tmp/qinglong-install.log
```

- 开机服务日志路径：

```text
/data/adb/qinglong-module.log
```

## 验证方式

设备连接 ADB 后，可以用以下命令检查面板是否启动：

```shell
adb shell su -c "netstat -ltn | grep 5700"
adb shell su -c "curl -I --max-time 5 http://127.0.0.1:5700"
```

正常情况下应能看到 `5700` 端口监听，并返回 `HTTP/1.1 200 OK`。

## 故障处理

- 如果刷入时卡在“安装青龙生产依赖”，通常是在下载或编译 `sqlite3` 等原生依赖，可能需要数分钟。
- 如果刷入失败，请查看 `/data/adb/qinglong-install.log` 或 `/data/local/tmp/qinglong-install.log`。
- 如果开机后面板无法访问，请查看 `/data/adb/qinglong-module.log`。
- 如果设备卡开机，请进入 root 管理器安全模式或 Recovery，禁用/删除模块目录：

```text
/data/adb/modules/qinglong
/data/adb/modules_update/qinglong
```

也可以在模块目录下创建空文件 `disable` 禁用模块。

## 已知注意事项

- `debian.tar.bz2` 约 136MB，超过 GitHub 普通单文件 100MB 限制，不能直接用普通 Git 上传。
- 如果需要上传完整源码，建议使用 Git LFS 管理 `debian.tar.bz2`，或者把该文件放到 GitHub Release 附件中。
- 模块额外预置 `Node.js 18 arm64`，因此打包后体积会明显变大。
- 安装过程中仍会执行 `apt`、`npm`、`pnpm` 等联网安装步骤，刷入设备需要能访问对应源。
- 当前模块主要面向 `arm64-v8a` 设备测试。

## 打包方式

在本目录内打包时，确保 zip 根目录直接包含 `module.prop`、`customize.sh`、`META-INF` 等文件。

PowerShell 示例：

```powershell
Compress-Archive -Path .\* -DestinationPath ..\qinglong-2.15.16-general-test-v2.zip -Force
```

@echo off
chcp 65001 > nul 2>&1
:: ==============================================
:: 纯手动配置参数区（使用半角符号，注释单独成行，无格式错误）
:: 编码：UTF-8 with BOM  换行：CRLF  兼容 Windows CMD 环境
:: 注意：修改以下参数即可切换架构/系统，无需改动其他脚本内容
:: ==============================================
:: 目标架构：arm64 / amd64 / arm / 386（Go 支持的规范架构名称）
set "TARGET_ARCH=amd64"
:: 目标系统：linux / windows / darwin（Go 支持的规范系统名称）
set "TARGET_OS=windows"
:: 产物后缀：Windows 系统填 ".exe"，Linux/macOS 系统填 ""（直接留空，不要添加任何字符）
set "EXE_SUFFIX=.exe"
:: 产物基础名称（无需修改，保持 frps/frpc 即可）
set "FRPS_NAME=frps"
set "FRPC_NAME=frpc"
:: ==============================================

:: 拼接最终产物名称（语法规范，无变量混乱，仅做简单字符串拼接）
set "FINAL_FRPS=%FRPS_NAME%%EXE_SUFFIX%"
set "FINAL_FRPC=%FRPC_NAME%%EXE_SUFFIX%"

:: 脚本标题和基础信息输出
title frp %TARGET_ARCH%-%TARGET_OS% 手动配置构建脚本（Windows CMD 版）
color 0E
:: 补充：兼容 UTF-8 输出，避免部分 Windows 系统中文换行错乱或显示异常
set "PYTHONIOENCODING=utf-8"
echo ==============================================
echo          frp %TARGET_ARCH%-%TARGET_OS% 手动配置构建脚本
echo          无自动检测，纯手动配置，兼容 CMD 环境
echo ==============================================
echo  当前手动配置：
echo  架构=%TARGET_ARCH%  目标系统=%TARGET_OS%  产物后缀=%EXE_SUFFIX%
echo  最终产物：%FINAL_FRPS% 、%FINAL_FRPC%
echo ==============================================
echo.

:: 步骤 1：检查当前目录是否为 frp 项目根目录（必须包含 cmd/frps 目录）
if not exist "./cmd/frps" (
    color 0C
    echo 错误：当前目录不是 frp 项目根目录！
    echo 请切换到包含 cmd/、web/ 目录的 frp 根目录后运行此脚本
    pause
    exit /b 1
)

:: 步骤 2：清理旧的静态资源和构建产物（确保目录结构干净，避免旧文件干扰）
color 0E
echo === 步骤 1/4：清理旧资源 ===
echo 正在删除旧的静态资源目录...
:: 强制递归删除目录，忽略不存在的错误（2>nul 隐藏错误提示）
rd /s /q "./assets/frps/static" 2>nul
rd /s /q "./assets/frpc/static" 2>nul
:: 重新创建必要目录（确保后续复制操作和编译操作有对应的目录）
md "./assets/frps/static" 2>nul
md "./assets/frpc/static" 2>nul
md "./bin" 2>nul
md "./web/frps/dist" 2>nul
md "./web/frpc/dist" 2>nul
echo 正在删除旧的构建产物...
:: 删除旧的编译产物，避免新旧产物混淆
del /f /q "./bin/%FINAL_FRPS%" 2>nul
del /f /q "./bin/%FINAL_FRPC%" 2>nul
echo 旧资源清理完成！
echo.

:: 步骤 3：复制 web 静态资源（修复循环复制错误，创建占位文件避免编译失败）
echo === 步骤 2/4：复制 web 静态资源 ===
echo 正在创建静态资源占位文件（避免 embed.go 编译失败）...
:: 创建空的占位文件，解决 frp 编译时要求 static 目录非空的问题
echo placeholder > "./assets/frps/static/placeholder.txt"
echo placeholder > "./assets/frpc/static/placeholder.txt"

:: 复制 frps web 静态资源（若存在 dist 目录则复制，否则跳过）
if exist "./web/frps/dist" (
    echo 正在复制 frps web 静态资源...
    :: xcopy 命令参数说明：/e 复制所有子目录（包括空目录）；/i 假定目标是目录；/h 复制隐藏文件；/y 覆盖不提示
    xcopy /e /i /h /y "./web/frps/dist" "./assets/frps/static\" >nul 2>&1
    if errorlevel 0 (
        echo frps web 静态资源复制完成！
    ) else (
        echo frps web 静态资源复制跳过（无有效文件或复制失败）
    )
) else (
    color 0D
    echo 警告：未找到 ./web/frps/dist 目录，已创建占位文件确保编译正常
    color 0E
)

:: 复制 frpc web 静态资源（若存在 dist 目录则复制，否则跳过）
if exist "./web/frpc/dist" (
    echo 正在复制 frpc web 静态资源...
    xcopy /e /i /h /y "./web/frpc/dist" "./assets/frpc/static\" >nul 2>&1
    if errorlevel 0 (
        echo frpc web 静态资源复制完成！
    ) else (
        echo frpc web 静态资源复制跳过（无有效文件或复制失败）
    )
) else (
    color 0D
    echo 警告：未找到 ./web/frpc/dist 目录，已创建占位文件确保编译正常
    color 0E
)
echo.

:: 步骤 4：配置 Go 交叉编译环境，构建指定架构/系统产物
echo === 步骤 3/4：交叉编译 frp %TARGET_ARCH%-%TARGET_OS% ===
:: 检查 Go 环境是否安装并配置成功
go version >nul 2>&1
if errorlevel 1 (
    color 0C
    echo 错误：未检测到 Go 环境！
    echo 排查提示：1. 请先安装 Go 1.16 及以上版本 2. 已安装请配置 Go 环境变量到 PATH 中
    pause
    exit /b 1
)

:: 配置 Go 交叉编译核心参数（读取手动配置的架构和系统，无自动适配）
set "GOARCH=%TARGET_ARCH%"
set "GOOS=%TARGET_OS%"
set "CGO_ENABLED=0"

:: 编译 frps 服务端产物
echo 正在编译 %FINAL_FRPS%（服务端）...
go build -trimpath -ldflags "-s -w" -o "./bin/%FINAL_FRPS%" "./cmd/frps"

:: 检查 frps 编译是否失败
if errorlevel 1 (
    color 0C
    echo 错误：%FINAL_FRPS% 编译失败！
    echo 排查提示：1. 架构/系统配置是否为 Go 支持的规范名称 2. assets 目录是否有占位文件 3. frp 源码是否完整
    pause
    exit /b 1
)

:: 编译 frpc 客户端产物
echo 正在编译 %FINAL_FRPC%（客户端）...
go build -trimpath -ldflags "-s -w" -o "./bin/%FINAL_FRPC%" "./cmd/frpc"

:: 检查 frpc 编译是否失败
if errorlevel 1 (
    color 0C
    echo 错误：%FINAL_FRPC% 编译失败！
    echo 排查提示：1. 架构/系统配置是否为 Go 支持的规范名称 2. assets 目录是否有占位文件 3. frp 源码是否完整
    pause
    exit /b 1
)
echo 编译完成！
echo.

:: 步骤 5：验证构建结果（彻底消除 CMD 解析错误，验证产物是否真实存在）
echo === 步骤 4/4：验证构建结果 ===
if exist "./bin/%FINAL_FRPS%" if exist "./bin/%FINAL_FRPC%" (
    echo 构建成功！frp 产物已生成在 ./bin 目录下：
    echo ----------------------------------------------
    :: 列出 bin 目录下的目标产物，隐藏其他无关文件
    dir "./bin/" | findstr "%FRPS_NAME% %FRPC_NAME%"
    echo ----------------------------------------------
    echo.
    echo frp %TARGET_ARCH%-%TARGET_OS% 构建全流程完成！
) else (
    color 0C
    echo 构建失败！未找到生成的 %FINAL_FRPS%/%FINAL_FRPC% 产物，请检查编译日志。
    echo 排查提示：1. 请手动查看编译过程中的错误提示 2. 确认 bin 目录是否有足够的写入权限
)

echo.
color 0E
echo 按任意键退出...
pause >nul
exit /b 0
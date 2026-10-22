# 复用原生 DAT 生成器

assets/generate_dat.c.in 来自验证过的 V008 生成器，已移除具体功能名称。只生成同目录 DAT，不注册插件、不写 config.pro、不改安全选项。

在独立构建/暂存目录准备 JSON：

```json
{
  "app_id": "AcmeSurfaceTool",
  "folder_name": "AcmeSurfaceTool",
  "dll_name": "acme_surface_v001.dll",
  "version": "V001",
  "required_files": [
    "text/acme_surface_msg.txt",
    "text/chinese_cn/acme_surface_msg.txt",
    "text/usascii/acme_surface_msg.txt",
    "text/resource/acme_surface.png"
  ]
}
```

清单须包含实际必需的所有资源和外部帮助程序，DLL 自动加入。本例只演示格式，不是通用完整清单。

```text
python scripts/render_registration.py spec.json --stage <独立暂存目录> --source <构建目录/GenerateDAT.c>
```

脚本检查必需文件，然后生成暂存目录的 protk.dat（默认 C:\<folder_name>、ASCII CRLF）和参数化的原生 Windows C 源码。

在已配置的 x64 MSVC 环境编译：

```text
cl /nologo /utf-8 /W4 /WX /O2 /MT GenerateDAT.c /link /SUBSYSTEM:WINDOWS /MACHINE:X64 user32.lib /OUT:GenerateDAT.exe
```

/MT 使生成器本身无需额外 VC++ 运行库，插件 DLL 的运行库需求仍要另查。编译器和 Windows SDK 按本机发现结果配置，不硬编码案例的 VS 版本。

将 EXE 放进暂存包，在复制出的测试目录运行 GenerateDAT.exe --silent，核对退出码、DAT 内容、旧文件备份、重复执行、缺文件拒绝和 DLL 未改变。

模板支持完整 ASCII 路径（含空格），上限 200 字符；非 ASCII 路径会明确拒绝。这是本模板的已验证范围，不是对 Creo 全部路径能力的判断。

脚本会重新写入暂存目录的 protk.dat；不要用用户安装目录作为 --stage。用户目录安全替换由生成的 EXE 负责。

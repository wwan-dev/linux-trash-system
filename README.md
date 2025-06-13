# 回收站系统 (Trash System)

一个安全的rm命令替代方案，将文件移动到回收站而不是永久删除。

## 📁 文件列表

- `trash` - 主要的回收站脚本，用于安全删除文件
- `trash-list` - 查看回收站内容的工具
- `trash-restore` - 恢复已删除文件的工具
- `trash-empty` - 清空回收站的工具
- `install-trash-system.sh` - 自动安装脚本，配置rm命令使用回收站

## 🚀 快速开始

### 安装

```bash
cd trash-system
./install-trash-system.sh
source ~/.bashrc  # 重新加载配置
```

### 基本使用

```bash
# 删除文件（移到回收站）
rm file.txt
rm -r folder/

# 查看回收站
trash-list

# 恢复文件
trash-restore file.txt

# 清空回收站
trash-empty
```

## 🎯 主要特性

- ✅ **安全删除**：文件移到回收站而不是永久删除
- ✅ **完全兼容**：支持rm命令的所有常用选项
- ✅ **智能识别**：自动识别系统文件，避免破坏系统
- ✅ **交互式恢复**：支持选择性恢复文件
- ✅ **自动清理**：支持按时间清理旧文件
- ✅ **详细信息**：记录删除时间和原始路径

## 📋 命令详情

### trash
主要的删除命令，替代rm功能。

```bash
trash [选项] <文件或目录>

选项:
  -h, --help      显示帮助信息
  -f, --force     强制删除，不询问确认
  -r, --recursive 递归删除目录
  -v, --verbose   显示详细信息
```

### trash-list
查看回收站内容。

```bash
trash-list [选项]

选项:
  -h, --help     显示帮助信息
  -l, --long     显示详细信息
  -s, --size     显示文件大小
  -t, --time     按删除时间排序
```

### trash-restore
恢复已删除的文件。

```bash
trash-restore [选项] [文件名]

选项:
  -h, --help        显示帮助信息
  -i, --interactive 交互式选择要恢复的文件
  -a, --all         恢复所有文件
  -f, --force       强制恢复，覆盖已存在的文件
```

### trash-empty
清空回收站。

```bash
trash-empty [选项]

选项:
  -h, --help     显示帮助信息
  -f, --force    强制清空，不询问确认
  -d, --days N   删除N天前的文件
```

## 🛡️ 安全特性

- **确认提示**：默认删除前会询问确认
- **重名保护**：自动处理同名文件冲突
- **系统保护**：自动识别系统临时文件使用真正的rm
- **配置备份**：安装时会备份原配置文件
- **真实删除**：提供`rm --real-rm`选项进行永久删除

## 📂 回收站结构

```
~/.trash/
├── files/     # 存储被删除的文件
└── info/      # 存储文件信息（原始路径、删除时间等）
```

## 🔧 高级用法

### 真正删除文件
如果需要永久删除文件（绕过回收站）：
```bash
rm --real-rm file.txt
```

### 批量恢复
交互式选择多个文件恢复：
```bash
trash-restore -i
```

### 定期清理
删除7天前的回收站文件：
```bash
trash-empty -d 7
```

## 🗂️ 卸载

### 自动卸载（推荐）

使用提供的卸载脚本：

```bash
cd trash-system
./uninstall-trash-system.sh
```

卸载选项：
- `./uninstall-trash-system.sh` - 交互式卸载
- `./uninstall-trash-system.sh -f` - 强制卸载，不询问确认
- `./uninstall-trash-system.sh -k` - 卸载但保留回收站内容
- `./uninstall-trash-system.sh -c` - 完全清理所有相关文件

### 手动卸载

如果无法使用卸载脚本：

1. 删除安装的脚本：
```bash
rm -rf ~/.local/bin/{trash,trash-list,trash-restore,trash-empty,rm}
```

2. 从shell配置文件中删除相关配置（在`~/.bashrc`或`~/.zshrc`中）

3. 清理回收站（可选）：
```bash
rm -rf ~/.trash
```

## 📄 许可证

MIT License - 自由使用和修改

## 🐛 问题反馈

如遇到问题，请检查：
1. 脚本是否有执行权限
2. PATH是否正确配置
3. 回收站目录是否可写

---

**注意**：此系统仅替代用户层面的rm命令，不影响系统级操作。 
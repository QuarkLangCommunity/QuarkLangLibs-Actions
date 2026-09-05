# QuarkLangLibs-System

**QuarkLang 官方库（system）——系统进程执行能力，官方认证。**

本仓库是 QuarkLang 官方项目生态的一部分：`system.qk` 是官方认证的
`sytem` 库源码，包装 QuarkLang 运行时原生提供的进程执行原语，
并提供官方语义背书。

## 使用方法

把 `system.qk` 放在与你的源码同目录，然后：

```qk
import "system";

fn main(io IOStream) {
    // 执行 shell 命令，返回退出码（0 表示成功）
    code int = exec("mkdir -p /tmp/out");
    io.println(code);

    // 不经 shell 的 argv 形态（无注入面）
    code2 int = execv("echo", ["hello", "world"]);
    io.println(code2);

    // 捕获命令输出（内部 8 MiB 上限）
    s InputStream = popen("printf 'hello from pipe'");
    io.println(s.readln());
}
```

## API

| 函数 | 签名 | 说明 |
|---|---|---|
| `exec` | `(cmd String) int` | `sh -c cmd`；返回退出码（0=成功） |
| `execv` | `(prog String, args List<String>) int` | argv 直传，**不经过 shell**；返回退出码 |
| `popen` | `(cmd String) InputStream` | 捕获 stdout 为输入流；输出超过 8 MiB 报错 |

## 认证信息

- 库名：`system`（`import "system"`）
- 语言版本：QuarkLang v0.2（`fn`/`struct`/`impl`/泛型体系）
- 运行时版本：见 QuarkLang 主仓库 `compiler/main.go` 的 `engineVersion`
- 认证方：QuarkLang 官方项目

> 说明：官方库的作用是**认证**——给出官方认可的使用形态与语义。
> 实现原语（`qkexec` 等）在 QuarkLang 运行时内部，本仓库不含运行时实现。

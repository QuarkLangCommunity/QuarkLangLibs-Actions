# QuarkLangLibs-Actions

**QuarkLang 官方库（actions）——进程/网络执行动作，官方认证，两级结构。**

本仓库是 QuarkLang 官方项目生态的一部分：`actions.qk` 是官方认证的
`actions` 库源码，包装 QuarkLang 运行时原生原语，提供官方语义背书。

## 两级结构

**第一级：系统级普通函数（space 空间）** —— `space { ... } (space名);` 定义，
以 `空间名::函数(...)` 静态调用：

| 空间 | 函数 | 说明 |
|---|---|---|
| `system` | `exec(cmd String) int` | `sh -c cmd`；返回退出码（0=成功） |
| `system` | `execv(prog String, args List<String>) int` | argv 直传，**不经过 shell** |
| `system` | `popen(cmd String) InputStream` | 捕获 stdout；8 MiB 上限 |
| `network` | `get(url String) String` | HTTP GET；10s 超时；8 MiB 上限；非 2xx 报错 |
| `network` | `post(url String, body String, contentType String) String` | HTTP POST |

**第二级：包装层（struct 类实现 Executor 接口）** —— 方法带 `self`（`self Self` 真实签名）：

```qk
interface {
    fn exec(self Self, cmd String) int;
} Executor;
```

- `Command` 类：`.exec(cmd)` 执行命令并记录退出码（`.lastCode()`）
- `Network` 类：`.exec(url)` 执行网络命令（GET，失败抛错、成功 0）；`.get(url)` / `.post(url, body, contentType)`

## 使用方法

把 `actions.qk` 放在与你的源码同目录，然后：

```qk
import "actions";

fn main(io IOStream) {
    // 第一级：space 普通函数
    code int = system::exec("mkdir -p /tmp/out");
    io.println(code);
    s String = network::get("https://example.com/api");
    io.println(s);

    // 第二级：包装类（Executor 接口）—— 链式与变量式均可
    Command::new("echo", ["hello"]).exec();          // 链式
    c Command = Command::new("echo", ["world"]);     // 变量式
    c.exec();

    Network::new("http://127.0.0.1:8000/").exec();   // 链式
    n Network = Network::new("http://127.0.0.1:8000/");
    n.exec();
    io.println(n.get("http://127.0.0.1:8000/"));     // GET 响应体（实例方法）
}
```

## 安全约束（运行时强制）

- `exec`/`popen` 经 shell 执行（`sh -c`）；防注入用 `execv`（argv 直传）
- `popen` 输出 ≤ 8 MiB；`network::get/post` 超时 10s、响应 ≤ 8 MiB、非 2xx 报 `HTTPError`

## 认证信息

- 库名：`actions`（`import "actions"`）
- 语言版本：QuarkLang v0.2（`fn`/`struct`/`impl`/泛型/`space`/接口体系）
- 运行时版本：见 QuarkLang 主仓库 `compiler/main.go` 的 `engineVersion`
- 认证方：QuarkLang 官方项目

> 官方库=认证（官方认可的使用形态与语义）；实现原语（`qkexec`/`qkhttp_*` 等）在 QuarkLang 运行时内部。

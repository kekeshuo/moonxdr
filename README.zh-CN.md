# MoonXDR 中文使用说明

[English](README.md) · [RFC 4506 条款与测试对照](docs/rfc4506-coverage.md)

`kekeshuo/moonxdr@0.2.0` 是 MIT 许可的纯 MoonBit XDR 声明解析、类型化编解码和 ONC RPCv2 线格式工具库，只依赖官方 MoonBit core。

## 用途与完成目标

面向协议/数据生产者、遗留协议集成工具作者、测试夹具与数据交换作者：输入 `.x` 声明、类型化值或二进制，得到经过边界校验的类型图、网络字节、结构化值或项目约定的 JSON。项目不是 NFS 专用读取器，也不是完整 RPC 客户端/服务器。

**项目终点是覆盖 RFC 4506 全部已定义数据类型与声明规则，而不是永久停留在子集。** 0.2.0 补齐 quadruple、无符号联合判别值和完整 uint32 声明上界。条款矩阵逐项链接实现及测试；若发现其他标准差异，将作为缺陷修复，不把标准内功能列为永久排除项。已有测试覆盖不等于第三方标准认证或赛事审核通过。

## 环境与安装

固定开发编译器：官方 `v0.10.14+7d59c7ec9`。CI 覆盖 wasm-gc、wasm、js、native；Windows 本地执行前三种，native 由 Linux CI 实际执行。

```sh
moon add kekeshuo/moonxdr@0.2.0
```

在包的 `moon.pkg` 中导入 `"kekeshuo/moonxdr" @xdr`。调用者需要允许 `raise` 或捕获 `XdrError::Invalid(位置, 原因)`。

## 可运行快速开始

```moonbit
let schema = @xdr.parse_schema(
  "typedef quadruple Q; union Measurement switch(unsigned int tag) { case 4294967295: Q reading; default: void; };",
)
let q = @xdr.Quadruple::from_hex("3fff0000000000000000000000000000")
let value = @xdr.VUnion(4294967295L, @xdr.VQuadruple(q))
let wire = @xdr.encode(schema, "Measurement", value)
assert_eq(@xdr.to_hex(wire), "ffffffff3fff0000000000000000000000000000")
assert_true(@xdr.encode(schema, "Measurement", @xdr.decode(schema, "Measurement", wire)) == wire)
```

以上代码对应 `examples/standard`，验证四倍精度数值 1.0 与正数字面量 `4294967295` 的联合，包括精确预期字节、解码和 JSON 往返，不用 `-1` 冒充无符号最大值。

```sh
moon run examples/schema --deny-warn
moon run examples/rpc --deny-warn
moon run examples/interchange --deny-warn
moon run examples/standard --deny-warn
```

四个闭环分别是：传感记录声明与数据往返；过程参数附加 RPC/AUTH_SYS、分片、逐字节重组及响应解码；精确 64 位整数/opaque/可选值的 JSON 交换；binary128 与 UINT32_MAX 联合的标准边界验证。全部示例带断言。

## 已实现能力与 API

- `parse_schema`：const、typedef、命名/内联 enum/struct/union、先前声明常量、递归可选数据及类型图验证。常量使用 BigInt 精确保留十进制、八进制、十六进制数，在用途处检查实际类型范围。
- `Reader` / `Writer`：网络字节序的 int/uint、hyper/uhyper、bool、float、double、quadruple，ASCII string、opaque 与零填充校验。
- `encode` / `decode`：结构、数组、联合、void、指针和类型别名，校验字段顺序、枚举成员、分支域及完整输入消费。
- `Quadruple`：两个 UInt64 保存符号位、15 位指数和 112 位小数，支持分类、十六进制和无损字节转换；正负零、次正规数、无穷、NaN 载荷均保留。`from_double` 精确扩展 binary64，不把 Double 当四倍精度存储。不声称提供四倍精度算术或十进制舍入库；XDR 规定的是数据表示与交换。
- `from_json` / `to_json`、精确 decimal64 与 hex 工具；`RpcCall` / `RpcReply` / `AuthSys` / `RecordDecoder` 提供传输无关的线格式组合。完整签名见 `pkg.generated.mbti`。

## 类型范围及 JSON 约定

int、enum 为有符号 32 位；uint 判别值与声明长度覆盖 `0..4294967295`。`case 4294967295:` 可直接用于 uint 联合，`case -1:` 不被视为其别名。省略上界 `<>` 表示协议上界 `4294967295U`，不表示运行时分配这么多内存。

JSON 是项目约定，不是 RFC 的 JSON 标准：int/uint/enum 为整数数字（enum 也可输入名字），hyper/uhyper 为精确十进制字符串，quadruple 为网络序 32 位十六进制数字符串，opaque 为偶数长度 hex，struct/array 为对象/数组，void 为 null，可选值为 null 或 `{"some": 值}`，联合为 `{"tag": 数字, "value": 值}`。整数词法拒绝 `1.0`、`1e0` 等形式以避免底层转换截断。float/double JSON 只支持有限数；需保留 NaN 载荷和负零时使用二进制 API。结构 Value 按声明顺序使用字段名和值的数组。

## 已知限制与非目标

默认每次操作限制 1 MiB 字节、65536 个值节点/令牌、深度 64；可配置上限分别为 64 MiB、1048576、128。单个常量字面量限制 4096 字符，不是 signed32/signed64 数值限制。类型图分析有令牌数四倍的工作预算。这些操作限制可能拒绝标准合法但过大的输入；不改变声明本身的类型范围，不把它们判为标准非法。

便利扩展包括 `//` 注释、`0X`、负十六/八进制、常量别名和前向类型引用。C 预处理、算术表达式、rpcgen 服务代码生成与 RPC program 语法不属于 RFC 4506 的要求。完整 RPC 服务、socket、rpcbind、NFS、重传、身份认证和 RPCSEC_GSS 另属协议/应用层功能。AUTH_SYS 只是未经信任的身份声明，不能当成认证。类型和值的数组使用期间不得并发修改；RecordDecoder 出错后须丢弃，调用者负责连接超时。详见 `SECURITY.md`。

## 检查与测试

```sh
moon info && moon fmt
moon fmt --check
moon check --deny-warn
moon build --deny-warn
moon test --deny-warn
python scripts/reference_vectors.py --check
python scripts/reference128.py --check
python scripts/audit.py
```

46 个测试包含 64 个独立 Python struct 向量（384 个标量字段）、176 个 binary128 网络字节向量、140 个有理数 oracle 的 binary64 精确扩展向量、RFC 第 7 节样例字节，以及长度/溢出/填充/递归/分片错误测试。随机数据固定种子、可再生成，测试与生成数据不计入生产代码行数。未给出性能或外部标准认证结论。

0.2.0 的兼容变更：声明上界改为 UInt，常量查询返回 BigInt，联合标签及 VUnion 判别值改为 Int64（明确写标签时使用 `L` 后缀）。旧 `parse_constant_number` 仅保留为 signed32 兼容入口，新解析使用 `parse_integer_constant`。旧发布版本不覆盖。

## 许可、参考与 AI 披露

原创实现，非移植。标准参考 RFC 4506/5531；行为参考 CPython xdrlib（PSF）和 go-xdr（ISC），未打包其实现或测试；官方 core 依赖为 Apache-2.0。新增 oracle 为本项目独立 MIT 代码，详见 [ATTRIBUTION.md](ATTRIBUTION.md)。设计、代码、测试、文档及交付使用 AI 辅助，详见 [AI-USE.md](AI-USE.md)。查重范围及近邻差异见 [查重记录](docs/competition/duplicate-check.md)，不作绝对唯一或赛事通过保证。

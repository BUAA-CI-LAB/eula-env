# EuLA Env
## 介绍
该项目致力于构建 LoongArch 32 Reduced 集成芯片敏捷开发平台

目录接口

* `am/`: 基于南京大学 AM 移植的 LoongArch 32 Reduced 裸机运行时环境

> 原仓库地址: https://github.com/NJU-ProjectN/abstract-machine.git

* `eulacore`: 基于敏捷开发平台设计实现的九级顺序单发射处理器与 Verilator 仿真 SoC

* `la32r-toolchains`: LoongArch 32 Reduced GNU 工具链和 newlib 链接库

* `nemu`: 基于南京大学 NEMU 移植的 LoongArch 32 Reduced 仿真模拟器

> 原仓库地址: https://gitee.com/wwt_panache/la32r-nemu.git

* `env.sh`: 环境变量加载脚本，需在编译程序前使用

* `setup-tools.sh`: 依赖库/工具安装脚本

* `setup.sh`: 一键配置脚本, 包含 env.sh 的功能, 初始化仓库子模块，并自动编译 nemu 与 am 中的 coremark 程序

## How It Works

> 写在前面，加载环境变量/编译 NEMU/编译 AM 的步骤可通过 `setup.sh` 脚本一键完成，其中默认编译 coremark 程序: 

```bash
$ source setup.sh
```

以下具体介绍每步操作方法。

### 加载环境变量

```bash
$ source env.sh
```

### 编译行为仿真模型

针对 CPU 设计的早期阶段，该项目设计了一套简易的 Verialtor 仿真 SoC，CPU 对外统一为一个 AXI4 接口，并通过 AXI4 转接桥连接 RAM 和 UART8250，CPU具体定义如下图所示：

```verilog
module mycpu_mega_top(
  input         clock,
  input         reset,
  input         awready,
  output        awvalid,
  output [31:0] awaddr,
  output [2:0]  awprot,
  output        awid,
  output        awuser,
  output [7:0]  awlen,
  output [2:0]  awsize,
  output [1:0]  awburst,
  output        awlock,
  output [3:0]  awcache,
  output [3:0]  awqos,
  input         wready,
  output        wvalid,
  output [31:0] wdata,
  output [3:0]  wstrb,
  output        wlast,
  output        bready,
  input         bvalid,
  input  [1:0]  bresp,
  input         bid,
  input         buser,
  input         arready,
  output        arvalid,
  output [31:0] araddr,
  output [2:0]  arprot,
  output        arid,
  output        aruser,
  output [7:0]  arlen,
  output [2:0]  arsize,
  output [1:0]  arburst,
  output        arlock,
  output [3:0]  arcache,
  output [3:0]  arqos,
  output        rready,
  input         rvalid,
  input  [1:0]  rresp,
  input  [31:0] rdata,
  input         rlast,
  input         rid,
  input         ruser,
  input  [7:0]  ext_int,
  output        global_reset
);
```

 为使得 CPU 接入该项目的 SoC，首先需要通过如下命令编译 SoC 仿真顶层模块，生成 SimTop.v 文件:
 
 ```bash
 $ make verilog
 ```

 可以看到 SimTop.v 中包含了该项目的 SoC 顶层并实例化了 CPU 模块:

 ```verilog
 mycpu_mega_top core ( // @[EulaSimTop.scala 27:20]
    .awready(core_awready),
    .awvalid(core_awvalid),
    ...
    .rready(core_rready),
    .rvalid(core_rvalid),
    .rresp(core_rresp),
    .rdata(core_rdata),
    .rlast(core_rlast),
    .rid(core_rid),
    .ruser(core_ruser),
    .ext_int(core_ext_int),
    .clock(core_clock),
    .reset(core_reset),
    .global_reset(core_global_reset)
  );
 ```

然而，SimTop.v 中并没有对应 CPU 的实现部分，这部分需要使用者进行添加：将 CPU 顶层命名为 `mycpu_mega_top`, 并使其对外为一个 AXI 4 接口，具体接口定义如前面所示。假设 CPU 顶层模块文件名为 core.v (例如文件路径为 eula-env/eulacore/core.v，其中需要哦包含 CPU 顶层模块 `mycpu_mega_top`)，最后在 SimTop.v 第一行引入 core.v 文件的路径

```verilog
`include "../core.v" // 使用者根据自身 CPU 顶层模块文件路径添加

module AXI4RAM(
  input         clock,
  input         reset,
  ...
);
```

完成上述步骤后，在 eula-env/eulacore 目录输入: 

```bash
$ make emu EMU_TRACE=1 # 若不需要导出波形，可以不添加 EMU_TRACE=1 参数
```

即可将 SimTop.v 与使用者的 CPU 共同编译为 C++ 行为模型，编译产物为 eula-env/eulacore/build/emu。


### 编译 NEMU

```bash
$ cd ${NEMU_HOME}
$ make la32-reduced-ref_defconfig
make -j
```

### 编译 AM

以 coremark 程序为例

```bash
$ cd ${AM_HOME}/apps/coremark
$ make ARCH=la32r-eula
```

### 运行仿真测试

```bash
$ cd ${PROJECT_ROOT}/eulacore/build
$ ./emu -i ${AM_HOME}/apps/coremark/build/coremark-la32r-eula.bin

# 如需导出波形，可添加 --dump-wave --wave-path="<your wave path>" 参数，注意前提是在编译 emu 的时候已经添加了 EMU_TRACE=1 参数
# 如需控制导出波形的周期，可添加 -b <begin cycle> -e <env cycle> 参数
```

### 查看波形

```bash
$ gtkwave "<your wave path>"
```


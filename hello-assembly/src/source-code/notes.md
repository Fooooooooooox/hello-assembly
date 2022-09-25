# 如何使用汇编 让调用合约返回的结果和合约code一样？

如果没有ctf的限制的话这其实是一个非常简单的事情。
callcode delegate call等都可以做到
## 知识补充1：delegate call和callcode的区别？

实际上，可以认为DELEGATECALL是CALLCODE的一个bugfix版本，官方已经不建议使用CALLCODE了。

CALLCODE和DELEGATECALL的区别在于：`msg.sender`不同。

具体来说，DELEGATECALL会一直使用原始调用者的地址，而CALLCODE不会。

所以用了delegate call的话就可以知道到底是谁在调用这个合约函数 。

但是ctf不让你用这些opcode，他会遍历你传入的code的每一个opcode，如果有黑名单内的opcode就返回false

## 知识补充2: staticCall是什么？
如果调用的时候用的是staticCall，那你的交易是不会改变区块链的状态的。所以经常被用于测试。


https://mp.weixin.qq.com/s?__biz=Mzg4MDcxNTc2NA==&mid=2247483849&idx=1&sn=d7ec401904280026ff8bcd361705422b&chksm=cf71b352f8063a441f0bcc0b8dba8b3a88284b44e5f0a3bd7c437f0d4c596350e407063f3c34&scene=178&cur_album_id=2556040001080557569#rd

第一行的code是怎么设计的呢？

第一行可以对照opcode表翻译一下 你就会发现他和整个code指令是一样的

调用合约之后返回的结果就是绿框框的内容 这个内容和合约code是一样的（实现了调用合约返回的结果和合约的code一样


# 知识补充3: fallback function

fallback在abi里是这样的：
```go
type ABI struct {
	Constructor Method
	Methods     map[string]Method
	Events      map[string]Event
	Errors      map[string]Error

	// Additional "special" functions introduced in solidity v0.6.0.
	// It's separated from the original default fallback. Each contract
	// can only define one fallback and receive function.
	Fallback Method // Note it's also used to represent legacy fallback before v0.6.0
	Receive  Method
}
```
找个例子看看？
我写了一个例子，在testfallback里，编译后生成的abi在output里。

这个合约定义了一个fallback函数，可以看到在abi找到：
```json
    {
      "stateMutability": "payable",
      "type": "fallback"
    },
```
也可以找到constructor：

```json
{
      "inputs": [],
      "stateMutability": "nonpayable",
      "type": "constructor"
    },
```

那如果直接写opcode转换成bytecode部署呢？
那就不会存在abi了，对于evm来说abi是没有用的，abi为了方便客户端外部调用。

# 知识补充4:quine
Quine，指的是输出结果为自身源码的程序。(能够直接读取自己源码、读入用户输入或空白的程序，一般不视为Quine)
- python版本quine代码
    
    ```python
    # 1
    r='r=%r;print(r%%r,)';print(r%r,)
    
    ```
    
- evm quine V1
    
    ```python
    codesize
    push1 00
    push1 0x40
    codecopy
    codesize
    push1 0x40
    return
    ```
    
- evm quine V2
    
    ```python
    # quine.etk
    # ⬜ => ⬜
    # A quine is a computer program which takes no input and produces a copy of its own source code as its only output.
    
    # 0x80...f3 is the compiled code excluding the push16 instruction (from dup1 to return)
    push16 0x8060801b17606f5953600152602136f3
    
                        # --- stack ---
    dup1                # code code
    push1 128           # 128 code code
    shl                 # code0000 code
    or                  # codecode
    
    # (6f is push16)
    push1 0x6f          # 6f codecode
    msize               # offset=0 6f codecode
    mstore8             # codecode
                        # mem = [6f]
    
    push1 1             # 1 codecode
    mstore              # mem = [6fcodecode]
    
    push1 33            # size
    **calldatasize**        # offset=0 size 
                        # (by definition, a quine takes no input so calldatasize is 0)
    return              # out = [6fcodecode]
    
    # $ eas quine.etk
    # 6f8060801b17606f5953600152602136f38060801b17606f5953600152602136f3
    #
    # $ evm --code $(eas quine.etk) run | cut -dx -f2
    # 6f8060801b17606f5953600152602136f38060801b17606f5953600152602136f3
    ```

## 知识补充5：
evm如何执行交易？

如果是一笔普通的转账交易，直接修改StateDB中对应的账户余额。

如果是合约交易，会调用解释器（interpreter）来查询/修改StateDB。

gas：

gas = intrinsic gas（21000的油费） + calldata的gas fee（字节为0的收4块，字节不为0收68块）

调用合约函数：

客户端可以用abi来生成input data（calldata）

inputdata的结构：

4-byte signature(函数签名的Keccak哈希值的前4个字节） + arguments(value调用函数时传入的参数)

调用过程：

CALLDATALOAD将4-byte signature压入栈，和合约bytecode一一对比，如果匹配的话就调用jump指令跳入该段代码继续执行。

来举个例子看看好了：
https://xz.aliyun.com/t/8655
例子：
hello-assembly/src/tee.sol

forge build之后可以在output中找到合约的bytecode

将bytecode转换为opcode：https://ethervm.io/decompile

这里的bytecode应该是合约的runtime（下次看看合约部署的过程：

图中creation是创建合约，主要执行constructor函数、返回合约的runtime、payable检查。不同合约部署的时候会生成不一样的constructor）

得到的结果：

合约的runtime包含：selector、wrapper、function body 和metadata hash

```c++
contract Contract {
    function main() {
        memory[0x40:0x60] = 0x80;
        var var0 = msg.value;

        // 这个对应的是
        if (var0) { revert(memory[0x00:0x00]); }
    
        memory[0x00:0x0156] = code[0x20:0x0176];
        return memory[0x00:0x0156];
    }
}
```

```c++
label_0000:
	// Inputs[1] { @0005  msg.value }
	0000    60  PUSH1 0x80 //（将0x80压入栈顶）
	0002    60  PUSH1 0x40 //（将0x40压入栈顶）
	0004    52  MSTORE //（把0x80存放在内存0x40处）现在栈是空的了
    // 上面这三条一般被叫做free memory pointer
	0005    34  CALLVALUE // callvalue会拿到mag.value存入栈顶
	0006    80  DUP1 // dup 1复制一个到栈顶
	0007    15  ISZERO // 判断栈顶是不是0（如果calldata不是空那就是1，如果calldata为空就为0） 所以这个是用来判断传入的calldata是不是空
	0008    61  PUSH2 0x0010 //现在的栈： 0x0010, calldata == 0(bool值表示calldata是不是空的)，calldata
	000B    57  *JUMPI //jumpi是跳转指令 表示从栈中依次出栈两个值destination	condition 如果condition的值为真则跳转到arg0处，否则不跳转
    // 如果calldata为空：栈：0x0010, 0, calldata ==》 不跳转
    // 如果calldata不为空：栈：0x0010, 1, calldata ==》 跳转到label0x0010
	// Stack delta = +1
	// Outputs[2]
	// {
	//     @0004  memory[0x40:0x60] = 0x80
	//     @0005  stack[0] = msg.value
	// }
	// Block ends with conditional jump to 0x0010, if !msg.value

// 如果不跳转就继续：
// 没有符合的，revert
label_000C:
	// Incoming jump from 0x000B, if not !msg.value
	// Inputs[1] { @000F  memory[0x00:0x00] }
	000C    60  PUSH1 0x00
	000E    80  DUP1
	000F    FD  *REVERT // REVERT接收两个参数：offset	length	
    // 返回memory从offset开始长度为length的内容 这个功能是Byzantium硬分叉之后具有的，revert的时候可以返回一条信息
	// Stack delta = +0
	// Outputs[1] { @000F  revert(memory[0x00:0x00]); }
	// Block terminates

label_0010:
    // 跳转到这（栈：calldata）
    // 内存是0x40：0x80
	// Incoming jump from 0x000B, if !msg.value
	// Inputs[1] { @001E  memory[0x00:0x0156] }
	0010    5B  JUMPDEST
	0011    50  POP // 把栈顶的元素去掉
	0012    61  PUSH2 0x0156 
	0015    80  DUP1
	0016    61  PUSH2 0x0020
	0019    60  PUSH1 0x00 // 栈：0x00 0x0020 0x0156 0x0156 
	001B    39  CODECOPY //复制当前的code到内存 用了三个参数：destOffset	offset	length	
    // 结果得到：memory[destOffset:destOffset+length] = address(this).code[offset:offset+length]
    // 第三个参数是code的长度
    // 第一个是栈的起始位置
    // 第二个是code里目标函数的起始位置
	001C    60  PUSH1 0x00 // 现在栈里面有两个东西：0x00，0x0156
	001E    F3  *RETURN // return接收两个参数：offset length，	return memory[offset:offset+length]，从offset的位置开始返回内从中长度为length的内容 所以这里是返回了code
    // 这里就是selector：
	// Stack delta = -1
	// Outputs[2]
	// {
	//     @001B  memory[0x00:0x0156] = code[0x20:0x0176]
	//     @001E  return memory[0x00:0x0156];
	// }
	// Block terminates

	001F    FE    *ASSERT
	0020    60    PUSH1 0x80
	0022    60    PUSH1 0x40
	0024    52    MSTORE
	0025    34    CALLVALUE 
	0026    80    DUP1
	0027    15    ISZERO
	0028    61    PUSH2 0x0010
	002B    57    *JUMPI
	002C    60    PUSH1 0x00
	002E    80    DUP1
	002F    FD    *REVERT
	0030    5B    JUMPDEST
	0031    50    POP
	0032    60    PUSH1 0x04
	0034    36    CALLDATASIZE
	0035    10    LT
	0036    61    PUSH2 0x0036
	0039    57    *JUMPI
	003A    60    PUSH1 0x00
	003C    35    CALLDATALOAD
	003D    60    PUSH1 0xe0
	003F    1C    SHR
	0040    80    DUP1
	0041    63    PUSH4 0x0dbe671f
	0046    14    EQ
	0047    61    PUSH2 0x003b
	004A    57    *JUMPI
	004B    80    DUP1
	004C    63    PUSH4 0x4df7e3d0
	0051    14    EQ
	0052    61    PUSH2 0x0055
	0055    57    *JUMPI
	0056    5B    JUMPDEST
	0057    60    PUSH1 0x00
	0059    80    DUP1
	005A    FD    *REVERT
	005B    5B    JUMPDEST
	005C    61    PUSH2 0x0043
	005F    61    PUSH2 0x005f
	0062    56    *JUMP
	0063    5B    JUMPDEST
	0064    60    PUSH1 0x40
	0066    51    MLOAD
	0067    90    SWAP1
	0068    81    DUP2
	0069    52    MSTORE
	006A    60    PUSH1 0x20
	006C    01    ADD
	006D    60    PUSH1 0x40
	006F    51    MLOAD
	0070    80    DUP1
	0071    91    SWAP2
	0072    03    SUB
	0073    90    SWAP1
	0074    F3    *RETURN
	0075    5B    JUMPDEST
	0076    61    PUSH2 0x005d
	0079    61    PUSH2 0x0070
	007C    56    *JUMP
	007D    5B    JUMPDEST
	007E    00    *STOP
	007F    5B    JUMPDEST
	0080    60    PUSH1 0x00
	0082    61    PUSH2 0x006b
	0085    60    PUSH1 0x02
	0087    61    PUSH2 0x0086
	008A    56    *JUMP
	008B    5B    JUMPDEST
	008C    90    SWAP1
	008D    50    POP
	008E    90    SWAP1
	008F    56    *JUMP
	0090    5B    JUMPDEST
	0091    60    PUSH1 0x00
	0093    80    DUP1
	0094    54    SLOAD
	0095    90    SWAP1
	0096    80    DUP1
	0097    61    PUSH2 0x007f
	009A    83    DUP4
	009B    61    PUSH2 0x00d1
	009E    56    *JUMP
	009F    5B    JUMPDEST
	00A0    91    SWAP2
	00A1    90    SWAP1
	00A2    50    POP
	00A3    55    SSTORE
	00A4    50    POP
	00A5    56    *JUMP
	00A6    5B    JUMPDEST
	00A7    60    PUSH1 0x00
	00A9    60    PUSH1 0x01
	00AB    82    DUP3
	00AC    11    GT
	00AD    61    PUSH2 0x0098
	00B0    57    *JUMPI
	00B1    50    POP
	00B2    60    PUSH1 0x01
	00B4    91    SWAP2
	00B5    90    SWAP1
	00B6    50    POP
	00B7    56    *JUMP
	00B8    5B    JUMPDEST
	00B9    61    PUSH2 0x00ab
	00BC    61    PUSH2 0x00a6
	00BF    60    PUSH1 0x01
	00C1    84    DUP5
	00C2    61    PUSH2 0x00ea
	00C5    56    *JUMP
	00C6    5B    JUMPDEST
	00C7    61    PUSH2 0x0086
	00CA    56    *JUMP
	00CB    5B    JUMPDEST
	00CC    61    PUSH2 0x00b5
	00CF    90    SWAP1
	00D0    83    DUP4
	00D1    61    PUSH2 0x0101
	00D4    56    *JUMP
	00D5    5B    JUMPDEST
	00D6    92    SWAP3
	00D7    91    SWAP2
	00D8    50    POP
	00D9    50    POP
	00DA    56    *JUMP
	00DB    5B    JUMPDEST
	00DC    63    PUSH4 0x4e487b71
	00E1    60    PUSH1 0xe0
	00E3    1B    SHL
	00E4    60    PUSH1 0x00
	00E6    52    MSTORE
	00E7    60    PUSH1 0x11
	00E9    60    PUSH1 0x04
	00EB    52    MSTORE
	00EC    60    PUSH1 0x24
	00EE    60    PUSH1 0x00
	00F0    FD    *REVERT
	00F1    5B    JUMPDEST
	00F2    60    PUSH1 0x00
	00F4    60    PUSH1 0x01
	00F6    82    DUP3
	00F7    01    ADD
	00F8    61    PUSH2 0x00e3
	00FB    57    *JUMPI
	00FC    61    PUSH2 0x00e3
	00FF    61    PUSH2 0x00bb
	0102    56    *JUMP
	0103    5B    JUMPDEST
	0104    50    POP
	0105    60    PUSH1 0x01
	0107    01    ADD
	0108    90    SWAP1
	0109    56    *JUMP
	010A    5B    JUMPDEST
	010B    60    PUSH1 0x00
	010D    82    DUP3
	010E    82    DUP3
	010F    10    LT
	0110    15    ISZERO
	0111    61    PUSH2 0x00fc
	0114    57    *JUMPI
	0115    61    PUSH2 0x00fc
	0118    61    PUSH2 0x00bb
	011B    56    *JUMP
	011C    5B    JUMPDEST
	011D    50    POP
	011E    03    SUB
	011F    90    SWAP1
	0120    56    *JUMP
	0121    5B    JUMPDEST
	0122    60    PUSH1 0x00
	0124    81    DUP2
	0125    60    PUSH1 0x00
	0127    19    NOT
	0128    04    DIV
	0129    83    DUP4
	012A    11    GT
	012B    82    DUP3
	012C    15    ISZERO
	012D    15    ISZERO
	012E    16    AND
	012F    15    ISZERO
	0130    61    PUSH2 0x011b
	0133    57    *JUMPI
	0134    61    PUSH2 0x011b
	0137    61    PUSH2 0x00bb
	013A    56    *JUMP
	013B    5B    JUMPDEST
	013C    50    POP
	013D    02    MUL
	013E    90    SWAP1
	013F    56    *JUMP
	0140    FE    *ASSERT
	0141    A2    LOG2
	0142    64    PUSH5 0x6970667358
	0148    22    22
	0149    12    SLT
	014A    20    SHA3
	014B    7F    PUSH32 0xf0022e73537bd40c24ff86858fdb98a5b554c4136f1658d4c4b100bd3527f164
	016C    73    PUSH20 0x6f6c634300080f0033
```







# 工具推荐：
查询opcode：
https://ethervm.io/

运行opcode：
https://www.evm.codes/playground

bytecode to opcode：
https://etherscan.io/opcode-tool

查询opcode和其他技术规范：
https://ethereum.github.io/yellowpaper/paper.pdf

ida：
是什么？

Writing a disassembler is a tedious task. You have to decode the opcode, interpret the meaning of the operands and, finally, print the instruction correctly. Fortunately, you can count on IDA to provide modules with mapping executable, a colorful GUI, control flow graphs and so on.

如何使用？
我发现ida作者写了很多的博客关于如何使用：
https://hex-rays.com/blog/ 

关于如何增加module可以看这篇：https://www.hex-rays.com/products/ida/support/idadoc/536.shtml
我们要加的module：https://github.com/crytic/ida-evm

首先安装ida pro
https://hex-rays.com/ida-free/

如何增加plugin module？

可以看这个：The IDA Way
https://sark.readthedocs.io/en/latest/plugins/installation.html

先装一个官方的sample module：highligther：
目录：
```shell
cd $HOME/.idapro
mkdir plugins
mv /Users/foooox/Downloads/highlighter/ .
```
重启ida
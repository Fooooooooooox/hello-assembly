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


# 工具推荐：
查询opcode：
https://ethervm.io/

运行opcode：
https://www.evm.codes/playground

bytecode to opcode：
https://etherscan.io/opcode-tool
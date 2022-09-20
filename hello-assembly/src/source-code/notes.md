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


https://mp.weixin.qq.com/s?__biz=Mzg4MDcxNTc2NA==&mid=2247483849&idx=1&sn=d7ec401904280026ff8bcd361705422b&chksm=cf71b352f8063a441f0bcc0b8dba8b3a88284b44e5f0a3bd7c437f0d4c596350e407063f3c34&scene=178&cur_album_id=2556040001080557569#rd

第一行的code是怎么设计的呢？

第一行可以对照opcode表翻译一下 你就会发现他和整个code指令是一样的

调用合约之后返回的结果就是绿框框的内容 这个内容和合约code是一样的（实现了调用合约返回的结果和合约的code一样
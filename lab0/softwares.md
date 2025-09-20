
### 实验中可能使用的软件

#### ***编辑器***

(1) Ubuntu 下自带的编辑器可以作为代码编辑的工具。例如 gedit 是 gnome 桌面环境下兼容UTF-8的文本编辑器。它十分的简单易用，有良好的语法高亮，对中文支持很好。通常可以通过双击或者命令行打开目标文件进行编辑。
[参考教程](https://blog.csdn.net/thisway_diy/article/details/108728087)

(2) nano

nano 是一款在终端中使用的轻量级文本编辑器，界面简洁、上手容易，适合快速查看与修改配置文件或代码片段。与 vi/vim 相比，nano 的常用操作在屏幕底部都有提示，学习成本较低。
[参考教程](https://blog.csdn.net/qq_41964263/article/details/148450309)

常用操作：
- 打开文件：nano 文件名
- 保存：Ctrl+O（回车确认）
- 退出：Ctrl+X（有修改会提示是否保存）
- 搜索：Ctrl+W
- 剪切/粘贴整行：Ctrl+K / Ctrl+U
- 跳转到行号：Ctrl+_（下划线），输入行号回车

Ubuntu中的安装指令为：

```shell
sudo apt-get install nano
```

(3) VSCode

如果你已经厌倦了命令行的操作，那么是时候使用一些真正现代化的工具了，相信你已经在其他课程中使用过它，如果还没有的话，现在下载也完全来得及。
关于使用VSCode在虚拟机或者wsl进行开发的连接方式，有以下内容作为参考：
[配置教程-虚拟机](https://blog.csdn.net/qq_45223683/article/details/141140237)
[配置教程-wsl](https://blog.csdn.net/weixin_41080308/article/details/144559183)

#### ***exuberant-ctags***

exuberant-ctags 可以为程序语言对象生成索引，其结果能够被一个文本编辑器或者其他工具简捷迅速的定位。支持的编辑器有 Vim、Emacs 等。
实验中，可以使用命令：

	ctags -h=.h.c.S -R
默认的生成文件为 tags (可以通过 -f 来指定)，在相同路径下使用 Vim 可以使用改索引文件，例如:

	使用 “ctrl + ]” 可以跳转到相应的声明或者定义处，使用 “ctrl + t” 返回（查询堆栈）等。

提示：习惯GUI方式的同学，可采用图形界面的understand、source insight等软件。

#### ***diff & patch***

diff 为 Linux 命令，用于比较文本或者文件夹差异，可以通过 man 来查询其功能以及参数的使用。使用 patch 命令可以对文件或者文件夹应用修改。

例如实验中可能会在 proj_b 中应用前一个实验proj_a 中对文件进行的修改，可以使用如下命令：

	diff -r -u -P proj_a_original proj_a_mine > diff.patch
	cd proj_b
	patch -p1 -u < ../diff.patch

注意：proj_a_original 指 proj_a 的源文件，即未经修改的源码包，proj_a_mine 是修改后的代码包。第一条命令是递归的比较文件夹差异，并将结果重定向输出到 diff.patch 文件中；第三条命令是将 proj_a 的修改应用到 proj_b 文件夹中的代码中。

提示：习惯GUI方式的同学，可采用图形界面的meld、kdiff3、UltraCompare等软件。

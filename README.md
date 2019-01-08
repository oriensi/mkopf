1. 利用 eamcs 的 org-mode 生成 html 文件
```
#+HTML_HEAD: <link rel="stylesheet" type="text/css" href="kindle.css"/>
```
2. 执行 makeopf 生成 opf 及相关文件
   ` ./makeopf.pl <title> <author> `
3. 通过 kindlegen 生成 mobi 文件
```
kindlegen [filename.opf/.htm/.html/.epub/.zip or directory] [-c0 or -c1 or c2] [-verbose] [-western] [-dont_append_source] [-o <file name>]
```

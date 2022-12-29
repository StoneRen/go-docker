# go 的 docker 构建

## 背景

```bash
.
├── go.mod
└── hello.go
```

```go
// hello.go
package main

import "fmt"

func main() {
	fmt.Println("Hello World")
}

```

## v1： 普通构建

### 编写 Dockerfile

```dockerfile
FROM golang:alpine

WORKDIR /build

COPY hello.go .

RUN go build -o hello hello.go

CMD ["./hello"]
```
### 构建
```shell
docker build -t hello:v1 .
docker run -it --rm hello:v1
# Hello World


docker images | grep hello
# hello  v1   c53dd69d5a2a   27 seconds ago   353MB
```

### 问题

>仅仅是1个打印输出，但是镜像竟然有 `353MB`?

看一下具体是大在哪里？

```shell
IMAGE          CREATED          CREATED BY                                      SIZE      COMMENT
c53dd69d5a2a   11 minutes ago   CMD ["./hello"]                                 0B        buildkit.dockerfile.v0
<missing>      11 minutes ago   RUN /bin/sh -c go build -o hello hello.go # …   2.07MB    buildkit.dockerfile.v0
<missing>      11 minutes ago   COPY hello.go . # buildkit                      72B       buildkit.dockerfile.v0
<missing>      11 minutes ago   WORKDIR /build                                  0B        buildkit.dockerfile.v0
<missing>      3 weeks ago      /bin/sh -c #(nop) WORKDIR /go                   0B        
<missing>      3 weeks ago      /bin/sh -c mkdir -p "$GOPATH/src" "$GOPATH/b…   0B        
<missing>      3 weeks ago      /bin/sh -c #(nop)  ENV PATH=/go/bin:/usr/loc…   0B        
<missing>      3 weeks ago      /bin/sh -c #(nop)  ENV GOPATH=/go               0B        
<missing>      3 weeks ago      /bin/sh -c set -eux;  apk add --no-cache --v…   342MB     
<missing>      3 weeks ago      /bin/sh -c #(nop)  ENV GOLANG_VERSION=1.19.4    0B        
<missing>      3 weeks ago      /bin/sh -c #(nop)  ENV PATH=/usr/local/go/bi…   0B        
<missing>      3 weeks ago      /bin/sh -c apk add --no-cache ca-certificates   622kB     
<missing>      5 weeks ago      /bin/sh -c #(nop)  CMD ["/bin/sh"]              0B        
<missing>      5 weeks ago      /bin/sh -c #(nop) ADD file:685b5edadf1d5bf0a…   7.46MB  
```
重点是这句话：`apk add --no-cache --v…   342MB`，这个命令占据了绝大部分的空间

# V2:  直接执行文件
既然镜像最耗费空间的是 go 的环境，而本身执行文件只有`7.46MB`， 那直觉告诉我们，我们替换环境镜像，直接复制执行文件就可以大大减轻文件体积。

```dockerfile
FROM alpine

WORKDIR /build

COPY hello .

CMD ["./hello"]
```
那我们打包一个新版本。
```shell
docker build -t hello:v2 .
```
看一下效果如何：
```shell
docker images | grep hello
hello v2  87ee9ec74d41   6 seconds ago    9.39MB
hello v1  c53dd69d5a2a   22 minutes ago   353MB
```
效果还是非常明显的。

## 问题
```shell
docker run -it --rm hello:v2
# exec ./hello: exec format error
```
我们执行命令是有问题的。
这个原因在于我们我们 build 的时候和 docker 镜像的执行环境是不一致的。

```shell
GOOS=linux go build -o hello hello.go
docker build -t hello:v2 .
docker run -it --rm hello:v2
```
现在执行已经 OK 了，现在想想是否就可以了呢？

现在存在一个问题，就是我们的打包镜像的过程是割裂的，我得先本地开发打包可执行文件，然后再打包镜像。我们是否可以统一由 docker 来完成本过程？答案是肯定的。

# V3：过程统一

```dockerfile
FROM golang:alpine AS builder
WORKDIR /build
COPY . .
RUN go build -o hello hello.go


FROM alpine
WORKDIR /build
COPY --from=builder /build/hello /build/hello
CMD ["./hello"]
```

```shell
docker build -t hello:v3 .
```
查看镜像大小
```shell
docker images | grep hello

hello      v3  e37f189f3f0d   5 seconds ago    9.28MB
hello      v2  a33c543d83f7   8 minutes ago    9.28MB
hello      v1  c53dd69d5a2a   36 minutes ago   353MB
```
大小是没有变化的，这也是符合预期的。因为我们主要改变的是build环境。

```shell
docker run -it --rm hello:v3
# Hello World
```
执行下来也是没有问题的，这样我们就做了一个好用且省空间的镜像。
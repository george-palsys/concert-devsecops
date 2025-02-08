# 使用 Liberty Base 镜像（支持 Java 17）
FROM icr.io/appcafe/websphere-liberty:full-java17-openj9-ubi

# 设置工作目录
WORKDIR /opt/ol/wlp/usr/servers/defaultServer

# 拷贝 Liberty 的 server.xml 配置（配置 web 应用）
COPY server.xml /config/

# 拷贝 WAR 文件到 Liberty 的应用目录
COPY target/insecure-bank.war /config/dropins/

# 暴露 Liberty 默认的 HTTP 和 HTTPS 端口
EXPOSE 9080 9443

# 启动 Liberty 服务器
CMD ["defaultServer"]

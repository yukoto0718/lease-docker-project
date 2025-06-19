FROM openjdk:17-jdk-alpine

# 安装字体支持
RUN apk update && \
    apk add --no-cache fontconfig ttf-dejavu && \
    rm -rf /var/cache/apk/*

# 复制jar文件
COPY web-app-1.0-SNAPSHOT.jar /app.jar

# 设置字体缓存
RUN fc-cache -fv

# 设置时区
ENV TZ=Asia/Shanghai

# 启动命令  
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app.jar"]

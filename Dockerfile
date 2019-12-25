#####################################################################################################
#
#           前言
# 本dockerfile所在目录的文件中有以下几个文件用来测试用的
# jdk-8u221-linux-x64.tar.gz   apache-tomcat-7.0.96.tar.gz  test_command_copy.txt   testDir.tar.gz
#
#本dockerfile中常用到的构建指令：docker build --build-arg author=monk -t custom:0.1 .
#
#
#####################################################################################################


#基于centos：latest版本的镜像
FROM centos

#拷贝一下两个文件到容器的/usr/local目录下
#这里因为copy过去需要解压，所以这里就直接使用ADD，没有使用copy，使用的方法是一样的，注意区别即可
ADD jdk-8u221-linux-x64.tar.gz /usr/local
ADD apache-tomcat-7.0.96.tar.gz /usr/local

#COPY指令的使用(多个文件分开COPY)
#COPY test_command_copy.txt /home/monk
#COPY testDir.tar.gz /home/monk

# 多个文件放在一行执行，源文件可以有多个，目标文件只可以有一个
# 并且，docker build的时候可以看到没一个指定对应一个step，所以建议在使用指令的时候，尽量写在一行，或者说尽量写在一条指令中
COPY test_command_copy.txt testDir.tar.gz /home/monk/

#设置容器的环境变量，如果想使用变量，记得先声明，在第二行才可以使用变量，否则会设置环境变量失败
ENV JAVA_HOME=/usr/local/jdk1.8.0_221 CATALINA_HOME=/usr/local/apache-tomcat-7.0.96
ENV CLASSPATH=.:${JAVA_HOME}/lib
#这里使用的格式是空格，上面一行环境变量使用的是key=value的形式，这里只是测试下两者都可以
ENV PATH $PATH:${JAVA_HOME}/bin:$CATALINA_HOME/bin

#容器暴露出去的端口，外部只可以访问这个端口
EXPOSE 8080

#切换工作目录，切换工作目录到tomcat目录下
WORKDIR ${CATALINA_HOME}

#!!!切记!!! VOLUME之后对于挂载点目录的操作，将不会成功，这里将Line:42和Line:48位置互换，容器运行起来后，目录挂载成功，但是index.html在宿主机和容器中均找不到
#PS： 如果行号不对，就是本dockerfile中的第一条VOLUME和第二条VOLUME指令，不论是否注释的指令
#VOLUME ["${CATALINA_HOME}/webapps","$CATALINA_HOME/logs"]
#使用RUN指令，执行echo指令，往${CATALINA_HOME}/webapps/ROOT目录下写了一个index.html，内容为“hello word“
RUN echo 'hello word' -> ${CATALINA_HOME}/webapps/ROOT/index.html

#设置挂载点，尽量写绝对路径。因为测试过，即使切换到了工作目录下，挂载路径写相对路径，会挂载失败
#在先写入index.html文件之后，再创建挂载点，在宿主机和容器中均可以看到index.html
VOLUME ["${CATALINA_HOME}/webapps","$CATALINA_HOME/logs"]

#容器启动的时候，执行的指令   catalina.sh run
#!!!注意!!!  CMD中的指令会被docker run后跟的参数覆盖掉  测试指令：docker run --rm -it custom:0.1 ls
#执行这条指令后，就会发现tomcat不会正常启动，并且在控制台输出ls指令显示的目录文件
#输入docker run --rm -it custom:0.1 指令，tomcat就会正常启动
CMD ["catalina.sh","run"]

#类似于CMD指令，都是给容器启动后执行的命令，但是区别在于，ENTRYPOINY指令不会被覆盖，可以用CMD指令上的注释中的指令来验证
ENTRYPOINT ["catalina.sh","run"]

#声明变量author，通过docker build中的参数build-arg <key>=<value>方式传值，Eg:docker build --build-arg author=monk -t custom:0.1 .
ARG author=testVar

#设置镜像的制作者简单信息,这个指令不支持使用ARG变量(生成镜像的 Author 字段)
MAINTAINER monk

#给镜像添加一些元信息，过个以空格隔开，ARG指令声明的author在这下面这条指令的地方都可以使用亲测
LABEL version=0.1 desc="this dockerfile is create by ${author}" create_date=2019.12.20

#测试下变量%{author}在输出文本中是否也可以使用，经过测试不仅仅是可以使用的，并且还可以在路径中使用
RUN echo "this docker file is create by ${author}" > /home/monk/${author}.txt
VOLUME /home/monk


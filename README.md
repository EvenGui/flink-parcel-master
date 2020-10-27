

# 集成目的

- 集成Flink HistoryServer至CDH（在CDH上运行的Flink程序，在程序结束后的任务均会显示在该角色实例的WebUI上）
- 集成Gateway（快捷命令，Flink配置分发）
- 集成Hive相关配置至CDH Flink
- 兼容Flink1.10 Flink1.11版本至CDH

最终效果如图

![image-20201022152537012](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022152537012.png)

![image-20201022152910241](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022152910241.png)

# 源码编译

> 说明：因为我们需要与CDH集成，故Flink需要编译CDH的版本，以减少部署和使用过程中JAR冲突依赖的问题

## 编译环境准备

### 安装JDK1.8

（使用JDK1.8编译，JDK11编译Flink1.11时会停顿，卡住，且无任何提示信息）

### 安装Git

```shell
yum install git -y
```

### 安装Maven　　

```shell
wget http://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/3.6.1/binaries/apache-maven-3.6.1-bin.tar.gz
tar xzvf apache-maven-3.6.1-bin.tar.gz -C /usr/local/
mv /usr/local/apache-maven-3.6.1/ /usr/local/maven
vim /etc/profile
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin:
source /etc/profile
maven -v

vim /usr/local/maven/conf/setting.xml
修改以下参数
<localRepository>/opt/build_flink/mavenlib</localRepository>

<mirrors>
    <mirror>
		  <id>alimaven</id>
		  <mirrorOf>central</mirrorOf>
		  <name>aliyun maven</name>
		  <url>http://maven.aliyun.com/nexus/content/repositories/central/</url>
    </mirror>
    <mirror> 
      <id>alimaven</id> 
      <name>aliyun maven</name> 
      <url>http://maven.aliyun.com/nexus/content/groups/public/</url> 
      <mirrorOf>*,!cloudera</mirrorOf>         
    </mirror>
    <mirror>
      <id>central</id>
      <name>Maven Repository Switchboard</name>
      <url>http://repo1.maven.org/maven2/</url>
      <mirrorOf>central</mirrorOf>
    </mirror>
    <mirror>
      <id>repo2</id>
      <mirrorOf>central</mirrorOf>
      <name>Human Readable Name for this Mirror.</name>
      <url>http://repo2.maven.org/maven2/</url>
    </mirror>
    <mirror>
      <id>ibiblio</id>
      <mirrorOf>central</mirrorOf>
      <name>Human Readable Name for this Mirror.</name>
      <url>http://mirrors.ibiblio.org/pub/mirrors/maven2/</url>
    </mirror>
    <mirror>
      <id>jboss-public-repository-group</id>
      <mirrorOf>central</mirrorOf>
      <name>JBoss Public Repository Group</name>
      <url>http://repository.jboss.org/nexus/content/groups/public</url>
    </mirror>
    <mirror>
      <id>google-maven-central</id>
      <name>Google Maven Central</name>
      <url>https://maven-central.storage.googleapis.com
      </url>
      <mirrorOf>central</mirrorOf>
    </mirror>
    <!-- 中央仓库在中国的镜像 -->
    <mirror>
      <id>maven.net.cn</id>
      <name>oneof the central mirrors in china</name>
      <url>http://maven.net.cn/content/groups/public/</url>
      <mirrorOf>central</mirrorOf>
    </mirror>
  </mirrors>
```

### 安装Node

 (编译flink-runtime-web模块)

```shell
wget https://nodejs.org/dist/v12.19.0/node-v12.19.0-linux-x64.tar.xz
tar -xvf node-v12.19.0-linux-x64.tar.xz

ln -s /opt/build_flink/node-v12.19.0-linux-x64/bin/npm   /usr/local/bin/ 
ln -s /opt/build_flink/node-v12.19.0-linux-x64/bin/node   /usr/local/bin/
node -v
npm -v
```

### Flink源码编译

#### flink-shaded

选用release-10.0版本，release-9.0版本在flink1.11版本的集成中缺少相关的common包，release-11.0版本已经移除掉了flink-shaded-hadoop-2模块   [FLINK-17685](https://issues.apache.org/jira/browse/FLINK-17685)

```shell
wget https://github.com/apache/flink-shaded/archive/release-10.0.zip
tar -xvf release-10.0.zip
cd flink-shaded-10.0
vim pom.xml
```

在pom.xml中，把下面内容加入到<profiles></profiles> 里面去：

```xml
<profile>
	<id>vendor-repos</id>
	<activation>
		<property>
			<name>vendor-repos</name>
		</property>
	</activation>
	<!-- Add vendor maven repositories -->
	<repositories>
		<!-- Cloudera -->
		<repository>
			<id>cloudera-releases</id>
			<url>https://repository.cloudera.com/artifactory/cloudera-repos</url>
			<releases>
				<enabled>true</enabled>
			</releases>
			<snapshots>
				<enabled>false</enabled>
			</snapshots>
		</repository>
		<!-- Hortonworks -->
		<repository>
			<id>HDPReleases</id>
			<name>HDP Releases</name>
			<url>https://repo.hortonworks.com/content/repositories/releases/</url>
			<snapshots><enabled>false</enabled></snapshots>
			<releases><enabled>true</enabled></releases>
		</repository>
		<repository>
			<id>HortonworksJettyHadoop</id>
			<name>HDP Jetty</name>
			<url>https://repo.hortonworks.com/content/repositories/jetty-hadoop</url>
			<snapshots><enabled>false</enabled></snapshots>
			<releases><enabled>true</enabled></releases>
		</repository>
		<!-- MapR -->
		<repository>
			<id>mapr-releases</id>
			<url>https://repository.mapr.com/maven/</url>
			<snapshots><enabled>false</enabled></snapshots>
			<releases><enabled>true</enabled></releases>
		</repository>
	</repositories>
</profile>
```

执行编译

```shell
mvn -T4C clean install -DskipTests -Pvendor-repos -Dhadoop.version=3.0.0-cdh6.3.3 -Dscala-2.11 -Drat.skip=true
```

最终生成的文件是：flink-shaded-hadoop-2-uber-3.0.0-cdh6.3.3-10.0.jar

#### flink

编译完成后，下载Flink版本,可选以下版本

```shell
#Flink 1.11.2版本
wget https://github.com/apache/flink/archive/release-1.11.2.zip
#Flink 1.10.2版本
wget https://github.com/apache/flink/archive/release-1.10.2.zip
```

以Flink1.10.2版本为例

```shell
cd flink-release-1.10.2
vim pom.xml

```

加入

```xml
 
 <repositories>
		<repository>
			<id>cloudera</id>
			<url>https://repository.cloudera.com/artifactory/cloudera-repos/</url>
		</repository>
	</repositories>
```

```shell
cd flink-runtime-web
vim pom.xml
```

在<plugin>标签中，修改groupId为com.github.eirslett的<executions>标签下的值

```xml
<execution>
						<id>install node and npm</id>
						<goals>
							<goal>install-node-and-npm</goal>
						</goals>
						<configuration>
							<nodeDownloadRoot>https://registry.npm.taobao.org/dist/</nodeDownloadRoot>
							<npmDownloadRoot>https://registry.npmjs.org/npm/-/</npmDownloadRoot>
							<nodeVersion>v10.9.0</nodeVersion>
						</configuration>
					</execution>
					<execution>
						<id>npm install</id>
						<goals>
							<goal>npm</goal>
						</goals>
						<configuration>
							<arguments>install -registry=https://registry.npm.taobao.org --cache-max=0 --no-save</arguments>
							<environmentVariables>
								<HUSKY_SKIP_INSTALL>true</HUSKY_SKIP_INSTALL>
							</environmentVariables>
						</configuration>
</execution>
```



```shell
#开始编译
mvn clean install -DskipTests -Dfast -Drat.skip=true -Dhaoop.version=3.0.0-cdh6.3.3 -Pvendor-repos -Dinclude-hadoop -Dscala-2.11 -T4C

参数说明
# -Dfast  #在flink根目录下pom.xml文件中fast配置项目中含快速设置,其中包含了多项构建时的跳过参数. #例如apache的文件头(rat)合法校验，代码风格检查，javadoc生成的跳过等，详细可阅读pom.xml
# install maven的安装命令
# -T4C #支持多处理器或者处理器核数参数,加快构建速度,推荐Maven3.3及以上
# -Pinclude-hadoop  将hadoop的 jar包，打入到lib/中
# -Pvendor-repos   # 如果需要指定hadoop的发行商，如CDH，需要使用-Pvendor-repos
# -Dscala-2.11     # 指定scala的版本为2.11
# -Dhadoop.version=3.0.0-cdh6.3.3  指定 hadoop 的版本，这里的版本与CDH集群版本的Hadoop一致就行

cd flink-release-1.10.2/flink-dist/target/flink-1.10.2-bin/flink-1.10.2
tar zcvf flink-1.10.2-cdh6.3.3-0001.tgz flink-1.10.2

#  Flink1.10与Flink1.11的版本编译没有太大差异，需要了解的是

#  Flink1.11使用的是flink-shaded release-11.0版本，已经移除掉了flink-shaded-hadoop-2模块，故在最终生成的flink编译后目录中不会有flink-shaded-hadoop-2-uber包
#  Flink1.10使用的是flink-shaded release-9.0的版本，如果在maven编译的过程中，无法下载flink-shaded-hadoop-2-uber-2.7.5-9.0.jar，下载wget https://github.com/apache/flink-shaded/archive/release-9.0.zip，
编译：mvn clean install -T4C -Pinclude-hadoop -Dhadoop.version=2.7.5 -DskipTests -Dscala-2.11

# 不推荐以Scala版本为2.12编译，在启动start-scala-shell.sh的时候会报错，错误信息为： Error: Could not find or load main class org.apache.flink.api.scala.FlinkShell
#  这是 flink 的一个 bug，基于 scala 2.12 编译的 flink 会存在这个问题，使用基于 scala 2.11 编译的 flink 就不会有这个问题了。这个 bug 之后应该会修复，当前已知在 flink 1.11 中这个问题依然存在。
```

#### jar包依赖添加

##### Flink1.10.2版本

在flink-release-1.10.2/flink-dist/target/flink-1.10.2-bin/flink-1.10.2/lib中添加以下jar

libfb303-0.9.3.jar

hive-exec-2.1.1-cdh6.3.3.jar（sz  /opt/cloudera/parcels/CDH/lib/hive/lib/hive-exec-2.1.1-cdh6.3.3.jar）

flink-connector-hive_2.11-1.10.2.jar (flink-release-1.10.2/flink-connectors/flink-connector-hive/target/flink-connector-hive_2.11-1.10.2.jar )

flink-shaded-hadoop-2-uber-3.0.0-cdh6.3.3-10.0.jar  (flink-shaded-10.0/flink-shaded-hadoop-2-parent/flink-shaded-hadoop-2-uber/target/flink-shaded-hadoop-2-uber-3.0.0-cdh6.3.3-10.0.jar)

删除lib目录已存在的flink-shaded-hadoop-2-uber-2.7.5-9.0.jar

##### Flink1.11.2版本

在flink-release-1.10.2/flink-dist/target/flink-1.10.2-bin/flink-1.10.2/lib中添加以下jar

libfb303-0.9.3.jar

hive-exec-2.1.1-cdh6.3.3.jar（sz  /opt/cloudera/parcels/CDH/lib/hive/lib/hive-exec-2.1.1-cdh6.3.3.jar）

flink-connector-hive_2.11-1.11.2.jar (flink-release-1.11.2/flink-connectors/flink-connector-hive/target/flink-connector-hive_2.11-1.11.2.jar )

flink-shaded-hadoop-2-uber-3.0.0-cdh6.3.3-10.0.jar  (flink-shaded-10.0/flink-shaded-hadoop-2-parent/flink-shaded-hadoop-2-uber/target/flink-shaded-hadoop-2-uber-3.0.0-cdh6.3.3-10.0.jar)

# Parcel制作

## 相关介绍

### parcel

以".parcel"结尾的压缩文件。parcel包内共4个目录

##### lib

包含了服务组件,即编译好了的Flink安装包

##### bin

-  configbuilder.jar  flink生成配置文件的jar
-  flink    快捷命令
-  flink-exec-env.sh 环境变量设置脚本。如HADOOP_HOME，HADOOP_CONF_DIR，FLINK_HOME等。相关快捷命令（flink）执行时，都会调用这个脚本
-  flink-historyserver 快捷命令,内部调用flink/bin目录下的historyserver.sh
-  flink-pyflink-shell 快捷命令,内部调用flink/bin目录下的pyflink-shell.sh
-  flink-sql-client 快捷命令，内部调用flink/bin目录下的sql-client.sh
-  flink-start-scala-shell 快捷命令，内部调用flink/bin目录下的start-scala-shell.sh
-  flink-yarn-session 快捷命令,内部调用flink/bin目录下的yarn-session.sh

##### meta

1. alternatives.json  

   ```json
   "flink": {
     "destination": "/usr/bin/flink",
     "source": "bin/flink",
     "priority": 10,
     "isDirectory": false
   }
   #....
   #配置上述bin目录下的flink与/usr/bin/flink的对应关系，cdh在安装Flink时，会制作相关的快捷命令链接到/usr/bin 目录下
   ```

2. flink_env.sh CDH安装Flink的安装目录环境变量配置

3. parcel.json 这个文件记录了服务的信息，如版本、所属用户、适用的CDH平台版本等。

4. permissions.json

   ```shell
   "bin/flink": {
     "user":  "flink",
     "group": "flink",
     "permissions": "0755"
   }
   #....
   #快捷命令的权限描述文件
   ```

5. release-notes.txt  描述文件,略

##### etc

```xml
└── flink
    └── conf.dist
        ├── flink-conf.yaml
        ├── log4j-cli.properties
        ├── log4j-console.properties
        ├── log4j.properties
        ├── log4j-session.properties    Flink 1.10.2 的yarn-session日志配置文件
        ├── log4j-yarn-session.properties Flink 1.11.2 的yarn-session日志配置文件
        └── sql-client-defaults.yaml

主要是Flink的相关配置，在你编译的Flink源码目录中flin/bin/conf目录下
```

### csd

csd文件是一个jar包，例如：FLINK_ON_YARN-1.10.2.jar，作用是引导用户在CDH页面上进行安装配置Flink。

重要部分：在CDH安装Flink时，要先确定/opt/cloudera/csd目录下有没有别的Flink CSD包，如果存在，则移出备份，目录最后存在一个csd jar包，即FLINK_ON_YARN-1.10.2.jar，因为不同版本的csd 引导安装Flink的安装步骤，Flink的参数配置都可能不一样，所以在安装时，确保只有一个csd jar

在CDH页面操作删除Flink后，会删除/opt/cloudera/parcel-repo目录下你上传的flink parcel文件，sha文件，但是不会删除/opt/cloudera/csd/FLINK_ON_YARN-1.10.2.jar 文件，请手动删除！

##### aux

```
├── configbuilder 
│   ├── cli.json   生成GateWay相关配置
│   └── hs.json    生成HistoryServer相关配置
├── defaults  配置相关
│   ├── log4j-console.properties
│   ├── log4j.properties
│   ├── log4j-session.properties
│   ├── log4j-yarn-session.properties
│   └── sql-client-defaults.yaml
└── templates   生成配置文件模板
    ├── flink-cli-conf.yaml.j2  GateWay模板
    └── flink-hs-conf.yaml.j2   HistoryServer模板
```

##### descriptor

略，请查看 https://github.com/EvenGui/flink-parcel-master/blob/main/descriptor/service.sdl

##### images

Flink图标

##### scripts

```
├── configbuilder.sh 根据不同的实例(HistoryServer,GateWay) 执行configbuilder.jar，生成不同实例的相关配置至flink-conf.yaml
├── control.sh  HistoryServer和GateWay实例启动时的脚本
└── set-dependencies.sh  根据配置，设置ZK相关的信息至flink-conf.yaml，Hive相关的信息至sql-client-defaults.yaml，在打包制作的过程中，可根据目前CDH集群Hive版本，修改该脚本
```



## 打包命名规则

**命名规则必须如下**：

文件名称格式为五段，第一段是包名，第二段是版本号，第三段是CDH版本号，第四段是你制作打包的版本号，第五段是运行平台。

例如：FLINK-1.10.2-CDH6.3.3-0001-el7.parcel

**包名**：FLINK

**版本号**：1.10.2

**CDH版本号**：CDH6.3.3

**打包制作版本号**：0001

**运行环境**：el7

el6是代表centos6系统，centos7则用el7表示

## 开始制作

```shell
git clone https://github.com/EvenGui/flink-parcel-master
```



```shell
cd flink-parcel-master
vim flink-parcel.properties

#Flink 路径，这里的路径就是Flink编译后存放的路径
FLINK_URL=  /opt/make-flink/flink-1.10.2-cdh6.3.3-0001.tgz

#flink版本号
FLINK_VERSION=1.10.2

#扩展版本号，每次打包需要修改扩展版本号，例如CDH6.3.3-0001，所对应的FLINK_URL为/opt/make-flink/flink-1.10.2-cdh6.3.3-0002.tgz
EXTENS_VERSION=CDH6.3.3-0001

#操作系统版本，以centos为例
OS_VERSION=7

#CDH 小版本
CDH_MIN_FULL=6.2
CDH_MAX_FULL=6.4

#CDH大版本
CDH_MIN=5
CDH_MAX=6

#说明：每次打包，需要更改FLINK_URL EXTENS_VERSION值，如FLINK_URL=/opt/make-flink/flink-1.10.2-cdh6.3.3-0002.tgz EXTENS_VERSION = CDH6.3.3-0002
```

```shell
sh build.sh parcel

........
+ java -jar cm_ext/validator/target/validator.jar -f ./FLINK-1.10.2-CDH6.3.3-0001_build/FLINK-1.10.2-CDH6.3.3-0004-el7.parcel
Validating: ./FLINK-1.10.2-CDH6.3.3-0001_build/FLINK-1.10.2-CDH6.3.3-0001-el7.parcel
Validating: FLINK-1.10.2-CDH6.3.3-0001/meta/parcel.json
Validating: FLINK-1.10.2-CDH6.3.3-0001/meta/alternatives.json
Validating: FLINK-1.10.2-CDH6.3.3-0001/meta/permissions.json
Validation succeeded.   主要关注是否有Validation succeeded的打印，如果没有表示Parcel制作失败
+ python cm_ext/make_manifest/make_manifest.py ./FLINK-1.10.2-CDH6.3.3-0001_build
Scanning directory: ./FLINK-1.10.2-CDH6.3.3-0001_build
Found parcel FLINK-1.10.2-CDH6.3.3-0001-el7.parcel
+ sha1sum ./FLINK-1.10.2-CDH6.3.3-0001_build/FLINK-1.10.2-CDH6.3.3-0001-el7.parcel
+ awk '{print $1}'
编译成功
```

```shell
sh build.sh csd

..........
+ java -jar cm_ext/validator/target/validator.jar -s flink_csd_build/descriptor/service.sdl -l FLINK_ON_YARN
Validating: flink_csd_build/descriptor/service.sdl
Validation succeeded.  主要关注是否有Validation succeeded的打印，如果没有表示csd制作失败
+ jar -cvf ./FLINK_ON_YARN-1.10.2.jar -C flink_csd_build .
..........
```

在flink-parcel-master目录下会生成FLINK_ON_YARN-1.10.2.jar，在FLINK-1.10.2-CDH6.3.3-0001_build目录下会生成FLINK-1.10.2-CDH6.3.3-0001-el7.parcel  FLINK-1.10.2-CDH6.3.3-0001-el7.parcel.sha  manifest.json 3个文件

```shell
#在CDH 主节点进行操作
#将原来的manifest.json备份
mv /opt/cloudera/parcel-repo/manifest.json /opt/cloudera/parcel-repo/manifest.back.json
cp FLINK_ON_YARN-1.10.2.jar  /opt/cloudera/csd/   && cp FLINK-1.10.2-CDH6.3.3-0001_build/* 
/opt/cloudera/parcel-repo/  && systemctl restart cloudera-scm-server
```

## 开始安装

![image-20201022172400317](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022172400317.png)

![image-20201023090550422](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201023090550422.png)

如果集群开启了Kerberos，这里选择勾选，CDH会自动在/var/run/cloudera-scm-agent/process/xxx-flink-FLINK_HISTORY_SERVER下创建flink.keytab文件

![image-20201022172609513](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022172609513.png)

![image-20201022173526475](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022173526475.png)

根据以下Hive相关配置

![image-20201022173611138](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022173611138.png)



![image-20201022175549145](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022175549145.png)

在sql-client中查询hive表时，hive source是自动推断并发的，将table.exec.hive.infer-source-parallelism取消勾选，把hive  source是自动推断并发推导关闭，否则会有以下问题

表文件夹288个

![image-20201023090737358](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201023090737358.png)

自动推导288个并发

![image-20201023090816188](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201023090816188.png)

在CDH上可配置Hive相关的参数

| 参数名                                       | 参数说明                                                     |
| -------------------------------------------- | ------------------------------------------------------------ |
| sql_current_db                               | SQL Client Current Database                                  |
| enable_hive_catalog                          | Enables Hive Catalog for SQL Client                          |
| table.exec.hive.infer-source-parallelism     | If is true, source parallelism is inferred according to splits number. If is false, parallelism of source are set by config. |
| table.exec.hive.infer-source-parallelism.max | Sets max infer parallelism for source operator.              |
| sql_current_catalog                          | Catalog for SQL Client                                       |

​            

完成修改配置后，点击重新部署客户端

![image-20201022175759722](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022175759722.png)



## 测试

flink-sql-client embedded

![image-20201022180342737](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022180342737.png)

![image-20201022180922177](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022180922177.png)

![image-20201022181021414](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022181021414.png)

![image-20201022181140649](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022181140649.png)

![image-20201022181208712](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022181208712.png)

在YARN中可查看该SQL执行情况

![image-20201022181258445](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022181258445.png)

在Flink HistoryServer中可查看任务执行情况

![image-20201022181350859](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022181350859.png)

![image-20201023090851943](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201023090851943.png)

也可执行WordCount测试

```shell
flink run -m yarn-cluster /opt/cloudera/parcels/FLINK/lib/flink/examples/batch/WordCount.jar
```

![image-20201022182230085](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022182230085.png)

![image-20201023090946077](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201023090946077.png)

## 问题

### Q1: 权限认证

![image-20201022180048083](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022180048083.png)

在shell操作前，使用kinit -k -t /root/flink.keytab flink@xxx.COM

如果本地没有flink.keytab文件，可以在最新的/var/run/cloudera-scm-agent/process/xxx-flink-FLINK_HISTORY_SERVER目录找一个

## 需要了解的问题

说明：在制作Parcel时，就已经将以下包加入到Flink的lib中，故无需解决这些问题

执行flink-sql-client embedded

Q1:缺少flink-connector-hive_2.11-1.10.2.jar包

![image-20201022185425563](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022185425563.png)

将flink-connector-hive_2.11-1.10.2.jar scp到各节点后

Q2：缺少 hive-exec-2.1.1-cdh6.3.3.jar包

![image-20201022185744738](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022185744738.png)

将hive-exec-2.1.1-cdh6.3.3.jar  scp到各节点后

Q3:缺少libfb303-0.9.3.jar包

![image-20201022185930504](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022185930504.png)

将libfb303-0.9.3.jar scp到各节点后

Q4:缺少flink-shaded-hadoop-2-uber-3.0.0-cdh6.3.3-10.0.jar包

![image-20201022190440588](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022190440588.png)



## Sql-Client的其它组件集成

例如集成ES，Kafka，请使用flink-sql-client embedded -d my.yaml -l sql-libs

my.yaml文件，是你自己配置的连接信息，如果不指定，则使用CDH默认生成的/etc/flink/conf.cloudera.flink/sql-client-defaults.yaml文件

sql-libs为你自己创建的文件夹，里面存放的就是flink连接kafka或者es的相关依赖包

不建议将依赖包全部存放在/opt/cloudera/parcels/FLINK/lib/flink/lib/ 下

原因：每次提交Flink程序，Flink都会去加载/opt/cloudera/parcels/FLINK/lib/flink/lib/ 下的包，会照成资源浪费，依赖包过多，可能会有JAR包冲突的问题！

![image-20201022191403740](https://github.com/EvenGui/flink-parcel-master/blob/main/github-img/image-20201022191403740.png)


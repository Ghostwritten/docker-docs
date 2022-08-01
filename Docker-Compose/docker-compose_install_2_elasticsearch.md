#  docker-compose 安装 elasticsearch 集群

## 1. 创建一个es节点的集群
```bash
$vim docker-compose.yaml
```

```bash
version: '2.2'
services:
  cerebro:
    image: lmenezes/cerebro:0.9.2
    container_name: cerebro
    ports:
      - "9000:9000"
    command:
      - -Dhosts.0.host=http://elasticsearch:9200
    networks:
      - es7net
  kibana:
    image: kibana:7.2.0
    container_name: kibana7
    environment:
      - I18N_LOCALE=zh-CN
      - XPACK_GRAPH_ENABLED=true
      - TIMELION_ENABLED=true
      - XPACK_MONITORING_COLLECTION_ENABLED="true"
      - ELASTICSEARCH_USERNAME=kibana
      - ELASTICSEARCH_PASSWORD=demo_password
    ports:
      - "5601:5601"
    networks:
      - es7net
  elasticsearch:
    #image: docker.elastic.co/elasticsearch/elasticsearch:7.2.0
    image: elasticsearch:7.2.0
    container_name: es7_01
    environment:
      - cluster.name=test-es
      - node.name=es7_01
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms1G -Xmx1G"
      - "TZ=Asia/Shanghai"
      - discovery.type=single-node
      - path.data=node0_data
      - xpack.security.enabled=false
      - xpack.security.transport.ssl.enabled=false
    ulimits:
      memlock:
        soft: -1
        hard: -1
    privileged: true
    volumes:
      - /data/es7data1:/usr/share/elasticsearch/data
    ports:
      - 9200:9200
    networks:
      - es7net

networks:
  es7net:
    driver: bridge
```

```bash
$ docker-compose up -d
$ docker ps
CONTAINER ID        IMAGE                    COMMAND                  CREATED             STATUS              PORTS                              NAMES
b291185b6516        elasticsearch:7.2.0      "/usr/local/bin/dock…"   6 minutes ago       Up 4 minutes        0.0.0.0:9200->9200/tcp, 9300/tcp   es7_01
729527faefb0        kibana:7.2.0             "/usr/local/bin/kiba…"   12 minutes ago      Up 4 minutes        0.0.0.0:5601->5601/tcp             kibana7
bd4dbad9737c        lmenezes/cerebro:0.9.2   "/opt/cerebro/bin/ce…"   12 minutes ago      Up 4 minutes        0.0.0.0:9000->9000/tcp             cerebro

```
![在这里插入图片描述](https://img-blog.csdnimg.cn/20201031170125723.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3hpeGloYWhhbGVsZWhlaGU=,size_16,color_FFFFFF,t_70#pic_center)
## 2. 创建两个节点的es集群

```bash
version: '2.2'
services:
  cerebro:
    image: lmenezes/cerebro:0.8.3
    container_name: cerebro
    ports:
      - "9000:9000"
    command:
      - -Dhosts.0.host=http://elasticsearch:9200
    networks:
      - es7net
  kibana:
    image: docker.elastic.co/kibana/kibana:7.1.0
    container_name: kibana7
    environment:
      - I18N_LOCALE=zh-CN
      - XPACK_GRAPH_ENABLED=true
      - TIMELION_ENABLED=true
      - XPACK_MONITORING_COLLECTION_ENABLED="true"
    ports:
      - "5601:5601"
    networks:
      - es7net
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.1.0
    container_name: es7_01
    environment:
      - cluster.name=geektime
      - node.name=es7_01
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - discovery.seed_hosts=es7_01,es7_02
      - cluster.initial_master_nodes=es7_01,es7_02
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es7data1:/usr/share/elasticsearch/data
    ports:
      - 9200:9200
    networks:
      - es7net
  elasticsearch2:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.1.0
    container_name: es7_02
    environment:
      - cluster.name=geektime
      - node.name=es7_02
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - discovery.seed_hosts=es7_01,es7_02
      - cluster.initial_master_nodes=es7_01,es7_02
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es7data2:/usr/share/elasticsearch/data
    networks:
      - es7net


volumes:
  es7data1:
    driver: local
  es7data2:
    driver: local

networks:
  es7net:
    driver: bridge
```

访问`http://ip:9000`

![在这里插入图片描述](https://img-blog.csdnimg.cn/20201101153644984.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3hpeGloYWhhbGVsZWhlaGU=,size_16,color_FFFFFF,t_70#pic_center)

更多阅读：

 - [安装 docker](https://blog.csdn.net/xixihahalelehehe/article/details/104293170)
 - [安装 docker-compose](https://blog.csdn.net/xixihahalelehehe/article/details/108769857)
 - [镜像拉取慢得解决方法](https://blog.csdn.net/xixihahalelehehe/article/details/109404298)

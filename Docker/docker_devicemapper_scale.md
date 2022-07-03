#  docker devicemapper 扩容

查看当前大小: 100G

```bash
$ ls -lh /var/lib/docker/devicemapper/devicemapper/
total 82G
-rw------- 1 root root 100G Dec  4 14:06 data
-rw------- 1 root root 2.0G Dec  4 14:05 metadata
```

扩容到200G

```bash
$ truncate -s 200G /var/lib/docker/devicemapper/devicemapper/data
```

查看扩容后磁盘文件大小(内存中大小暂未改变)

```bash
$  ls -lh /var/lib/docker/devicemapper/devicemapper/
total 82G
-rw------- 1 root root 200G Dec  4 14:07 data
-rw------- 1 root root 2.0G Dec  4 14:07 metadata

reload
```

从命令行调用区块设备控制程序

```bash
$ echo $[ $(sudo blockdev --getsize64 /dev/loop0) / 1024 / 1024 / 1024 ]
100
```

`losetup`用来将loopdevice与档案或blockdevice联结、分离.以及查询loopdevice目前的状况,如只给定loop_device的参数.则秀出loopdevice目前的状况

```bash
$ losetup -c /dev/loop0

$ echo $[ $(sudo blockdev --getsize64 /dev/loop0) / 1024 / 1024 / 1024 ]
200

Reload the devicemapper thin pool
$ dmsetup status | grep ' thin-pool ' | awk -F ': ' {'print $1'}
docker-252:0-5637144768-pool

$ dmsetup table docker-252:0-5637144768-pool
0 209715200 thin-pool 7:1 7:0 128 32768 1 skip_block_zeroing 

$ dmsetup suspend docker-252:0-5637144768-pool

$ dmsetup reload docker-252:0-5637144768-pool --table '0 419430400 thin-pool 7:1 7:0 128 32768 1 skip_block_zeroing'

$ dmsetup resume docker-252:0-5637144768-pool
```

扩容完成查看效果(200G)

```bash
$ docker info
Containers: 21
 Running: 20
 Paused: 0
 Stopped: 1
Images: 118
Server Version: 17.05.0-ce
Storage Driver: devicemapper
 Pool Name: docker-252:0-5637144768-pool
 Pool Blocksize: 65.54kB
 Base Device Size: 64.42GB
 Backing Filesystem: xfs
 Data file: /dev/loop0
 Metadata file: /dev/loop1
 Data Space Used: 87.43GB
 Data Space Total: 214.7GB
 Data Space Available: 127.3GB
 Metadata Space Used: 99.05MB
 Metadata Space Total: 2.147GB
 Metadata Space Available: 2.048GB
 Thin Pool Minimum Free Space: 21.47GB
```

参考：

 - [Use the Device Mapper storage driver](https://docs.docker.com/storage/storagedriver/device-mapper-driver/)
 - [Docker and the Device Mapper storage driver](https://gdevillele.github.io/engine/userguide/storagedriver/device-mapper-driver/)
 - [How Do I Change the Mode of the Docker Device Mapper?](https://support.huaweicloud.com/intl/en-us/ae-ad-1-usermanual-cce/cce_faq_00096.html)

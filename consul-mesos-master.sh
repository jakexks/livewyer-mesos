#!/bin/bash
while true
do
  IP=$(ip route | grep default | cut -d\  -f3)
  STATUSCODE=$(curl -s --output /dev/null --write-out "%{http_code}" $IP:8500/v1/catalog/services)
  ZK=$(curl -s $IP:8500/v1/catalog/service/zookeeper-2181)
  if [ "$STATUSCODE" != "200" ]; then
    echo "curl failed with status code $STATUSCODE, retrying in 5 seconds..."
    sleep 5
  elif [ "$ZK" == "[]" ]; then
    echo "Zookeeper not yet ready, retrying in 5 seconds..."
    sleep 5
  else
    regex="Address\":\"([1-2]?[0-9]?[0-9]\.[1-2]?[0-9]?[0-9]\.[1-2]?[0-9]?[0-9]\.[1-2]?[0-9]?[0-9])\",\""; 
    [[ $ZK =~ $regex ]]
    export ZK=${BASH_REMATCH[1]}
    echo "Zookeeper found at $ZK, starting mesos"
    break
  fi
done
docker -H unix:///docker.sock run --name=mesos_master --privileged --net=host mesosphere/mesos-master:0.20.1 --ip=$ZK --zk=zk://$ZK:2181/mesos --work_dir=/var/lib/mesos/master --quorum=1

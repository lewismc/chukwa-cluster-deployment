# chukwa-cluster-deployment

## Introduction
A small utility project used to deploy [Apache Chukwa](http://chukwa.apache.org) (master branch or most recent stable) 
on to an existing [Hadoop](http://hadoop.apache.org) cluster. It should be noted that this cluster
deployment scenario also works for an [Amazon EMR](https://aws.amazon.com/elasticmapreduce/) deployment.

The project basically enables you to replicate automated software deployment such as what Chef or Puppet would do. 

## Software Versions
 * Both [Apache Hadoop](http://hadoop.apache.org) and [Amazon EMR](https://aws.amazon.com/elasticmapreduce/) v2.4.0
 * [Apache Chukwa](http://chukwa.apache.org) [master branch](https://github.com/apache/chukwa/tree/master) or most stable

## Command Line Usage
```
$ git clone https://github.com/lewismc/chukwa-cluster-deployment.git
$ cd chukwa-cluster-deployment
$ ./chukwa-cluster-deployment.sh
chukwa-cluster-deployment [-m|--master]
	-m|--master	        Optionally checks out Chukwa master branch from the official Apache Git source repository 
                                instead of using most recent stable Chukwa.
	Install Directory	Directory which Chuwka is to be installed in on every node present in machines.txt.
```
 
## Deployment
1. Add the IP of every node within your cluster to machines.txt
2. Run ./chukwa-cluster-deployment.sh -m /path/to/install/directory 

## Deployment Characteristics
For each IP present within machines.txt the deployment script will iterate through each IP and 
execute Chukwa cluster deployment (e.g. an [Agent](http://chukwa.apache.org/docs/r0.6.0/agent.html)) on each node and Agent configuration as per the 
[Chukwa Quickstart Guide](http://chukwa.apache.org/docs/r0.6.0/Quick_Start_Guide.html).

Further to this, Chukwa is pointed at specific logs which it then monitors and pushes into [Apache Solr](http://lucene.apache.org/solr).

From then on, Log Analysis can then be managed through Chukwa.  


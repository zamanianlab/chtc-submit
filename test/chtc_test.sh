#!/bin/bash

# set home () and mk dirs
export HOME=$PWD
#mkdir input work output

# echo core, thread, and memory
echo "CPU threads: $(grep -c processor /proc/cpuinfo)"
grep 'cpu cores' /proc/cpuinfo | uniq
echo $(free -g)

# print a 'hello' message to the job's terminal output:
echo "Hello CHTC from Job $1 running on `whoami`@`hostname`"
#
# keep this job running for a few minutes so you'll see it in the queue:
sleep 180


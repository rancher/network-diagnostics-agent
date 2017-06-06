#!/bin/bash
set -e -o pipefail

info()
{
    echo INFO: "$@"
}

HISTORY_LENGTH=$2

LOGS_DIR=$1
cd ${LOGS_DIR}

rm -rf dump
mkdir -p dump
cd dump


mkdir -p rancher-net rancher-dns network-manager

curl -s -f -H 'Accept: application/json' http://169.254.169.250/2016-07-29 > metadata.json
ps auxwwwf > ps.log
docker ps -a > docker-ps.log
df -h > df.log

HOST_PID=$(docker inspect -f '{{.State.Pid}}' rancher-agent)
RANCHER_NET_PID=$(pidof rancher-net)
DNS_PID=$(pidof rancher-dns)
PM_PID=$(pidof plugin-manager)

if [ -z "${HOST_PID}" ]; then
    > no-host-pid
else
    nsenter -m -u -i -n -p -t ${HOST_PID} -- ip link > ip-link.log 2>&1
    nsenter -m -u -i -n -p -t ${HOST_PID} -- ip addr > ip-addr.log 2>&1
    nsenter -m -u -i -n -p -t ${HOST_PID} -- ip neighbor > ip-neighbor.log 2>&1
    nsenter -m -u -i -n -p -t ${HOST_PID} -- ip route > ip-route.log 2>&1
    nsenter -m -u -i -n -p -t ${HOST_PID} -- conntrack -L > conntrack.log 2>&1
    nsenter -m -u -i -n -p -t ${HOST_PID} -- iptables-save > iptables-save.log 2>&1
    nsenter -m -u -i -n -p -t ${HOST_PID} -- sysctl -a > sysctl-a.log 2>&1 || true
    nsenter -m -u -i -n -p -t ${HOST_PID} -- cat /proc/net/xfrm_stat > xfrm_stat.log 2>&1 || true
    nsenter -m -u -i -n -p -t ${HOST_PID} -- cat /host/etc/resolv.conf > resolv.conf.log 2>&1 || true
    nsenter -m -u -i -n -p -t ${HOST_PID} -- uname -a > uname.log 2>&1
fi

if [ -z "$RANCHER_NET_PID" ]; then
    > no-rancher-net
else
    nsenter -m -u -i -n -p -t ${RANCHER_NET_PID} -- ip link > rancher-net/ip-link.log 2>&1
    nsenter -m -u -i -n -p -t ${RANCHER_NET_PID} -- ip addr > rancher-net/ip-addr.log 2>&1
    nsenter -m -u -i -n -p -t ${RANCHER_NET_PID} -- ip neighbor > rancher-net/ip-neighbor.log 2>&1
    nsenter -m -u -i -n -p -t ${RANCHER_NET_PID} -- ip route > rancher-net/ip-route.log 2>&1
    nsenter -m -u -i -n -p -t ${RANCHER_NET_PID} -- conntrack -L > rancher-net/conntrack.log 2>&1
    nsenter -m -u -i -n -p -t ${RANCHER_NET_PID} -- iptables-save > rancher-net/iptables-save.log 2>&1
    nsenter -m -u -i -n -p -t ${RANCHER_NET_PID} -- sysctl -a > rancher-net/sysctl.log 2>&1
    nsenter -m -u -i -n -p -t ${RANCHER_NET_PID} -- cat /proc/net/xfrm_stat > rancher-net/xfrm_stat.log 2>&1 || true
    nsenter -m -u -i -n -p -t ${RANCHER_NET_PID} -- cat /etc/resolv.conf > rancher-net/resolv.conf.log 2>&1 || true
    nsenter -m -u -i -n -p -t ${RANCHER_NET_PID} -- swanctl --list-conn > rancher-net/swanctl-list-conn.log 2>&1 || true
    nsenter -m -u -i -n -p -t ${RANCHER_NET_PID} -- swanctl --list-sas > rancher-net/swanctl-list-sas.log 2>&1 || true
    nsenter -m -u -i -n -p -t ${RANCHER_NET_PID} -- ip xfrm policy > rancher-net/ip-xfrm-policy.log 2>&1 || true
    nsenter -m -u -i -n -p -t ${RANCHER_NET_PID} -- ip xfrm state > rancher-net/ip-xfrm-state.log 2>&1 || true
fi

if [ -z "${DNS_PID}" ]; then
    > no-rancher-dns
else
    nsenter -m -u -i -n -p -t ${DNS_PID} -- ip link > rancher-dns/ip-link.log 2>&1
    nsenter -m -u -i -n -p -t ${DNS_PID} -- ip addr > rancher-dns/ip-addr.log 2>&1
    nsenter -m -u -i -n -p -t ${DNS_PID} -- ip neighbor > rancher-dns/ip-neighbor.log 2>&1
    nsenter -m -u -i -n -p -t ${DNS_PID} -- ip route > rancher-dns/ip-route.log 2>&1
    nsenter -m -u -i -n -p -t ${DNS_PID} -- cat /etc/resolv.conf > rancher-dns/resolv.conf.log 2>&1 || true
fi

if [ -z "${PM_PID}" ]; then
    > no-network-manager
else
    nsenter -m -u -i -n -p -t ${PM_PID} -- cat /etc/resolv.conf > network-manager/resolv.conf.log 2>&1 || true
fi

cd ..

CUR_TMP_DIR="dump.$(date -u +%Y-%m-%dT%H-%M-%SZ).$(date +%s%N)"
mv dump $CUR_TMP_DIR
tar cjf ${CUR_TMP_DIR}.tar.bz2 $CUR_TMP_DIR
rm -rf $CUR_TMP_DIR
TO_DELETE=$(ls -1t | sed '1,'${HISTORY_LENGTH}'d')
if [ -n "$TO_DELETE" ]; then
    rm -rf $TO_DELETE
fi

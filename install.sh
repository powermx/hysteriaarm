#!/bin/bash

rm -rf $(pwd)/$0

read -p " ingresa tu dominio: " domain

apt update -y; apt upgrade -y; apt install git -y

git clone https://github.com/powermx/hysteriaarm.git

dir=$(pwd)

OBFS=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 8)

interfas=$(ip -4 route ls|grep default|grep -Po '(?<=dev )(\S+)'|head -1)

sys=$(which sysctl)

ip4t=$(which iptables)
ip6t=$(which ip6tables)

openssl genrsa -out ${dir}/hysteriaarm/udpmod.ca.key 2048
openssl req -new -x509 -days 3650 -key ${dir}/hysteriaarm/udpmod.ca.key -subj "/C=CN/ST=GD/L=SZ/O=Udpmod, Inc./CN=Udpmod Root CA" -out ${dir}/hysteriaarm/udpmod.ca.crt
openssl req -newkey rsa:2048 -nodes -keyout ${dir}/hysteriaarm/udpmod.server.key -subj "/C=CN/ST=GD/L=SZ/O=Udpmod, Inc./CN=${domain}" -out ${dir}/hysteriaarm/udpmod.server.csr
openssl x509 -req -extfile <(printf "subjectAltName=DNS:${domain},DNS:${domain}") -days 3650 -in ${dir}/hysteriaarm/udpmod.server.csr -CA ${dir}/hysteriaarm/udpmod.ca.crt -CAkey ${dir}/hysteriaarm/udpmod.ca.key -CAcreateserial -out ${dir}/hysteriaarm/udpmod.server.crt

sed -i "s/setobfs/${OBFS}/" ${dir}/hysteriaarm/config.json
sed -i "s#instDir#${dir}#g" ${dir}/hysteriaarm/config.json
sed -i "s#instDir#${dir}#g" ${dir}/hysteriaarm/hysteriaarm.service
sed -i "s#iptb#${interfas}#g" ${dir}/hysteriaarm/hysteriaarm.service
sed -i "s#sysb#${sys}#g" ${dir}/hysteriaarm/hysteriaarm.service
sed -i "s#ip4tbin#${ip4t}#g" ${dir}/hysteriaarm/hysteriaarm.service
sed -i "s#ip6tbin#${ip6t}#g" ${dir}/hysteriaarm/hysteriaarm.service

chmod +x ${dir}/hysteriaarm/*

install -Dm644 ${dir}/hysteriaarm/udpmod.service /etc/systemd/system

systemctl daemon-reload
systemctl start udpmod
systemctl enable udpmod

echo " obfs: ${OBFS}" > ${dir}/hysteriaarm/data
echo "port: 36712" >> ${dir}/hysteriaarm/data
echo "rago de puertos: 10000:65000" >> ${dir}/hysteriaarm/data
cat ${dir}/hysteriaarm/data

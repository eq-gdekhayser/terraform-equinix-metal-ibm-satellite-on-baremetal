#!/bin/bash

#register node with RH subscription
subscription-manager register --username gdekhayser_p --password Voyant1500! --auto-attach

#enable repos
subscription-manager repos --enable rhel-server-rhscl-7-rpms
subscription-manager repos --enable rhel-7-server-optional-rpms
subscription-manager repos --enable rhel-7-server-rh-common-rpms
subscription-manager repos --enable rhel-7-server-supplementary-rpms
subscription-manager repos --enable rhel-7-server-extras-rpms

yum-config-manager --save --setopt=docker-ce-stable.skip_if_unavailable=true > /tmp/yum-config-manager-output.log

curl -sL https://raw.githubusercontent.com/IBM-Cloud/ibm-cloud-developer-tools/master/linux-installer/idt-installer | bash



ibmcloud plugin install container-service -f
ibmcloud plugin install container-registry -f
ibmcloud plugin install observe-service -f

ibmcloud sat host attach --location eq-satellite-poc -hl use=satellite-poc


mv /tmp/reg* /tmp/attach.sh

sudo nohup bash /tmp/attach.sh &


---PREP VLAN---

modprobe 8021q
echo "8021q" >> /etc/modules-load.d/networking.conf
ip link add link bond0 name bond0.1000 type vlan id 1000

ip addr add 192.168.0.4/24 brd 192.168.0.255 dev bond0.1000
ip link set dev bond0.1000 up

--ifcfg-bond0.VLAN--

DEVICE=bond0.1000NAME=bond0.1000ONPARENT=yesIPADDR=192.168.0.4NETMASK=255.255.255.0GATEWAY=192.168.0.1VLAN=yesBOOTPROTO=noneONBOOT=yesUSERCTL=no




image-registry.openshift-image-registry.svc


oc patch configs.imageregistry.operator.openshift.io/cluster --type merge -p '{"spec":{"defaultRoute":true}}'
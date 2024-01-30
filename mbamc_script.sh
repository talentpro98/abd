#!/bin/bash


# Getting information
echo -e "[*] Get OS version release...:" 
head -n 100000 /etc/*-release

echo -e "\n\n\n\n[*] Get system date...:"
date 

echo -e "\n\n\n\n[*] Get NTP/Chrony status...:"
echo -e "[+] NTP config file:"
cat /etc/ntp.conf

echo -e "\n\n[+] Chrony config file:"
cat /etc/chrony.conf

echo -e "\n\n\n\n[*] Check internet connection..."
curl -I https://www.google.com.vn


echo -e "\n\n\n\n[*] Get yum/apt configuration..."
echo -e "\n\n[+] yum config files:"
head -n 100000 /etc/yum/*
echo -e "\n\n[+] apt config files:"
head -n 100000 /etc/apt/*

echo -e "\n\n\n\n[*] Get iptables rules..."
iptables -L

echo -E "\n\n\n\n[*] Get services running..."
systemctl list-units --state=running

echo -e "\n\n\n\n[*] Rsyslog config file..."
head -n 100000 /etc/rsyslog.conf /etc/rsyslog.d/*

echo -e "\n\n\n\n[*] /var/log/ files permissions..."
ls -la /var/log/*

echo -e "\n\n\n\n[*] Get logrotate config..."
head -n 100000 /etc/logrotate.conf /etc/logrotate.d/*

echo -e "\n\n\n\n[*] Get sudo package info..."
rpm -q sudo

echo -e "\n\n\n\n[*] Get sudoers config ..."
head -n 100000 /etc/sudoers /etc/sudoers.d/*

echo -e "\n\n\n\n[*] Get environment config..."
echo -e "[+] Get env variables:"
env
echo -e "\n\n[+] Get content of files /etc/profile, /etc/profile.d/*, /etc/bashrc"
head -n 100000 /etc/profile /etc/profile.d/* /etc/bashrc


echo -e "\n\n\n\n[*] Get content of /etc/pam.d/su..."
cat /etc/pam.d/su

echo -e "\n\n\n\n[*] Get content of /etc/group..."
cat /etc/group

echo -e "\n\n\n\n[*] Get users's last login: "
lastlog

echo -e "\n\n\n\n[*] Get content of /etc/passwd..."
cat /etc/passwd

echo -e "\n\n\n\n[*] Get sshd config..."
sshd -T

echo -e "\n\n\n\n[*] Get /etc/security/pwquality.conf..."
cat /etc/security/pwquality.conf 


echo -e "\n\n\n\n[*] Get files from /etc/pam.d/* ..."
head -n 100000 /etc/pam.d/*

echo -e "\n\n\n\n[*] Get /etc/shadow..."
cat /etc/shadow

echo -e "\n\n\n\n[*] Get /etc/login.defs..."
cat /etc/login.defs


echo -e "\n\n\n\n[*] Get file permissions..."
stat -c %a:%U:%G:%N /etc/crontab /etc/cron.* /etc/cron.d/*
stat -c %a:%U:%G:%N /etc/passwd /etc/passwd- /etc/shadow /etc/shadow- /etc/gshadow /etc/gshadow- /etc/group /etc/group-

echo -e "\n\n\n\n[*] Get kernel config..."
sysctl -a


echo -E "\n\n\n\n[*] Get /etc/modprobe.d/ files..."
head -n 100000 /etc/modprobe.d/*

lsblk


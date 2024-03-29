#!/bin/bash

wget https://sourceforge.net/projects/sshpass/files/latest/download/sshpass/1.08/sshpass-1.08.tar.gz 1>/dev/null 2>&1
tar zxvf sshpass-1.08.tar.gz 1>/dev/null 2>&1
cd sshpass-*/ 1>/dev/null 2>&1
./configure 1>/dev/null 2>&1
make 1>/dev/null 2>&1
cp sshpass ../ 1>/dev/null 2>&1
cd .. 1>/dev/null 2>&1
rm -rf sshpass-* 1>/dev/null 2>&1

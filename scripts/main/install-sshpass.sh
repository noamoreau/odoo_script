#!/bin/bash

wget https://sourceforge.net/projects/sshpass/files/latest/download/sshpass/1.08/sshpass-1.08.tar.gz
tar zxvf sshpass-1.08.tar.gz
cd sshpass-*/
./configure
make
cp sshpass ../
cd ..
rm -rf sshpass-*

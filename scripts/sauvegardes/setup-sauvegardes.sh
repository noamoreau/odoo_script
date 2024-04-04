#!/bin/bash

ssh sauvegardes1 "su --login -c 'apt-get install rsync"
ssh sauvegardes1 "sudo -S ssh-keygen"
ssh sauvegardes1 "sudo -S ssh-copy-id postgres@10.42.124.2"

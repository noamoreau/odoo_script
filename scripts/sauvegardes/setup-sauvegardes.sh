#!/usr/bin/env bash
scp sshpass sauvegardes1:.
ssh sauvegardes1 'echo user|sudo -S apt install rsync'
ssh sauvegardes1 'ssh-keygen'
ssh sauvegardes1 './sshpass -p postgres ssh-copy-id postgres@10.42.124.2'
#!/bin/bash

esc='\e'
rouge_fonce=${esc}'[91m'
bleu_clair=${esc}'[94m'
jaune_clair=${esc}'[33m'
reset=${esc}'[0m'

echo -e "${bleu_clair}Configuration de sauvegardes1...${reset}"

scp sshpass sauvegardes1:. 1>/dev/null 2>&1
ssh sauvegardes1 'echo user|sudo -S apt install rsync' 1>/dev/null 2>&1
ssh sauvegardes1 'ssh-keygen -f /home/user/.ssh/id_rsa  -N "" ' 1>/dev/null 2>&1
ssh sauvegardes1 './sshpass -p postgres ssh-copy-id postgres@10.42.162.2'  1>/dev/null 2>&1

echo -e "${bleu_clair}Configuration de sauvegardes terminée${reset}" 
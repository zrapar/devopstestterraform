#!/bin/bash
chmod 400 files/Devops.pem
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i files/Devops.pem files/ssh-key.pem __USER_HOST__@__JUMPSERVER_IP__:/home/__USER_HOST__/ssh-key.pem
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i files/Devops.pem __USER_HOST__@__JUMPSERVER_IP__ "chmod 400 /home/__USER_HOST__/ssh-key.pem"

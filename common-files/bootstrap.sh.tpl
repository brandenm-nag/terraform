#!/bin/bash

date

${custom_block}

cat > /root/citc_authorized_keys <<EOF
${citc_keys}
EOF

yum install -y ansible git
cat > /root/hosts <<EOF
[management]
$(hostname -f)
EOF

mkdir /etc/ansible/facts.d/
echo "{\"csp\":\"${cloud-platform}\", \"fileserver_ip\":\"${fileserver-ip}\", \"mgmt_hostname\":\"${mgmt_hostname}\"}" > /etc/ansible/facts.d/citc.fact

PYTHON=$(command -v python || command -v python3)
$PYTHON -u /usr/bin/ansible-pull --url=${ansible_repo} --checkout=${ansible_branch} --inventory=/root/hosts management.yml >> /root/ansible-pull.log
res=$?
echo "ansible returned [$res]" >> /root/ansible-pull.log
exec > /tmp/mylog 2>&1
set -x
if [[ "$res" == 0 ]]; then
    /mnt/shared/sbin/run_command --token=${token} sync
    /mnt/shared/bin/update_service_db --token=${token} cluster --status='r'
else
    # If ansible failed, update_service_db will still be in /tmp
    /tmp/cluster_control/update_service_db --token=${token} cluster --status='e'
fi

date

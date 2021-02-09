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
time $PYTHON -u /usr/bin/ansible-pull --url=${ansible_repo} --checkout=${ansible_branch} --inventory=/root/hosts management.yml >> /root/ansible-pull.log || /tmp/update_service_db cluster --status=e

date

#!/bin/bash
set -e

# Install an outdated MongoDB release (4.4 line — EOL, 1+ year old) per exercise requirement
cat <<REPOEOF > /etc/apt/sources.list.d/mongodb-org-4.4.list
deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse
REPOEOF

apt-get update -y
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -
apt-get update -y
apt-get install -y mongodb-org=4.4.* mongodb-org-server=4.4.* mongodb-org-shell=4.4.* mongodb-org-mongos=4.4.* mongodb-org-tools=4.4.* awscli

# Listen on all interfaces; the security group is what restricts source IPs
sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf
cat <<CONFEOF >> /etc/mongod.conf
security:
  authorization: enabled
CONFEOF

systemctl enable mongod
systemctl start mongod
sleep 10

# Create the application DB user (rotate this password before using outside the lab)
mongo <<MONGOEOF
use admin
db.createUser({ user: "appuser", pwd: "CHANGE_ME_BEFORE_USE", roles: [ { role: "readWrite", db: "tododb" } ] })
MONGOEOF

# Daily backup script -> public S3 bucket, per exercise requirement
cat <<'SCRIPTEOF' > /usr/local/bin/mongo-backup.sh
#!/bin/bash
set -e
TS=$(date +%Y%m%d-%H%M%S)
mongodump --out /tmp/mongodump-$${TS}
tar -czf /tmp/mongodump-$${TS}.tar.gz -C /tmp mongodump-$${TS}
aws s3 cp /tmp/mongodump-$${TS}.tar.gz s3://${backup_bucket}/backups/mongodump-$${TS}.tar.gz
rm -rf /tmp/mongodump-$${TS} /tmp/mongodump-$${TS}.tar.gz
SCRIPTEOF
chmod +x /usr/local/bin/mongo-backup.sh

echo "0 2 * * * root /usr/local/bin/mongo-backup.sh" > /etc/cron.d/mongo-backup

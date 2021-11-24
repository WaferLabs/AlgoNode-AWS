#!/bin/bash

#### Install Tools
#### ============================================
apt-get update
apt-get install -y gnupg2 curl software-properties-common htop jq xfsprogs

#### Parse User Data
#### ============================================
user_data=$(curl -s -f  http://169.254.169.254/latest/user-data || echo '{ "type": "fastcatchup", "chain": "mainnet", "algoDir": "/var/lib/algorand", "ebsVolumeID": "", "indexer": false, "indexerPostgres": "", "indexerOptions": ""}')
eval "$( echo $user_data | jq -r 'to_entries | .[] | .key + "=" + (.value | @sh)')"

#### Export Env Variables
#### ============================================
aws_region=$(curl -s 169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//')
instance_id=$(curl -s 169.254.169.254/latest/meta-data/instance-id)
printf "export CHAIN=$chain
export ALGORAND_DATA=$algoDir
export AWS_DEFAULT_REGION=$aws_region
export INSTANCE_ID=$instance_id
" > /etc/profile.d/algoenv.sh

export CHAIN=$chain
export ALGORAND_DATA=$algoDir
export AWS_DEFAULT_REGION=$aws_region
export INSTANCE_ID=$instance_id


curl -O https://releases.algorand.com/key.pub
apt-key add key.pub

#### Install Algorand + Devtools + Indexer
#### ============================================
if [ $chain == "betanet" ]; then
    add-apt-repository "deb [arch=amd64] https://releases.algorand.com/deb/ beta main"
    apt-get update
    apt-get install -y algorand-beta algorand-devtools-beta
else
    add-apt-repository "deb [arch=amd64] https://releases.algorand.com/deb/ stable main"
    apt-get update
fi

wget -q http://algorand-dev-deb-repo.s3-website-us-east-1.amazonaws.com/releases/indexer/f9e6a6841_2.6.5/algorand-indexer_2.6.5_amd64.deb
dpkg -i -E algorand-indexer_2.6.5_amd64.deb

systemctl stop algorand.service
systemctl stop algorand-indexer.service

#### Configure Filesystem
#### ============================================
# Are we using default directory or a custom directory?
if [ $algoDir != "/var/lib/algorand" ]; then
    mkdir -p $algoDir

    # Check if this is run again on reboot or if I need to run it again <--------
    # Are we using a custom EBS volume?
    if [ $ebsVolumeID != "" ]; then
        aws ec2 attach-volume --volume-id $ebsVolumeID --instance-id $INSTANCE_ID --device /dev/sdk
        sleep 10

        mount /dev/nvme1n1 $algoDir
        if [ $? -ne 0 ]; then
            mkfs -t ext4 /dev/nvme1n1
            mount /dev/nvme1n1 $algoDir
        fi
    fi
fi

#### Configure Algorand Chain + Service
#### ============================================
if [ ! -f $algoDir/genesis.json ]; then
    cp -p /var/lib/algorand/genesis/$chain/genesis.json $algoDir/genesis.json
    cp -p /var/lib/algorand/system.json $algoDir/system.json
fi

chown -R algorand:algorand $algoDir

printf "[Unit]
Description=Algorand daemon for $chain in $algoDir
After=network.target

[Service]
ExecStart=/usr/bin/algod -d $algoDir
PIDFile=$algoDir/algod.pid
User=algorand
Group=algorand
Restart=always
RestartSec=5s
ProtectSystem=full
ProtectHome=true

[Install]
WantedBy=multi-user.target" > /lib/systemd/system/algorand.service
systemctl daemon-reload

#### Configure Algorand Node
#### ============================================
if [ $type == "fastcatchup" ]; then
    systemctl start algorand.service
    goal node catchup $(curl -s https://algorand-catchpoints.s3.us-east-2.amazonaws.com/channel/$chain/latest.catchpoint) -d $algoDir
elif [ $type == "archival" ]; then
    if [ ! -f $algoDir/config.json ]; then
        printf '{
            "Archival": true
        }' > $algoDir/config.json
        chown algorand:algorand $algoDir/config.json
    fi
    systemctl start algorand.service
else
    if [ ! -f $algoDir/config.json ]; then
        printf '{
            "NetAddress": ":4161"
        }' > $algoDir/config.json
        chown algorand:algorand $algoDir/config.json
    fi

    if [ ! -f $algoDir/phonebook.json ]; then
        if [ $chain == "mainnet" ]; then
            mv /tmp/AlgoNode-AWS/mainnet_phonebook.json $algoDir/phonebook.json
        elif [ $chain == "betanet" ]; then
            mv /tmp/AlgoNode-AWS/betanet_phonebook.json $algoDir/phonebook.json
        fi

        chown algorand:algorand $algoDir/phonebook.json
    fi

    systemctl start algorand.service
fi


#### Configure Indexer
#### ============================================
if [ $indexer == true ]; then
    printf "[Unit]
Description=Algorand Indexer daemon
After=network.target

[Service]
ExecStart=/usr/bin/algorand-indexer daemon --pidfile $algoDir/algorand-indexer.pid --algod $algoDir --postgres \"$indexerPostgres\" $indexerOptions
PIDFile=$algoDir/algorand-indexer.pid
User=algorand
Group=algorand
Restart=always
RestartSec=5s
ProtectSystem=full
ProtectHome=true

[Install]
WantedBy=multi-user.target" > /lib/systemd/system/algorand-indexer.service
    systemctl daemon-reload
    systemctl enable algorand-indexer
    systemctl start algorand-indexer.service
fi

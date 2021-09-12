# AlgoNode AWS
This repo contains the source files for the latest AMI (Amazon Machine Image) Algorand Node build. It is updated frequently to reflect the latest releases of the indexer and algod node. You can view our AWS Marketplace page here: LINK_HERE

The AMI when launched on AWS is configured to clone this repo during startup and run the [setup.sh](setup.sh) script which will setup the node as defined by the [configuration file](#configuration-file). For more information on how to get started with an Algorand Node on AWS, please read the following guide: LINK_HERE

Below you will find additional information regarding proper node configuration as well as optimal hardware provisioning based on use case.

## Configuration File
The most crucial aspect to successfully deploying a node on AWS is by properly defining the config file. The config file is a JSON file uploaded as user data during the EC2 creation process. It is an object with the following key/value pairs:

1. **type**: Defines the type of node. Options: _fastcatchup_, _archival_, _relay_
2. **chain**: Chain to run the node on. Options: _mainnet_, _testnet_, _betanet_
3. **algoDir**: Directory to run the algod node in. Default directory is: _/var/lib/algorand_
4. **ebsVolumeID**: EBS Volume ID that will be used to store the node data/run the node off of. The volume id specified in this option will be mounted at the mountpoint specified by `algoDir`. A custom directory other than _/var/lib/algorand_ must be specified in order to use `ebsVolumeID`
5. **indexer**: _true_ or _false_ value to install/use the indexer
6. **indexerPostgres**: Postgres connection string to pass onto the indexer. Can be left blank if `indexer` is _false_
7. **indexerOptions**: Additional options to pass to the indexer daemon. Can be left blank.

###### **Note**: All options MUST be specified in the config file, even if they aren't used.  
\
Here are some examples of configuration files that may be used to deploy an Algorand Node.

### Mainnet Fastcatchup Node
In this scenario, the goal is to deploy a fastcatchup node to AWS. The most common use case for this is usually to particpate in consensus. Here is an example of what the JSON config might look like:

```json
{
    "type": "fastcatchup",
    "chain": "mainnet",
    "algoDir": "/var/lib/algorand",
    "ebsVolumeID": "",
    "indexer": false,
    "indexerPostgres": "",
    "indexerOptions": ""
}
```
Since this is fastcatchup, there is no need to use the indexer or a custom EBS volume since the default volume bundled with the EC2 Instance is usally more than enough. The node data is stored in the default directory: `/var/lib/algorand`.

### Testnet Archival Node w/ Indexer
In this scenario, the goal is to deploy an Archival node on Testnet with an Indexer. The most common use case for this usually development purposes. Here is an example of what the JSON config might look like:

```json
{
    "type": "archival",
    "chain": "testnet",
    "algoDir": "/testnet",
    "ebsVolumeID": "vol-11d9g038gg91f9410",
    "indexer": true,
    "indexerPostgres": "host=indexer-database.somepostgresdb.com user=postgres password=notarealpassword dbname=customdbname",
    "indexerOptions": ""
}
```
Since this is archival, it is recommended to use an external EBS volume to store node data. The volume is mounted in the `/testnet` directory. The indexer is set to `true` and a custom Postgres connection string is specified so that our indexer can connect to the database. 

## Hardware Recommendations
The hardware recommendations listed here are based off my own personal experience running nodes on AWS and may not accurately reflect your particular use case. It is recommended to utilize this list as a jumping off point rather than the final set of requirements.

The published AMI and subsequent node configuration specified here is primarily intended to be used on ARM based EC2 Instances. While Algorand supports both x86/x64 and ARM architectures, I have personally found additional cost savings by as much as 35% using ARM over x86/x64 on AWS.

### Fastcatchup Node
- **t4g.micro** - This EC2 instance is recommended for running a fastcatchup node. Fastcatchup nodes are relatively light in workload and don't require any external resources. The default 8GB volume that comes attached to the instance should be enough.

For additional information regarding fastcatchup nodes, consult the section under Node Requirements here: https://algorand.foundation/algorand-protocol/network

### Archival Node w/ Indexer
The resource requirements for this node changes depending on whether the node is catching up to the latest block or all caught up. Catchup is more resource intensive as the node attempts to validate every block on the blockchain. Catchup times will vary based on the chain you are targeting.

- **c6g.large** - This compute optimized EC2 instance is recommended during catchup
- **t4g.micro** - This EC2 instance is recommended after the node is fully caught up.
- **EBS Volume** - It recommended to separately provision an EBS Volume to store archival node data. For relative sizes of the volume, please consult: https://howbigisalgorand.com/

### Relay Node
Relay nodes are the most intensive node operation as they serve as network hubs and maintain connections to many other nodes. 

- **c6g.2xlarge** - This compute optimized instance is the **minimum** required instance for running a relay node. Better performance may be obtained on larger instance types
- **EBS Volume** - It is recommended to separately provision an EBS Volume for your relaqy node. The recommended size is 1TB.

For additional information regarding relay node hardware requirements, consult the following document: https://algorand.foundation/news/community-relay-node-running-pilot

## Feedback
For any feedback or issues regarding the AWS Algorand Node, please open up a github issue here: https://github.com/WaferFinance/AlgoNode-AWS/issues

## License
This project is released under the [MIT License](LICENSE)
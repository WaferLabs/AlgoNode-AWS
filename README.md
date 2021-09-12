# AlgoNode AWS
---
This repo contains the source files for the latest AMI (Amazon Machine Image) Algorand Node build. It is updated frequently to reflect the latest releases of the indexer and algod node. You can view our AWS Marketplace page here: LINK_HERE

The AMI when launched on AWS is configured to clone this repo during startup and run the [setup.sh](LINK_HERE) script which will setup the node as defined by the [configuration file](LINK_HERE). For more information on how to get started with an Algorand Node on AWS, we recommend reading the following guide: LINK_HERE

Below we will go into some detail regarding configuring your node as well as optimal hardware provisioning based on your use case.

## Configuration File
---
The most crucial aspect to sucessfully deploying a node on AWS is by properly defining the config file. The config file is a JSON file uploaded as user data during the EC2 creation process. It is an object with the following key configurations:

1. **type**: Defines the type of node. Options: _fastcatchup_, _archival_, _relay_
2. **chain**: Chain to run the node on. Options: _mainnet_, _testnet_, _betanet_
3. **algoDir**: Directory to run the algod node in. Default directory is: _/var/lib/algorand_
4. **ebsVolumeID**: EBS Volume ID that will be used to store the node data/run the node off of. The volume id specified in this option will be mounted at the mountpoint specified by `algoDir`. You must specify a custom directory other than _/var/lib/algorand_ in order to use `ebsVolumeID`
5. **indexer**: _true_ or _false_ value to install/use the indexer
6. **indexerPostgres**: Postgres connection string to pass onto the indexer. Can be left blank if `indexer` is _false_
7. **indexerOptions**: Additional options to pass to the indexer daemon. Can be left blank.

###### **Note**: All options MUST be specified in the config file, even if they aren't used.  
\
Here are some examples of configuration files you may want to use to deploy your Algorand Node.

##### Mainnet Fastcatchup Node
In this scenario, you may want to deploy a fastcatchup node to AWS. The most common use case for this is usually to particpate in consensus. Here is an example of what the JSON config might look like:

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
Since this is fastcatchup, there is no need to use the indexer or a custom EBS volume since the default volume bundled with the EC2 Instance should be more than enough. This will all be stored in the default Algorand Node Directory: `/var/lib/algorand`.

##### Testnet Archival Node w/ Indexer
In this scenario, we are deploying an Archival node on Testnet with an Indexer. The most common use case for this usually development purposes. Here is an example of what the JSON config might look like:

```json
{
    "type": "archival",
    "chain": "testnet",
    "algoDir": "/testnet",
    "ebsVolumeID": "vol-11d9g038gg91f9410",
    "indexer": true,
    "indexerPostgres": "host=indexer-database.somepostgresdb.com user=postgres password=notarealpassword dbname=mainnet",
    "indexerOptions": ""
}
```
Since this is archival, we are using a custom external EBS volume due to the lack of space available to use locally on the disk and are mounting it at the `/testnet` directory where the node will run from and save data to. We've set indexer to `true` and specified a custom Postgres connection string so that our indexer can connect to our database and store data. 

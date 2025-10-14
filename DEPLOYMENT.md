# DEPLOYMENT REFERENCES

## ETHEREUM SEPOLIA

### Contract Addresses

| Contract               | Contract Address                                                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| EDEN Multisig          | [`0x3139DB2845810C4DE0727A5D5Aa24146C086eE1A`](https://sepolia.etherscan.io/address/0x3139DB2845810C4DE0727A5D5Aa24146C086eE1A) |
| SPIRIT Token           | [`0xC280291AD69712e3dbD39965A90BAff1683D2De5`](https://sepolia.etherscan.io/address/0xC280291AD69712e3dbD39965A90BAff1683D2De5) |
| Reward Controller      | [`0xdd27Ce16F1B59818c6A4C428F8BDD5d3BA652539`](https://sepolia.etherscan.io/address/0xbb44C68248fB1E108B8aaaBfA02AdE1a387c50fC) |
| Staking Pool (Beacon)  | [`0xF66A9999ea07825232CeEa4F75711715934333D1`](https://sepolia.etherscan.io/address/0x5a0AE4D855Fb94709032a86c0af3a42cEC855fA2) |
| Eden Factory           | [`0x28F0BC53b52208c8286A4C663680C2eD99d18982`](https://sepolia.etherscan.io/address/0x64B6A29edC6cacF9568332E302D293A562c2fb8F) |
| Spirit Vesting Factory | [`0x511cE8Dd17dAa368bEBF7E21CC4E00E1a9510319`](https://sepolia.etherscan.io/address/0x81876c0f41D43CdfA9D9bee7AF037d3e41aD9FAD) |

### Logs

```shell
forge script script/Deploy.s.sol:DeployEden --rpc-url $ETH_SEPOLIA_RPC_URL --account TESTNET_DEPLOYER --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY

[⠊] Compiling...
No files changed, compilation skipped
Enter keystore password:
Script ran successfully.

== Logs ==

  ===> DEPLOYMENT CONFIGURATION
   --- Admin address                 : 0x5D6D8518A1d564c85ea5c41d1dc0deca70F2301C
   --- Treasury address              : 0x5D6D8518A1d564c85ea5c41d1dc0deca70F2301C
   --- Distributor address           : 0x5D6D8518A1d564c85ea5c41d1dc0deca70F2301C
   --- Super Token Factory           : 0x254C2e152E8602839D288A7bccdf3d0974597193
   --- UniswapV4 Position Manager    : 0x429ba70129df741B2Ca2a85BC3A2a3328e5c09b4
   --- UniswapV4 Pool Manager        : 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543
   --- Permit2 address               : 0x000000000022D473030F116dDEE9F6B43aC78BA3
   --- Spirit Token Name             : Secret Token V3
   --- Spirit Token Symbol           : SECRETv3
   --- Spirit Token Supply           : 1000000000
   --- SPIRIT/ETH Initial Tick       : 184200
   --- SPIRIT/ETH Tick Spacing       : 200
   --- SPIRIT/ETH Pool Fee           : 10000

  ===> DEPLOYING EDEN PROTOCOL
   --- Chain ID          :    11155111
   --- Deployer address  :    0x48CA32c738DC2Af6cE8bB33934fF1b59cF8B1831
   --- Deployer balance  :    6 ETH

  ===> DEPLOYMENT RESULTS
   --- Spirit Token              : 0xC280291AD69712e3dbD39965A90BAff1683D2De5
   --- Reward Controller         : 0xdd27Ce16F1B59818c6A4C428F8BDD5d3BA652539
   --- Staking Pool              : 0xF66A9999ea07825232CeEa4F75711715934333D1
   --- Eden Factory              : 0x28F0BC53b52208c8286A4C663680C2eD99d18982
   --- Spirit Vesting Factory    : 0x511cE8Dd17dAa368bEBF7E21CC4E00E1a9510319


## Setting up 1 EVM.

==========================

Chain 11155111

Estimated gas price: 0.001000035 gwei

Estimated total gas used for script: 11222830

Estimated amount required: 0.00001122322279905 ETH

==========================

##### sepolia
✅  [Success] Hash: 0x7ef6c3f4be10fa794c3d42b8f5852337317259606aa519084b8e9208f52323c1
Contract Address: 0x511cE8Dd17dAa368bEBF7E21CC4E00E1a9510319
Block: 9403694
Paid: 0.000001350106701694 ETH (1350077 gas * 0.001000022 gwei)


##### sepolia
✅  [Success] Hash: 0x37d93e746e318a418b90966966e14a756edbf5efcaea9ecde64eeb4280b1e826
Block: 9403694
Paid: 0.000000200856418744 ETH (200852 gas * 0.001000022 gwei)


##### sepolia
✅  [Success] Hash: 0x579b53e119210442dae3d94ef933c18982ae45b947e09bdde2b689b242cfc177
Block: 9403694
Paid: 0.00000026586584892 ETH (265860 gas * 0.001000022 gwei)


##### sepolia
✅  [Success] Hash: 0x86e42431f87e4b1e33b19925e029182a7ae9b4021ce6e43e8360738684b22c38
Block: 9403694
Paid: 0.0000000476510483 ETH (47650 gas * 0.001000022 gwei)


##### sepolia
✅  [Success] Hash: 0x5f12004c82d9cf8537b01fad3e035faa4607c6490f7af0876b96fac750b59480
Contract Address: 0x16B7eF65EAC5BC029D40888aa1429a40D3Fa71d4
Block: 9403694
Paid: 0.00000075994171835 ETH (759925 gas * 0.001000022 gwei)


##### sepolia
✅  [Success] Hash: 0xe9ddd99399f71bfa34d7c98a13f674bb1e342b1f08163d7218bcdbbc2e66c142
Contract Address: 0xB1fB88c5789a1104DDbcfe6Cb3F38baf774917d0
Block: 9403694
Paid: 0.000000319888037382 ETH (319881 gas * 0.001000022 gwei)


##### sepolia
✅  [Success] Hash: 0x306d86e7374625ccbd3a3240cf93982fc2f4fe73a15b74b5defe5c2a8e5c621f
Block: 9403694
Paid: 0.000000056312238842 ETH (56311 gas * 0.001000022 gwei)


##### sepolia
✅  [Success] Hash: 0xe015dc6448a7380b74cacf64861fe85a6a291992db9dd072dad694ca7a17e293
Block: 9403694
Paid: 0.000000677860912612 ETH (677846 gas * 0.001000022 gwei)


##### sepolia
✅  [Success] Hash: 0x347035ef6791a169c43a26c74ab3c76045783b5ab8677660569793ede049f53b
Contract Address: 0xC280291AD69712e3dbD39965A90BAff1683D2De5
Block: 9403694
Paid: 0.00000033313732886 ETH (333130 gas * 0.001000022 gwei)


##### sepolia
✅  [Success] Hash: 0x722b47c5e1f3e58a543aa74bde371f33744f565a9807e0b520fcb6d6f2b788d6
Block: 9403694
Paid: 0.000000051279128116 ETH (51278 gas * 0.001000022 gwei)


##### sepolia
✅  [Success] Hash: 0x5dee704164928657221092ebdff84a6b725acc47f9415f48e3dc6fc375a0c5ca
Contract Address: 0xdd27Ce16F1B59818c6A4C428F8BDD5d3BA652539
Block: 9403694
Paid: 0.000000227718009686 ETH (227713 gas * 0.001000022 gwei)


##### sepolia
✅  [Success] Hash: 0xd888cf4bad84cc2d8917b9d9975fcf6ad2066297a4ab442d74aa9d97ff8b14c8
Contract Address: 0xf1C86D91DA80b3a860CFe5Ee967f2be0313F470F
Block: 9403694
Paid: 0.000001267073875012 ETH (1267046 gas * 0.001000022 gwei)


##### sepolia
✅  [Success] Hash: 0x7ffce2fc6cb95dfedded04d16f6bc1298b34f943de9d4f1822bddc1f83600260
Contract Address: 0xF66A9999ea07825232CeEa4F75711715934333D1
Block: 9403694
Paid: 0.000000249346485502 ETH (249341 gas * 0.001000022 gwei)


##### sepolia
✅  [Success] Hash: 0xac66b569b76835d5be2600c3c2ea9b1be000477a102e9eab454bd939ad3e35ec
Contract Address: 0xd84a783dCaECFa4Cc109A340B01447527bf59027
Block: 9403694
Paid: 0.00000246944432658 ETH (2469390 gas * 0.001000022 gwei)


##### sepolia
✅  [Success] Hash: 0x286566de42014976c0a61e86458bcc55666beff587b0ee73eb3e3338774b127d
Block: 9403694
Paid: 0.000000032023704506 ETH (32023 gas * 0.001000022 gwei)


##### sepolia
✅  [Success] Hash: 0xb085bcc136f3918d64315f799839de53aa5f64a438a86db60d73c46652a71343
Block: 9403694
Paid: 0.000000056350239678 ETH (56349 gas * 0.001000022 gwei)


##### sepolia
✅  [Success] Hash: 0xe7b54da3ca39fd30d2a49a66adfc4540a9663a74b7628ab2300382420a0dc2a8
Contract Address: 0x28F0BC53b52208c8286A4C663680C2eD99d18982
Block: 9403694
Paid: 0.000000178547927968 ETH (178544 gas * 0.001000022 gwei)

✅ Sequence #1 on sepolia | Total Paid: 0.000008543403950752 ETH (8543216 gas * avg 0.001000022 gwei)


==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
##
```

## BASE SEPOLIA

### Contract Addresses

| Contract               | Contract Address                                                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| EDEN Multisig          | [`0x3139DB2845810C4DE0727A5D5Aa24146C086eE1A`](https://sepolia.basescan.org/address/0x3139DB2845810C4DE0727A5D5Aa24146C086eE1A) |
| SPIRIT Token           | [`0xc7e9de362C6eA2Cc03863ECe330622146Ff1c18B`](https://sepolia.basescan.org/address/0xc7e9de362C6eA2Cc03863ECe330622146Ff1c18B) |
| Reward Controller      | [`0x1390A073a765D0e0D21a382F4F6F0289b69BE33C`](https://sepolia.basescan.org/address/0x1390A073a765D0e0D21a382F4F6F0289b69BE33C) |
| Staking Pool (Beacon)  | [`0x6A96aC9BAF36F8e8b6237eb402d07451217C7540`](https://sepolia.basescan.org/address/0x6A96aC9BAF36F8e8b6237eb402d07451217C7540) |
| Eden Factory           | [`0x879d67000C938142F472fB8f2ee0b6601E2cE3C6`](https://sepolia.basescan.org/address/0x879d67000C938142F472fB8f2ee0b6601E2cE3C6) |
| Spirit Vesting Factory | [`0x94bea63d6eC10AF980bf8C7aEFeE04665D355AFe`](https://sepolia.basescan.org/address/0x94bea63d6eC10AF980bf8C7aEFeE04665D355AFe) |

### Logs

```shell
forge script script/Deploy.s.sol:DeployEden --rpc-url $BASE_SEPOLIA_RPC_URL --account TESTNET_DEPLOYER --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY

[⠊] Compiling...
No files changed, compilation skipped
Enter keystore password:
Script ran successfully.

== Logs ==

  ===> DEPLOYMENT CONFIGURATION
   --- Admin address                 : 0x5D6D8518A1d564c85ea5c41d1dc0deca70F2301C
   --- Treasury address              : 0x5D6D8518A1d564c85ea5c41d1dc0deca70F2301C
   --- Distributor address           : 0x5D6D8518A1d564c85ea5c41d1dc0deca70F2301C
   --- Super Token Factory           : 0x7447E94Dfe3d804a9f46Bf12838d467c912C8F6C
   --- UniswapV4 Position Manager    : 0x4B2C77d209D3405F41a037Ec6c77F7F5b8e2ca80
   --- UniswapV4 Pool Manager        : 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408
   --- Permit2 address               : 0x000000000022D473030F116dDEE9F6B43aC78BA3
   --- Spirit Token Name             : Secret Token V3
   --- Spirit Token Symbol           : SECRETv3
   --- Spirit Token Supply           : 1000000000
   --- SPIRIT/ETH Initial Tick       : 184200
   --- SPIRIT/ETH Tick Spacing       : 200
   --- SPIRIT/ETH Pool Fee           : 10000

  ===> DEPLOYING EDEN PROTOCOL
   --- Chain ID          :    84532
   --- Deployer address  :    0x48CA32c738DC2Af6cE8bB33934fF1b59cF8B1831
   --- Deployer balance  :    52 ETH

  ===> DEPLOYMENT RESULTS
   --- Spirit Token              : 0xc7e9de362C6eA2Cc03863ECe330622146Ff1c18B
   --- Reward Controller         : 0x1390A073a765D0e0D21a382F4F6F0289b69BE33C
   --- Staking Pool              : 0x6A96aC9BAF36F8e8b6237eb402d07451217C7540
   --- Eden Factory              : 0x879d67000C938142F472fB8f2ee0b6601E2cE3C6
   --- Spirit Vesting Factory    : 0x94bea63d6eC10AF980bf8C7aEFeE04665D355AFe


## Setting up 1 EVM.

==========================

Chain 84532

Estimated gas price: 0.001000418 gwei

Estimated total gas used for script: 11227391

Estimated amount required: 0.000011232084049438 ETH

==========================

##### base-sepolia
✅  [Success] Hash: 0xc50d67ae2218cba4f9cee243fcbb7e276bdbc35488a2023ca5a253134f149bf6
Contract Address: 0xc7e9de362C6eA2Cc03863ECe330622146Ff1c18B
Block: 32300075
Paid: 0.0000003331999573 ETH (333130 gas * 0.00100021 gwei)


##### base-sepolia
✅  [Success] Hash: 0x03d939ad64734f7214d8bb9d789d4dfda0c9680b6d08f40eb4a4c4e719f4cfac
Block: 32300075
Paid: 0.00000005632282531 ETH (56311 gas * 0.00100021 gwei)


##### base-sepolia
✅  [Success] Hash: 0x02403728cc9e7fd92f5c1347b8b81530ed8a541f52c328aa77eb8d69b6781779
Contract Address: 0x818e6782A736D5A30A6373F0f0eAB9a0A60dDC15
Block: 32300075
Paid: 0.00000031994817501 ETH (319881 gas * 0.00100021 gwei)


##### base-sepolia
✅  [Success] Hash: 0x2ce34715da87d658b48993c943efd0815d2b97b4de276b94f48b2e4d29ce9c72
Block: 32300075
Paid: 0.0000000476600065 ETH (47650 gas * 0.00100021 gwei)


##### base-sepolia
✅  [Success] Hash: 0x749e9ab9cf51fd8f00920c001dc9120ed538374f385a638c9d91ac3b407fed19
Contract Address: 0x41C272c29Df1D1a5Ae480305dd0C95aEF1b2B104
Block: 32300075
Paid: 0.00000076008458425 ETH (759925 gas * 0.00100021 gwei)


##### base-sepolia
✅  [Success] Hash: 0x755b1a6c48e45683f15e71aa122ca9a12b89221b5a085234c80030bc25c668d9
Block: 32300075
Paid: 0.00000005128876838 ETH (51278 gas * 0.00100021 gwei)


##### base-sepolia
✅  [Success] Hash: 0x7dcc15d924cf02c740dd371979d023f297bf0a6c2fcb91220f136d147efa6a0f
Block: 32300075
Paid: 0.00000067798834766 ETH (677846 gas * 0.00100021 gwei)


##### base-sepolia
✅  [Success] Hash: 0x36855825cd3cec41d4b9d4bd68da41124da845ad09eb35de905048e7290e7f56
Block: 32300075
Paid: 0.0000002659158306 ETH (265860 gas * 0.00100021 gwei)


##### base-sepolia
✅  [Success] Hash: 0xcc9769425573251554e076e188c87fc1d3aa1d6ec2c7df79930974d662ff75ba
Contract Address: 0x94bea63d6eC10AF980bf8C7aEFeE04665D355AFe
Block: 32300075
Paid: 0.00000135036051617 ETH (1350077 gas * 0.00100021 gwei)


##### base-sepolia
✅  [Success] Hash: 0x66ceb805a987414ef1c9ecdfe1f07c6d68ea5fdfc23b0515d765af23b7e58455
Block: 32300075
Paid: 0.00000020089417892 ETH (200852 gas * 0.00100021 gwei)


##### base-sepolia
✅  [Success] Hash: 0x01b2a76a52d996d066732acedc3318132837f5a95ede06b2950c54aee4314725
Contract Address: 0x11817a7d96f16D90Ea3D8C8C84b1d6756042166E
Block: 32300075
Paid: 0.00000126731207966 ETH (1267046 gas * 0.00100021 gwei)


##### base-sepolia
✅  [Success] Hash: 0x6b645d6b39ee451c239b574d6ebcacded154569e9ffd9d853fa7252d8736a0a5
Contract Address: 0x6A96aC9BAF36F8e8b6237eb402d07451217C7540
Block: 32300075
Paid: 0.00000024939336161 ETH (249341 gas * 0.00100021 gwei)


##### base-sepolia
✅  [Success] Hash: 0x929fbd518c9e4082516bb53caeb8c53da0e3a907578d1c09b6b422b1ffa859ed
Contract Address: 0x879d67000C938142F472fB8f2ee0b6601E2cE3C6
Block: 32300075
Paid: 0.00000017858149424 ETH (178544 gas * 0.00100021 gwei)


##### base-sepolia
✅  [Success] Hash: 0x6d6b2ccdf43f23681b6c035ce0aa9e9adebaba89d2c0173b4ed190621b36df43
Block: 32300075
Paid: 0.00000005634883077 ETH (56337 gas * 0.00100021 gwei)


##### base-sepolia
✅  [Success] Hash: 0x03acc51832347ecf7c32386d5bfa2f239119bffd729eb0f03d7259d6ae1b471a
Contract Address: 0x1390A073a765D0e0D21a382F4F6F0289b69BE33C
Block: 32300075
Paid: 0.00000022776081973 ETH (227713 gas * 0.00100021 gwei)


##### base-sepolia
✅  [Success] Hash: 0xcc512904f385fc688e555a0d78a44d419b45b38fd76b4a63fc4713b475013d52
Block: 32300075
Paid: 0.00000003202972483 ETH (32023 gas * 0.00100021 gwei)


##### base-sepolia
✅  [Success] Hash: 0xaf17de43f800c29a1a7189ce052232dc634fd2ca36a4b7e9fee4db859e36c345
Contract Address: 0x071909f4C103871fc53D6F940eFa8f15c1E80aa0
Block: 32300075
Paid: 0.0000024699085719 ETH (2469390 gas * 0.00100021 gwei)

✅ Sequence #1 on base-sepolia | Total Paid: 0.00000854499807284 ETH (8543204 gas * avg 0.00100021 gwei)


==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
##
```

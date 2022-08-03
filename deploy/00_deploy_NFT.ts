import { DeployFunction } from 'hardhat-deploy/types';
import { calculate_whitelist_root } from '../whitelist/utils';

const fn: DeployFunction = async function ({ deployments: { deploy }, ethers: { getSigners }, network }) {
  const deployer = (await getSigners())[0];
  const signerAddress = "0xeA860Ae1b9aEB06b674664c5496D2F8Ee7C4BBFA";
 
  const maxBatchSize_ = 5;
  const collectionSize_ = 7777;
  const baseTokenURI = "https://gateway.pinata.cloud/ipfs/QmchQb5AmN17JyLDMFimADLqvJ6o9iy3mJseDLQcwqxWcy/";
  const placeHolderURI = "";

  const root = calculate_whitelist_root();

  const contractDeployed = await deploy('DireLej', {
    from: deployer.address,
    log: true,
    skipIfAlreadyDeployed: false,
    args: [
      baseTokenURI,
      placeHolderURI,
      maxBatchSize_,
      collectionSize_,
      signerAddress
    ]
  });

  console.log('npx hardhat verify --network '+ network.name +  ' ' + contractDeployed.address);

};
fn.skip = async (hre) => {
  return false;
  // Skip this on kovan.
  const chain = parseInt(await hre.getChainId());
  return chain != 1;
};
fn.tags = ['Anero'];

export default fn;

import { DeployFunction } from 'hardhat-deploy/types';
import { calculate_whitelist_root } from '../whitelist/utils';

const fn: DeployFunction = async function ({ deployments: { deploy }, ethers: { getSigners }, network }) {
  const deployer = (await getSigners())[0];
  const signerAddress = "0x5e6cCfBa0aB8Bf8BDEE5ABe9f6eE0BB2f274a609";
 
  const maxBatchSize_ = 5;
  const collectionSize_ = 3333;
  const currentSaleAmount = 500;
  const baseTokenURI = "https://kanessanft.mypinata.cloud/ipfs/QmbEaPLaoYJzDYih3q15eMCeEdU5rCFRXsDsuM4Ki9N1DN/";
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
      signerAddress,
      currentSaleAmount
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

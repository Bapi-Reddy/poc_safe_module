import { ethers } from "ethers";
import dotenv from "dotenv";
import EthersAdapter from "@gnosis.pm/safe-ethers-lib";
import { SafeAccountConfig, SafeFactory } from "@gnosis.pm/safe-core-sdk";

const main = async () => {
  dotenv.config();
  /// replace with actual safe module address
  const safeModule = "0x9633E0749faa6eC6d992265368B88698d6a93Ac0";

  const provider = new ethers.providers.JsonRpcProvider(process.env.MATIC_RPC);
  const safeOwner = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);

  const ethAdapter = new EthersAdapter({
    ethers,
    signerOrProvider: safeOwner
  });

  const safeFactory = await SafeFactory.create({
    ethAdapter
  });
  const safeAccountConfig: SafeAccountConfig = {
    owners: [safeOwner.address],
    threshold: 1
  };
  const safeSdk = await safeFactory.deploySafe({ safeAccountConfig });
  console.log("safe deployed to:", safeSdk.getAddress());

  const safeEnableModuleTx = await safeSdk.createEnableModuleTx(safeModule);
  const safeEnableModuleSignedTx = await safeSdk.signTransaction(
    safeEnableModuleTx,
    "eth_sign"
  );

  await safeSdk.executeTransaction(safeEnableModuleSignedTx);
  console.log(`[Enabled Module] ${safeModule}`);
};

main()
  .then(() => console.log("[Execution completed]"))
  .catch((e) => {
    throw e;
  });

import { BigNumber, ethers } from "ethers";
import dotenv from "dotenv";
import EthersAdapter from "@gnosis.pm/safe-ethers-lib";
import { SafeAccountConfig, SafeFactory } from "@gnosis.pm/safe-core-sdk";

import { MetaTransactionData } from "@safe-global/safe-core-sdk-types";

const ERC20Abi = [
  {
    inputs: [
      { internalType: "address", name: "recipient", type: "address" },
      { internalType: "uint256", name: "amount", type: "uint256" }
    ],
    name: "transfer",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "nonpayable",
    type: "function"
  }
];
const SafeModuleAbi = [
  {
    inputs: [{ internalType: "uint256", name: "usdcAmt", type: "uint256" }],
    name: "initPosition",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [],
    name: "registerSafe",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  }
];

const main = async () => {
  dotenv.config();
  const USDC_ADDRESS = "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8";
  /// TODO: add address after deploy
  const SAFE_MODULE_ADDRESS = "";

  const provider = new ethers.providers.JsonRpcProvider(process.env.MATIC_RPC);
  const safeOwner = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);

  const ethAdapter = new EthersAdapter({
    ethers,
    signerOrProvider: safeOwner
  });

  const usdcContract = new ethers.Contract(USDC_ADDRESS, ERC20Abi, safeOwner);
  const safeModuleContract = new ethers.Contract(
    SAFE_MODULE_ADDRESS,
    SafeModuleAbi,
    safeOwner
  );

  const safeModuleConfig = {
    address: safeModuleContract.address,
    registerSafeCallData: (_safe: string) =>
      safeModuleContract.interface.encodeFunctionData("registerSafe"),
    initPosCallData: (_safe: string) =>
      safeModuleContract.interface.encodeFunctionData("initPosition", [
        BigNumber.from(1).mul(BigNumber.from(1e9)).mul(BigNumber.from(1e9))
      ])
  };

  const safeFactory = await SafeFactory.create({
    ethAdapter
  });
  const safeAccountConfig: SafeAccountConfig = {
    owners: [safeOwner.address],
    threshold: 1
  };
  const safeSdk = await safeFactory.deploySafe({ safeAccountConfig });
  console.log("[safe deployed]", safeSdk.getAddress());

  /// TEMP: init balance on safe
  await usdcContract.transfer(
    safeSdk.getAddress(),
    BigNumber.from(1).mul(BigNumber.from(1e9)).mul(BigNumber.from(1e9))
  );

  const safeEnableModuleData = (
    await safeSdk.createEnableModuleTx(safeModuleConfig.address)
  ).data;
  const safeEnableModuleAndExecuteOpsData: MetaTransactionData[] = [
    {
      ...safeEnableModuleData
    },
    {
      to: safeModuleConfig.address,
      data: safeModuleConfig.registerSafeCallData(safeSdk.getAddress()),
      value: "0"
    },
    {
      to: safeModuleConfig.address,
      data: safeModuleConfig.initPosCallData(safeSdk.getAddress()),
      value: "0"
    }
  ];
  console.log(
    `[executing txns] ${JSON.stringify(safeEnableModuleAndExecuteOpsData)}`
  );

  const safeInitializationTx = await safeSdk.createTransaction({
    safeTransactionData: safeEnableModuleAndExecuteOpsData,
    onlyCalls: true
  });
  const safeEnableModuleSignedTx = await safeSdk.signTransaction(
    safeInitializationTx,
    "eth_sign"
  );

  await safeSdk.executeTransaction(safeEnableModuleSignedTx, {
    /// TODO: hardcoded gas limit for tenderly testing, must be fetched from RPC in prod
    gasLimit: 8000000
  });
  console.log(`[Enabled Module] ${safeModuleConfig.address}`);
};

main()
  .then(() => console.log("[Execution completed]"))
  .catch((e) => {
    throw e;
  });

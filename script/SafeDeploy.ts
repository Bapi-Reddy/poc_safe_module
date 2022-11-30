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

const main = async () => {
  dotenv.config();
  const DAI_ADDRESS = "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063";

  const provider = new ethers.providers.JsonRpcProvider(process.env.MATIC_RPC);
  const safeOwner = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);

  const ethAdapter = new EthersAdapter({
    ethers,
    signerOrProvider: safeOwner
  });

  /// TODO: transfering 0.1DAI to safe here, modify it to safeModule address and calldata to execute
  const erc20Contract = new ethers.Contract(DAI_ADDRESS, ERC20Abi, safeOwner);
  const safeModuleConfig = {
    address: DAI_ADDRESS,
    initCallData: (_safe: string) =>
      erc20Contract.interface.encodeFunctionData("transfer", [
        _safe,
        BigNumber.from(1).mul(BigNumber.from(1e9))
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
  await erc20Contract.transfer(
    safeSdk.getAddress(),
    BigNumber.from(1).mul(BigNumber.from(1e9))
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
      data: safeModuleConfig.initCallData(safeSdk.getAddress()),
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

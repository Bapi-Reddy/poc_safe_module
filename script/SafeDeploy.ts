import { ethers } from "ethers";
import dotenv from "dotenv";

const main = async () => {
  dotenv.config();

  const provider = new ethers.providers.JsonRpcProvider(process.env.MATIC_RPC);
  const signer = await provider.getSigner(
    "0x9633E0749faa6eC6d992265368B88698d6a93Ac0"
  );

  console.log("address:", signer._address);
};

main()
  .then(() => console.log("[Execution completed]"))
  .catch((e) => {
    throw e;
  });

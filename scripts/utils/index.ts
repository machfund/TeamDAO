import { TonContract } from "@rsquad/ton-utils";
import { sendThroughMultisig } from "@rsquad/ton-utils/dist/net";
import pkgSafeMultisigWallet from "../../ton-packages/SafeMultisigWallet.package";
import pkgSCMS from "../../ton-packages/SCMS.package";
import { TonClient } from "@tonclient/core";
import { TonPackage } from "@rsquad/ton-utils/dist/ton-contract";

export const createMultisig = (client: TonClient) =>
  new TonContract({
    client,
    name: "SafeMultisigWallet",
    tonPackage: pkgSafeMultisigWallet,
    address: process.env.MULTISIG_ADDRESS,
    keys: {
      public: process.env.MULTISIG_PUBKEY,
      secret: process.env.MULTISIG_SECRET,
    },
  });

  export const me = async (client: TonClient, smcSafeMultisigWallet: TonContract) => { 
    const myAddr = new TonContract({
    client,
    name: "SCMS",
    tonPackage: pkgSCMS,
    address: process.env.MY_ADDRESS,
    keys: {
      public: process.env.MY_PUBKEY,
      secret: process.env.MY_SECRET,
    },
  });
  // await sendThroughMultisig({
  //   smcSafeMultisigWallet,
  //   dest: myAddr.address,
  //   value: 5000_000_000_000,
  // });
  if (!(await isAddrActive(client, myAddr.address))) {
  await myAddr.deploy({input: {
    owners: ["0x" + process.env.MY_PUBKEY],
    reqConfirms: 1
  } }); }
    return myAddr as TonContract;
  } 

  

export const deployDirectly = async ({
  client,
  smcSafeMultisigWallet,
  name,
  tonPackage,
  input = {},
  initialData = {},
}: {
  client: TonClient;
  smcSafeMultisigWallet: TonContract;
  name: string;
  tonPackage: TonPackage;
  input?: any;
  initialData?: any;
}) => {
  try {
    const smc = new TonContract({
      client,
      name: name,
      tonPackage: tonPackage,
      keys: await client.crypto.generate_random_sign_keys(),
    });
    await smc.calcAddress({ initialData });

    await sendThroughMultisig({
      smcSafeMultisigWallet,
      dest: smc.address,
      value: 5_000_000_000,
    });

    await smc.deploy({ input, initialData });
    return smc as TonContract;
  } catch (err) {
    console.log(err);
  }
};

export const isAddrActive = async (client: TonClient, addr: string) => {
  const { result } = await client.net.query_collection({
    collection: "accounts",
    filter: { id: { eq: addr } },
    result: "acc_type",
  });
  if (result[0] && result[0].acc_type == 1) return true;
  return false;
};

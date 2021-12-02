import { createClient, TonContract } from "@rsquad/ton-utils";
import pkgLLCService from "../ton-packages/LLCService.package";
import pkgLLCWallet from "../ton-packages/LLCWallet.package";
import pkgLLCWalletDebot from "../ton-packages/LLCWalletDebot.package";
import pkgLLCServiceDebot from "../ton-packages/LLCServiceDebot.package";
import pkgLLCAdminDebot from "../ton-packages/LLCAdminDebot.package";
import { createMultisig, deployDirectly, me } from "./utils";
import { sendThroughMultisig } from "@rsquad/ton-utils/dist/net";
import { utf8ToHex } from "@rsquad/ton-utils/dist/convert";
import { exit } from "process";
import { NETWORK_MAP } from "@rsquad/ton-utils/dist/constants";
const fs = require("fs");

(async () => {
  try {
    let client;
    let smcSafeMultisigWallet: TonContract;

    let smcLLCService: TonContract;
    let smcLLCWalletDebot: TonContract;
    let smcLLCServiceDebot: TonContract;
    let smcLLCAdminDebot: TonContract;

    client = createClient();

    const asd = createMultisig(client);
    smcSafeMultisigWallet = await me(client, asd);

    smcLLCService = new TonContract({
      client,
      name: "LLCService",
      tonPackage: pkgLLCService,
      keys: await client.crypto.generate_random_sign_keys(),
    });

    await smcLLCService.calcAddress({
      initialData: {
        _addrAdmin: smcSafeMultisigWallet.address,
      },
    });

    await sendThroughMultisig({
      smcSafeMultisigWallet,
      dest: smcLLCService.address,
      value: 5_000_000_000,
    });

    await smcLLCService.deploy({
      initialData: {
        _addrAdmin: smcSafeMultisigWallet.address,
      },
    });

    await smcLLCService.call({
      functionName: "init",
      input: {
        codeLLCWallet: (
          await client.boc.get_code_from_tvc({ tvc: pkgLLCWallet.image })
        ).code,
      },
    });

    console.log(`LLCService deployed: ${smcLLCService.address}`);

    smcLLCServiceDebot = new TonContract({
      client,
      name: "LLCServiceDebot",
      tonPackage: pkgLLCServiceDebot,
      keys: await client.crypto.generate_random_sign_keys(),
    });
    await smcLLCServiceDebot.calcAddress();

    await smcSafeMultisigWallet.call({
      functionName: "sendTransaction",
      input: {
        dest: smcLLCServiceDebot.address,
        value: 5_000_000_000,
        bounce: false,
        flags: 2,
        payload: "",
      },
    });

    await smcLLCServiceDebot.deploy();

    await new Promise<void>((resolve) => {
      fs.readFile(
        "./build/LLCServiceDebot.abi.json",
        "utf8",
        async function (err, data) {
          if (err) {
            return console.log({ err });
          }
          const buf = Buffer.from(data, "ascii");
          const hexvalue = buf.toString("hex");
          await smcLLCServiceDebot.call({
            functionName: "setABI",
            input: {
              dabi: hexvalue,
            },
          });
          resolve();
        }
      );
    });
    

    smcLLCAdminDebot = new TonContract({
      client,
      name: "smcLLCAdminDebot",
      tonPackage: pkgLLCAdminDebot,
      keys: await client.crypto.generate_random_sign_keys(),
    });
    await smcLLCAdminDebot.calcAddress();

    await smcSafeMultisigWallet.call({
      functionName: "sendTransaction",
      input: {
        dest: smcLLCAdminDebot.address,
        value: 5_000_000_000,
        bounce: false,
        flags: 2,
        payload: "",
      },
    });

    await smcLLCAdminDebot.deploy();

    await new Promise<void>((resolve) => {
      fs.readFile(
        "./build/LLCAdminDebot.abi.json",
        "utf8",
        async function (err, data) {
          if (err) {
            return console.log({ err });
          }
          const buf = Buffer.from(data, "ascii");
          const hexvalue = buf.toString("hex");
          await smcLLCAdminDebot.call({
            functionName: "setABI",
            input: {
              dabi: hexvalue,
            },
          });
          resolve();
        }
      );
    });


    smcLLCWalletDebot = new TonContract({
      client,
      name: "LLCWalletDebot",
      tonPackage: pkgLLCWalletDebot,
      keys: await client.crypto.generate_random_sign_keys(),
    });
    await smcLLCWalletDebot.calcAddress();

    await smcSafeMultisigWallet.call({
      functionName: "sendTransaction",
      input: {
        dest: smcLLCWalletDebot.address,
        value: 5_000_000_000,
        bounce: false,
        flags: 2,
        payload: "",
      },
    });

    await smcLLCWalletDebot.deploy();

    await new Promise<void>((resolve) => {
      fs.readFile(
        "./build/LLCWalletDebot.abi.json",
        "utf8",
        async function (err, data) {
          if (err) {
            return console.log({ err });
          }
          const buf = Buffer.from(data, "ascii");
          const hexvalue = buf.toString("hex");
          await smcLLCWalletDebot.call({
            functionName: "setABI",
            input: {
              dabi: hexvalue,
            },
          });
          resolve();
        }
      );
    });

    await smcLLCServiceDebot.call({
      functionName: "init",
      input: {
        addrLLCService: smcLLCService.address,
        addrLLCWalletDebot: smcLLCWalletDebot.address
      },
    });

    await smcLLCAdminDebot.call({
      functionName: "init",
      input: {
        addrLLCService: smcLLCService.address
      },
    });

    console.log(
      `LLCServiceDebot: tonos-cli --url ${NETWORK_MAP[process.env.NETWORK][0]} debot fetch ${
        smcLLCServiceDebot.address
      }`
    );
    console.log(
      `LLCAdminDebot: tonos-cli --url ${NETWORK_MAP[process.env.NETWORK][0]} debot fetch ${
        smcLLCAdminDebot.address
      }`
    );
    // console.log(
    //   `tonos-cli --url ${NETWORK_MAP[process.env.NETWORK][0]} debot fetch ${
    //     smcLLCWalletDebot.address
    //   }`
    // );
  } catch (err) {
    console.log(`Error! `, err);
  }
  exit();
})();

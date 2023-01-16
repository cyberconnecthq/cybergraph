import * as fs from "fs/promises";
import * as path from "path";

const writeAbi = async () => {
  const folders = [
    "CyberWallet.sol/CyberWallet.json",
    "CyberWalletFactory.sol/CyberWalletFactory.json",
  ];
  const ps = folders.map(async (file) => {
    const f = await fs.readFile(path.join("./out", file), "utf8");
    const json = JSON.parse(f);
    const fileName = path.parse(file).name;
    return fs.writeFile(
      path.join("docs/abi", `${fileName}.json`),
      JSON.stringify(json.abi)
    );
  });
  await Promise.all(ps);
};

const main = async () => {
  await writeAbi();
};

main()
  .then(() => {})
  .catch((err) => {
    console.error(err);
  });

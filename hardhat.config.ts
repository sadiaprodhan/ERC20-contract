import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";

dotenv.config();
const ROPSTEN_URL = "https://ropsten.infura.io/v3/ce5d6e71eace484fa17a1d1f656bb15d";
const RINKEBY_URL = "https://rinkeby.infura.io/v3/ce5d6e71eace484fa17a1d1f656bb15d";
const PRIVATE_KEY = "12a6316d56e45a10a4ee13954c98eebf6c3d37615211d713abb44f664dded68b";
const ETHERSCAN_API_KEY = "19H1YIAC2VY617HMG6W55W71RWQB5B1UPX";

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
    ropsten: {
      url: ROPSTEN_URL ,
      accounts: PRIVATE_KEY != undefined ? [PRIVATE_KEY] : []
    },
    rinkeby: {
      url: RINKEBY_URL,
      accounts: PRIVATE_KEY != undefined ? [PRIVATE_KEY] : []
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },

};

export default config;

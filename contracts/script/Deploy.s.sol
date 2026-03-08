// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/PledgeVaultRH.sol";

contract Deploy is Script {
    // Robinhood Chain Testnet token addresses
    address constant USDC = 0xbf4479C07Dc6fdc6dAa764A0ccA06969e894275F;
    address constant TSLA = 0xC9f9c86933092BbbfFF3CCb4b105A4A94bf3Bd4E;
    address constant AMZN = 0x5884aD2f920c162CFBbACc88C9C51AA75eC09E02;
    address constant PLTR = 0x1FBE1a0e43594b3455993B5dE5Fd0A7A266298d0;
    address constant AMD = 0x71178BAc73cBeb415514eB542a8995b82669778d;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        // Deploy vault: deployer is treasury and relayer initially
        PledgeVaultRH vault = new PledgeVaultRH(USDC, deployer, deployer);

        // Set allocations: 30% TSLA, 25% AMZN, 25% PLTR, 20% AMD
        PledgeVaultRH.StockAllocation[] memory allocs = new PledgeVaultRH.StockAllocation[](4);
        allocs[0] = PledgeVaultRH.StockAllocation(TSLA, 3000);
        allocs[1] = PledgeVaultRH.StockAllocation(AMZN, 2500);
        allocs[2] = PledgeVaultRH.StockAllocation(PLTR, 2500);
        allocs[3] = PledgeVaultRH.StockAllocation(AMD, 2000);
        vault.setAllocations(allocs);

        vm.stopBroadcast();

        console.log("PledgeVaultRH deployed at:", address(vault));
        console.log("Owner/Treasury/Relayer:", deployer);
    }
}

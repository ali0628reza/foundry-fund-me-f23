// SPDX-Lisence-Identifier: MIT

// in this contract we're gonna do 2 things,
// 1. Deploy mocks when we are on a local anvil chain
// 2. Keep track of contract addresses across different chains
// for example:
// Sepolia ETH/USD -> different address
// Mainnet ETH/USD -> different address

// ** and if we setup this helperconfig currectly we'll be able to work with the local chain with no problem and work
// with any chain we want with no problim

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // if we are on a local anvil, we deploy mocks
    // otherwise, grab the existing address from the live network
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DESIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed; // ETH/USD price feed address
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // this is gonna return a configuration for everything we need in sepolia or really any chain.
        // all we need in sepolia is gonna be :
        // price feed address

        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return ethConfig;
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
            //  the reason that we use this, is , without this we actually create new price feed in this function
            // however if we already deployed one, we don't want to deploy a new one, so we do this if
            // this  activeNetworkConfig.priceFeed != address(0)   is basically saying, hey have we set the priceFeed up as
            // something? , remember because address defaults to address(0), so if it's not at or zero, we've already set it
            // so just go ahead and return and don't run the rest of this
        }

        // 1. Deploy the mocks
        // 2. Return the mock addresses

        // this way, we can actually deploy the mock contracts in the anvil network
        // and since we using the vm  we can't use pure keyword, and this contract should be a script because we are using broadcast
        // lets deploy our own price feed
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DESIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }
}

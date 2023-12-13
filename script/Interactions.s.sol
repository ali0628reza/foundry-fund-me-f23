// SPDX-License-Identifier: MIT

// fund
// withdraw

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.01 ether;

    // we're gonna fund our most resently deployed contract
    // we have a tool called foundry devops the we use to actually to grab our most resently deployed
    // contract address, this package helps to foundry keep track of the most resently deployed version
    // of a contract, first we should install this package
    // forge install Cyfrin/foundry-devops --no-commit
    // after installing we will import it and you should go to foundry.toml and write ffi= true
    // if you set ffi=true, you're gonna allow foundry to run commands directly on your machine
    // i recomend you to try to keep this off as long as posible
    // https://github.com/Cyfrin/foundry-devops
    // https://youtu.be/sas02qSFZ74?t=7285
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        // the way that this works, is it looks inside of the broadcast folder, based of the chainid
        // and then picks this run-latest and grab these deployed contract in that file
        // now do we have the most recent deployed contract address we can just call fund on this
        // most recent deployed address
        fundFundMe(mostRecentlyDeployed);
        // we will run with : forge script script/...:contractName --rpc-url $... --private-key $..
    }

    function fundFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();
        // we should typecast mostRecentlyDeployed payable because we're gonna sending value
        vm.stopBroadcast();
        console.log("Funded FundMe with &s", SEND_VALUE);
    }
}

contract WithdrawFundMe is Script {
    function withdrawFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
        console.log("Withdraw FundMe balance!");
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        withdrawFundMe(mostRecentlyDeployed);
    }
}

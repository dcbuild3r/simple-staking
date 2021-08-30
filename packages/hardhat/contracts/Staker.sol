pragma solidity >=0.6.0 <0.7.0;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    mapping(address => uint256) public balances;

    uint256 public constant threshold = 1 ether;

    event Stake(address staker, uint256 amount);
    event Withdraw(address staker, uint256 amount);

    modifier deadlineHasPassed() {
        require(timeleft() == 0);
        _;
    }

    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    function getBalance(address _addr) public view returns (uint256) {
        // Mapping always returns a value.
        // If the value was never set, it will return the default value.
        return balances[_addr];
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable {
        emit Stake(msg.sender, msg.value);
        balances[msg.sender] += msg.value;

        if (balances[msg.sender] >= threshold) {
            exampleExternalContract.complete();
        }
    }

    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
    uint256 public deadline = now + 30 seconds;
    bool openForWithdraw = false;

    function execute() public {
        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            openForWithdraw = true;
        }
    }

    // if the `threshold` was not met, allow everyone to call a `withdraw()` function
    function withdraw(uint256 amount, address payable _to)
        public
        deadlineHasPassed
    {
        require(balances[msg.sender] >= amount);
        emit Withdraw(msg.sender, amount);
        balances[msg.sender] -= amount;
        _to.transfer(amount);
    }

    function withdrawAll(address payable _to) public deadlineHasPassed {
        require(balances[msg.sender] != 0);
        emit Withdraw(msg.sender, balances[msg.sender]);
        balances[msg.sender] = 0;
        _to.transfer(balances[msg.sender]);
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeleft() public view returns (uint256) {
        if (deadline - now > 0) {
            return deadline - now;
        } else {
            return 0;
        }
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract RentalContract is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    struct Rental {
        address developer;
        address owner;
        uint depositAmount;
        uint rentalPrice;
        uint withDrawDate;
        bool isActive;
    }

    AggregatorV3Interface internal priceFeed;
    IERC20 public token;
    uint rentedHours = 0;
    uint rentalCost = 0;
    uint amountToReturn = 0;

    mapping(string => Rental) private rentals;

    event RentalStarted(address indexed developer, address indexed owner, uint withDrawDate, uint depositAmount, uint rentalPrice);
    event RentalDiscontinued(address indexed developer, address indexed owner, uint endDate);
    event RentalPaidOut(address indexed developer, address indexed owner, uint amount);

    constructor(address _tokenAddress, address _priceFeedAddress) {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        token = IERC20(_tokenAddress);
    }

    function rentAdd(uint _rentalPrice, string memory _gpuId) external {
        Rental memory rental = Rental({
            developer: address(0xabcd),
            owner: msg.sender,
            depositAmount: _rentalPrice.mul(2),
            rentalPrice: _rentalPrice,
            withDrawDate: block.timestamp,
            isActive: false
        });
        rentals[_gpuId] = rental;
    }

    function rentRemove(string memory _gpuId) external {
        Rental storage ownerRentals = rentals[_gpuId];
        require(ownerRentals.owner == msg.sender, "Not owner");
        require(!ownerRentals.isActive, "Rental is still active");

        // Remove the rental at the specified index
        delete rentals[_gpuId];
    }

    function rentModify(string memory _gpuId, uint _rentalPrice) external {
        Rental storage rental = rentals[_gpuId];
        require(rental.owner == msg.sender, "Not owner");
        require(!rental.isActive, "Rental is still active");
        
        rental.rentalPrice = _rentalPrice;
        rentals[_gpuId] = rental;
    }

    function startRental(string memory _gpuId) external {
        Rental storage currentRental = rentals[_gpuId];
        require(!currentRental.isActive, "Rental is active");

        uint tokenDepositAmount = convertUSDToTokenAmount(currentRental.depositAmount);
        uint rentalAmount = convertUSDToTokenAmount(currentRental.rentalPrice);
        require(token.allowance(msg.sender, address(this)) >= tokenDepositAmount, "Insufficient token allowance");
        require(token.balanceOf(msg.sender) >= tokenDepositAmount, "Insufficient token balance");

        token.safeTransferFrom(msg.sender, address(this), tokenDepositAmount); // Deposit token amount equivalent to the USD price

        currentRental.withDrawDate = block.timestamp;
        currentRental.isActive = true;
        rentals[_gpuId] = currentRental;

        emit RentalStarted(msg.sender, currentRental.owner, block.timestamp, tokenDepositAmount, rentalAmount);
    }

    function discontinueRental(string memory _gpuId) external {
        Rental storage rental = rentals[_gpuId];
        require(rental.isActive, "Rental is not active");
        require(rental.developer == msg.sender || rental.owner == msg.sender, "Not authorized to discontinue rental");

        rental.isActive = false;
        rentals[_gpuId] = rental;

        rentedHours = block.timestamp.sub(rental.withDrawDate).div(1 hours);
        rentalCost = (rental.rentalPrice).mul(rentedHours);
        amountToReturn = (rental.depositAmount).sub(rentalCost);
        
        token.safeTransferFrom(address(this), rental.developer, convertUSDToTokenAmount(amountToReturn));
        token.safeTransferFrom(address(this), rental.owner, convertUSDToTokenAmount(rentalCost));
        rental.withDrawDate = block.timestamp;

        emit RentalDiscontinued(rental.developer, rental.owner, block.timestamp);
    }

    function payoutRental(string memory _gpuId) external {
        Rental storage rental = rentals[_gpuId];
        require(rental.owner == msg.sender, "Not authorized to payout rental");

        rentedHours = (block.timestamp).sub(rental.withDrawDate).div(1 hours);
        rentalCost = (rental.rentalPrice).mul(rentedHours);
        rental.withDrawDate = block.timestamp;

        rentals[_gpuId] = rental;

        token.safeTransferFrom(address(this), rental.owner, convertUSDToTokenAmount(rentalCost));

        emit RentalPaidOut(rental.developer, rental.owner, rentalCost);
    }

    function convertUSDToTokenAmount(uint256 usdAmount) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        // uint256 tokenDecimals = uint256(priceFeed.decimals());
        uint256 tokenAmount = usdAmount.div(uint256(price));
        return tokenAmount;
    }

    function getRental(string memory _gpuId) external view returns (Rental memory) {
        return rentals[_gpuId];
    }

    function getBalance(string[] memory _gpuIds) external view returns (uint) {
        uint balance = 0;
        uint rentedTime = 0;
        uint rentalCostSum = 0;
        for(uint i = 0; i < _gpuIds.length; i ++) {
            rentedTime = block.timestamp.sub(rentals[_gpuIds[i]].withDrawDate).div(1 hours);
            rentalCostSum += rentals[_gpuIds[i]].rentalPrice.mul(rentedTime);
        }

        return rentalCostSum;
    }

    function ownerTransfer(address _newOwner) public onlyOwner {
        transferOwnership(_newOwner);
    }


}
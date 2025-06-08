// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./OkidoPropertyNFT.sol";
import "./FractionalOwnership.sol";

contract OkidoFinance{
    OkidoPropertyNFT public propertyNFT;
    IERC20 public okidoToken;
    uint256 public propertyCounter;
    address public owner;

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    struct Property {
        uint256 tokenId;
        FractionalOwnership fractionalContract; // Fractional ownership contract
        uint256 pricePerShare;
        uint256 totalShares;
        uint256 shareSold; // total shares sold
        string name;
        string uri;
    }

    mapping(uint256 => Property) public properties;
    mapping(address => uint256[]) public userProperties;
    
    event PropertyCreated(uint256 indexed tokenId, address indexed fractionalContract, uint256 priceShare);
    event SharesPurchased(uint256 indexed tokenId, address indexed buyer, uint256 shares);

    constructor(address _propertyNFT, address _okidoToken) {
        propertyNFT = OkidoPropertyNFT(_propertyNFT);
        okidoToken = IERC20(_okidoToken);
        owner = msg.sender;
    }

    // 卖家调用，来创建房产的通证，也就是协议property 的概念
    function createProperty(string memory name, string memory symbol, string memory uri, uint256 totalShares, uint256 pricePerShare) external onlyOwner {
        uint256 tokenId = propertyNFT.mint(address(this), uri);
        FractionalOwnership fractionalContract = new FractionalOwnership(name, symbol, totalShares);

        properties[tokenId] = Property({
            tokenId: tokenId,
            fractionalContract: fractionalContract,
            pricePerShare: pricePerShare,
            totalShares: totalShares,
            shareSold: 0,
            name: name,
            uri: uri
        });
        propertyCounter++;
        emit PropertyCreated(tokenId, address(fractionalContract), pricePerShare);
    }

    // 卖家可以定义买那个nft,买多少个
    function buyShares(uint256 tokenId, uint256 shares) external {
        Property storage property = properties[tokenId];
        require(property.tokenId != 0, "Property does not exist");
        require(property.shareSold + shares <= property.totalShares, "Not enough shares available");

        uint256 cost = shares * property.pricePerShare;
        require(okidoToken.transferFrom(msg.sender, address(this), cost), "Transfer failed");
        
        property.fractionalContract.transfer(msg.sender, shares);
        property.shareSold += shares;
        userProperties[msg.sender].push(tokenId);
        emit SharesPurchased(tokenId, msg.sender, shares);
    }

    // 买家买了后，能在dapp上架，售卖
    function listProperties() external view returns (Property[] memory) { 
        Property[] memory allProperties = new Property[](propertyCounter);
        for(uint256 i = 0; i < propertyCounter; i++){
            Property storage property = properties[i];
            allProperties[i] = Property({
                tokenId: property.tokenId,
                fractionalContract: property.fractionalContract,
                pricePerShare: property.pricePerShare,
                totalShares: property.totalShares,
                shareSold: property.shareSold,
                name: property.name,
                uri: property.uri
            });
        }
        return allProperties;
    }

    function getUserProperties(address user) external view returns (uint256[] memory) {
        return userProperties[user];
    }

}
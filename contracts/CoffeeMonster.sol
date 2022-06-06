// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

//importing relevant libraries
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "erc721a/contracts/ERC721A.sol";

import './royalties/ContractRoyalties.sol';
import "hardhat/console.sol";

contract CoffeeMonster is ERC721A, Ownable, ERC2981ContractRoyalties {

    //Interface for royalties
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    //amount of tokens that have been minted so far, in total and in presale
    uint256 private numberOfTokensMinted;
    uint256 private numberOfTokensPhase1;
    
    //declares the maximum amount of tokens that can be minted, total and in presale
    uint256 private maxTotalTokens;
    uint256 private maxTokensPhase1;
        
    //cost of mints depending on state of sale    
    uint256 private constant mintCostPhase1 = 1.05 ether;
    uint256[16] private prices = [1.05 ether, 1 ether, 0.95 ether, 0.90 ether, 
                            0.85 ether, 0.80 ether, 0.75 ether, 0.70 ether, 
                            0.65 ether, 0.60 ether, 0.55 ether, 0.5 ether, 
                            0.45 ether, 0.40 ether, 0.35 ether, 0.30 ether];
  
    
    //maximum amount of mints allowed per person: 5. Strict comparison
    uint256 public constant maxMintPhase1 = 6;
    
    //the amount of reserved mints that have currently been executed by creator and giveaways
    uint private _reservedMints = 0;
    
    //the maximum amount of reserved mints allowed for creator and giveaways. 500. Strict comparison
    uint private maxReservedMints = 501;
    
    //marks the timestamp of when the respective sales open
    uint256 internal phase1LaunchTime;
    uint256 internal phase2LaunchTime;
    uint256 internal phase3LaunchTime;
    uint256 internal revealTime;

    uint256 private lastPhase1Price;

    //amount of mints that each address has executed
    mapping(address => uint256) public mintsPerAddress;
    
    //current state of sale
    enum State {NoSale, Phase1, Phase2, Phase3}

    //NFT Uri
    string public baseTokenURI;
    
    //declaring initial values for variables
    constructor(string memory _unrevealedURI) ERC721A("Coffee Monster Collection", "CMC") {
        maxTotalTokens = 10001;
        maxTokensPhase1 = 5501;
        setRoyalties(owner(), 500);
        baseTokenURI = _unrevealedURI;

    }

    modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

    ///@dev returns current tokenId
    function tokenId() external view returns(uint256) {
        if (numberOfTokensMinted == 0) {
            return 0;
        } else {
            uint currentId = numberOfTokensMinted - 1;
            return currentId;
        }

    }

    function openSale() external onlyOwner {
        require(saleState() == State.NoSale, 'Sale is already Open!');
        phase1LaunchTime = block.timestamp;
        phase2LaunchTime = phase1LaunchTime + 28800; //8 hours
        phase3LaunchTime = phase2LaunchTime + 172800; //48 hours
    }


    /// @dev mint a @param number of NFTs in public sale Phase 1.
    /// @notice price goes down by 0.5 ETH every 30 mins
    function phase1Mint(uint256 _number) internal {
        State _saleState = saleState();
        require(_saleState == State.Phase1, "Sale is not open!");
        require(numberOfTokensMinted < maxTokensPhase1, "Not enough NFTs left to mint");
        require(mintsPerAddress[msg.sender] < maxMintPhase1, "Max 5 Mints per address allowed!");
        require(_number < maxMintPhase1, "Max reached for phase 1");
        uint256 mintCost_ = mintCost();
        require(msg.value == mintCost_ * _number, "Not enough/too much Ether sent");

        _safeMint(msg.sender, _number); 
        mintsPerAddress[msg.sender] += _number;
        numberOfTokensMinted += _number;
        numberOfTokensPhase1 += _number;

        lastPhase1Price = mintCost();

    }
    
    ///@dev mint a @param number of NFTs in public sale. Phase 2
    ///@notice price is 85% of Phase 1 last price
    function phase2Mint(uint256 _number) internal {

        State saleState_ = saleState();
        require(saleState_ == State.Phase2, "Sale in not open!");
        require(numberOfTokensMinted + _number < maxTotalTokens - maxReservedMints, "Not enough NFTs left to mint..");
        uint256 mintCost_ = mintCost();
        require(msg.value == mintCost_ * _number, "Not enough/too much Ether sent");

            _safeMint(msg.sender, _number); 
            mintsPerAddress[msg.sender] += _number;
            numberOfTokensMinted += _number;
    }

    ///@dev mint a @param number of NFTs in public sale. Phase 3
    ///@notice price is 50% of Phase1 last price
    function phase3Mint(uint256 _number) internal {
        State saleState_ = saleState();
        require(saleState_ == State.Phase3, "Sale in not open!");
        require(numberOfTokensMinted + _number < maxTotalTokens - maxReservedMints, "Not enough NFTs left to mint..");
        uint mintCost_ = mintCost();
        require(msg.value == mintCost_ * _number, "Not enough/too much Ether sent");

        _safeMint(msg.sender, _number);
        mintsPerAddress[msg.sender] += _number;
        numberOfTokensMinted += _number;

        }    

    //This is the function that will be used in the front-end
    function mintNfts(uint _number) external payable callerIsUser {
        State saleState_ = saleState();

        if(saleState_ == State.Phase1){
            phase1Mint(_number);
        } else if (saleState_ == State.Phase2){
            phase2Mint(_number);
        } else if (saleState_ == State.Phase3){
            phase3Mint(_number);
        }
    }   

    /// @dev see the current sale state to set prices
    function saleState() public view returns(State){

        if (phase1LaunchTime == 0) {
            return State.NoSale;
        }
        else if (block.timestamp < phase2LaunchTime && numberOfTokensPhase1 < maxTokensPhase1) {
            return State.Phase1;
        }
        else if (block.timestamp < phase3LaunchTime) {
            return State.Phase2;
        }
        else {
            return State.Phase3;
        }
    }
    
    ///@dev get the current cost of minting. Used for the Dutch Auction functionality
    ///@dev cost in Phase 1 decreases every 30 mins
    ///@dev cost in Phase 2 is 85% of last price in Phase 1
    ///@dev cost in Phase 3 is 50% of last price in Phase 1
    function mintCost() public view returns(uint) {
        State saleState_ = saleState();

        if (saleState_ == State.NoSale) {
            return mintCostPhase1;
        }
        else if (saleState_ == State.Phase1) {
            uint256 timestamp = (block.timestamp - phase1LaunchTime) / uint256(1800);
            return prices[timestamp];
        }
        else if (saleState_ == State.Phase2) {
            return ((lastPhase1Price * uint256(8500)) / uint256(10000));
        }   
        else {
            return ((lastPhase1Price * uint256(5000)) / uint256(10000));
        }    
    }

    function _baseURI() internal view override returns (string memory) {
       return baseTokenURI;
    }
    
    /// @dev changes BaseURI and set it to the true URI for collection
    /// @param revealedTokenURI new token URI. Format required ipfs://CID/
    function reveal(string memory revealedTokenURI) public onlyOwner {
        baseTokenURI = revealedTokenURI;
    }

    /// @dev reserved NFTs for Team
    /// @param _number number of NFTs to be minted
    /// @param recipient address where reserved nfts will be minted to
    function reservedMint(uint256 _number, address recipient) external onlyOwner {
        require(_reservedMints + _number < maxReservedMints, "Not enough Reserved NFTs left");

        _safeMint(recipient, _number);
        numberOfTokensMinted += _number;
        _reservedMints += _number;
        
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev Sets token royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function setRoyalties(address recipient, uint256 value) public {
        _setRoyalties(recipient, value);
    }

    /// @dev retrieve all the funds obtained during minting
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        require(balance > 0, "No funds left to withdraw");

        (bool sent, ) = payable(owner()).call{value: balance}("");
        require(sent, "Failed to send Ether");
    }

    /// @dev reverts transaction if someone accidentally send ETH to the contract 
    receive() payable external {
        revert();
    }
    
}
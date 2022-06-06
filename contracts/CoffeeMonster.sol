// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

//importing relevant libraries
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

import './royalties/ContractRoyalties.sol';
import "hardhat/console.sol";

contract CoffeeMonster is ERC721A, Ownable, ERC2981ContractRoyalties {

    //Interface for royalties
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    //amount of tokens that have been minted so far, in total and in presale
    uint256 private numberOfTotalTokens;
    uint256 private numberOfTokensPhase1;
    
    //declares the maximum amount of tokens that can be minted, total and in presale
    uint256 private maxTotalTokens;
    uint256 private maxTokensPhase1;
    
    //initial part of the URI for the metadata
    string private _currentBaseURI = "ipfs://QmZJ3ohAicfqaCM4UFyvC7uCBdnVsKnNeHnu3DfvknUNmP/";
        
    //cost of mints depending on state of sale    
    uint256 private constant mintCostPhase1 = 1.05 ether;
    uint256 private constant decrement = 0.05 ether;
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

    uint256 private lastPhase1Price = 0.30 ether;

    //amount of mints that each address has executed
    mapping(address => uint256) public mintsPerAddress;
    
    //current state of sale
    enum State {NoSale, Phase1, Phase2, Phase3}

    //Unrevealed NFT Uri
    string public unrevealedURI;
    
    //declaring initial values for variables
    constructor(string memory _unrevealedURI) ERC721A("Coffee Monster Collection", "CMC") {
        maxTotalTokens = 10000;
        maxTokensPhase1 = 8500;

        unrevealedURI = _unrevealedURI;

    }

    modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

    
    //visualize baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }
    
    //change baseURI in case needed for IPFS
    function changeBaseURI(string memory baseURI_) external onlyOwner {
        _currentBaseURI = baseURI_;
        console.log("New Base URI", _currentBaseURI);
    }

    function changeUnrevealedURI(string memory unrevealedURI_) external onlyOwner {
        unrevealedURI = unrevealedURI_;
    }

    function changeMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }
    
    //gets the tokenID of NFT to be minted.
    function tokenId() internal view returns(uint256) {
        uint currentId = totalSupply();
        bool exists = true;
        while (exists) {
            currentId += 1;
            exists = _exists(currentId);
        }
        
        return currentId;
    }

    function openSale() external onlyOwner {
        require(saleState() == State.NoSale, 'Sale is already Open!');
        phase1LaunchTime = block.timestamp;
        phase2LaunchTime = phase1LaunchTime + 28800; //8 hours
        phase3LaunchTime = phase2LaunchTime + 172800; //48 hours

       
    }

    function openWhitelistSale() external onlyOwner {
        require(saleState() != State.NoSale, 'Sale is already Open!');
        whitelistIsOpen = true;
    }


    //mint a @param number of NFTs in public sale
    function phase1Mint(uint256 _number) internal {
        State saleState_ = saleState();
        require(saleState_ == State.Phase1, "Sale is not open!");
        require(numberOfTotalTokens < maxTokensPhase1, "Not enough NFTs left to mint..");
        require(mintsPerAddress[msg.sender] <= maxMintPhase1, "Maximum 5 Mints per Address allowed!");
        require(_number <= maxMintPhase1, "Maximum 5 mints for phase 1");
        uint256 mintCost_ = mintCost();
        require(msg.value >= mintCost_ * _number, "Not sufficient Ether to mint this amount of NFTs");

        

        _safeMint(msg.sender, _number); //safeMint in ERC721A style
        mintsPerAddress[msg.sender] += _number;
        numberOfTotalTokens += _number;
        numberOfTokensPhase1 += _number;

        //lastPhase1Price = mintCost_;
        console.log("Phase1 Mint with price", mintCost_);
    }
    
    //mint a @param number of NFTs in public sale

    function phase2Mint(uint256 _number) internal {

        State saleState_ = saleState();
        require(saleState_ == State.Phase2, "Sale in not open!");
        require(numberOfTotalTokens + _number <= maxTotalTokens - (maxReservedMints - _reservedMints), "Not enough NFTs left to mint..");
        uint256 mintCost_ = mintCost();
        require(msg.value >= mintCost_ * _number, "Not sufficient Ether to mint this amount of NFTs");

            _safeMint(msg.sender, _number); //safeMint in ERC721A style
            mintsPerAddress[msg.sender] += _number;
            numberOfTotalTokens += _number;
        
        

    }

    //mint a @param number of NFTs in public sale
    function phase3Mint(uint256 _number) internal {
        State saleState_ = saleState();
        require(saleState_ == State.Phase3, "Sale in not open!");
        require(numberOfTotalTokens + _number <= maxTotalTokens - (maxReservedMints - _reservedMints), "Not enough NFTs left to mint..");
        uint mintCost_ = mintCost();
        require(msg.value >= mintCost_ * _number, "Not sufficient Ether to mint this amount of NFTs");

        _safeMint(msg.sender, _number); //safeMint in ERC721A style
        mintsPerAddress[msg.sender] += _number;
        numberOfTotalTokens += _number;

        for (uint256 i; i <_number; i++ ){

            uint256 newTokenId = numberOfTotalTokens + i;

            setRoyalties(newTokenId, payable(owner()), 1000);
        }    
        
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

    //Whitelist claiming function
    function whitelistMint(uint256 _number, bytes32[] calldata _merkleProof) external callerIsUser{
        //basic validation. Wallet has not already claimed
        require(whitelistIsOpen == true, "Whitelist is not Open");
        require(!whitelistClaimed[msg.sender], "Address has already claimed NFT");
        require(numberOfTotalTokens + _number <= maxTotalTokens - (maxReservedMints), "Not enough NFTs left to mint..");

        //The whitelist will have free NFTs??? If so, add payable to this function
        //require(msg.value >= mintCost_ * _number, "Not sufficient Ether to mint this amount of NFTs");

        //veryfy the provided Merkle Proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Proof");

        //Mark address as having claimed the token
        whitelistClaimed[msg.sender] = true;

        //mint tokens 
        _safeMint(msg.sender, _number); //safeMint in ERC721A style
            mintsPerAddress[msg.sender] += _number;
            numberOfTotalTokens += _number;
    }


    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        require(_exists(tokenId_), "ERC721Metadata: URI query for nonexistent token");
        
        //check to see that 24 hours have passed since beginning of public sale launch
        if (revealTime == 0) {
            return unrevealedURI;
        }
        
        else {
            string memory baseURI = _baseURI();
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId_.toString(), '.json')) : "";
        }    
    }
    
    //reserved NFTs for creator
    function reservedMint(uint256 _number, address recipient) external onlyOwner {
        require(_reservedMints + _number <= maxReservedMints, "Not enough Reserved NFTs left to mint..");

        _safeMint(recipient, _number); //safeMint in ERC721A style
        mintsPerAddress[recipient] += _number; 
        numberOfTotalTokens += _number;
        _reservedMints += _number;
        
        
    }

    
    //burn the tokens that have not been sold yet
    function burnTokens() external onlyOwner {
        maxTotalTokens = numberOfTotalTokens;
    }
    
    //see the current account balance
    function accountBalance() public onlyOwner view returns(uint) {
        return address(this).balance;
    }
    
    //retrieve all funds received from minting
    function withdraw() external onlyOwner {
        uint256 balance = accountBalance();
        require(balance > 0, 'No Funds to withdraw, Balance is 0');

        _withdraw(payable(owner()), balance);
    }
    
    //send the percentage of funds to a shareholder´s wallet
    function _withdraw(address payable account, uint256 amount) internal {
        (bool sent, ) = account.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
    
    //see the total amount of tokens that have been minted
    
    // function totalSupply() public view override returns(uint256) {
    //      return numberOfTotalTokens;
    //  }
    
    //to see the total amount of reserved mints left 
    function reservedMintsLeft() public onlyOwner view returns(uint256) {
        uint256 mintsLeft = maxReservedMints - _reservedMints;
        console.log("Reserved Mints Left: ", mintsLeft);
        return mintsLeft;
        
        
    }
    //see current state of sale
    //see the current state of the sale
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
    
    //gets the cost of current mint
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
            return ((lastPhase1Price * uint256(85)) / uint256(100));
        }   
        else {
            return lastPhase1Price; //price in phase 3 is higher than phase 2?
        }    
    }

    function reveal() external onlyOwner{

        require(revealTime == 0, "Already been revealed!");
        revealTime = block.timestamp;
        console.log("Revealed, reveal time: ", revealTime);

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

    //in case somebody accidentaly sends funds or transaction to contract. 
    receive() payable external {
        revert();
    }
    
}
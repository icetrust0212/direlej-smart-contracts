// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract DireLej is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    // Amount limit per wallet
    uint256 public maxAmountPerWallet;

    // Price for presale and public sale
    uint256 public publicSalePrice = 30 ether; // 30 matic
    uint256 public presalePrice = 25 ether; // 25 matic

    // Signer for whitelist verification
    address private preSaleSigner;

    // metadata URI
    string private _baseTokenURI;
    string private _placeHolderURI;

    bool public reveal = true;
    uint256 public currentSaleAmount;

    enum SalePhase {
        None,
        PreSale,
        PublicSale
    }

    // Current Sale phase
    SalePhase public currentSalePhase = SalePhase.None;

    /**
        @param maxBatchSize_ Max size for ERC721A batch mint.
        @param collectionSize_ NFT collection size
    */
    constructor(
        string memory _baseURIString,
        string memory _placeholder,
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        address signerAddress,
        uint256 currentSaleAmount_
    ) ERC721A("DireLej", "DRLJ", maxBatchSize_, collectionSize_) {
        _baseTokenURI = _baseURIString;
        _placeHolderURI = _placeholder;

        maxAmountPerWallet = maxBatchSize_;
        preSaleSigner = signerAddress;
        require(currentSaleAmount_ <= collectionSize_, "Current Sale Amount should less than collection size.");
        currentSaleAmount = currentSaleAmount_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier whenPublicSaleIsOn() {
        require(
            currentSalePhase == SalePhase.PublicSale, 
            "Public sale is not live."
        );
        _;
    }

    modifier whenPreSaleOn() {
        require(
            currentSalePhase == SalePhase.PreSale,
            "Presale is not active."
        );
        _;
    }

    function setReveal(bool value) external onlyOwner {
        reveal = value;
    }

    // Set sale mode
    function setSaleMode(SalePhase phase) external onlyOwner {
        require(
            currentSalePhase != phase,
            "Already active."
        );
        currentSalePhase = phase;
    }

    function preSaleMint(
      uint256 quantity,
      bytes calldata signature
    )
        external
        payable
        callerIsUser
        whenPreSaleOn
        nonReentrant
    {
        require(
            totalSupply() + quantity <= currentSaleAmount,
            "reached max supply"
        );
        require(
            numberMinted(msg.sender) + quantity <= maxAmountPerWallet,
            "Exceeds limit"
        );

        verifySigner(signature);

        _safeMint(msg.sender, quantity);

        refundIfOver(presalePrice * quantity);
    }

    function verifySigner(bytes calldata signature) 
        public view {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        address receivedAddress = ECDSA.recover(message, signature);
        require(receivedAddress != address(0) && receivedAddress == preSaleSigner);
    }

    function publicSaleMint(uint256 quantity)
        external
        payable
        callerIsUser
        whenPublicSaleIsOn
        nonReentrant
    {
        require(
            totalSupply() + quantity <= currentSaleAmount,
            "reached max supply"
        );
        require(
            numberMinted(msg.sender) + quantity <= maxAmountPerWallet,
            "Exceeds limit"
        );
        _safeMint(msg.sender, quantity);
        refundIfOver(publicSalePrice * quantity);
    }

    // For marketing etc.
    function devMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= currentSaleAmount, "Exceeds Max Supply");
        
        if (quantity > maxBatchSize) {
            require(
                quantity % maxBatchSize == 0,
                "can only mint a multiple of the maxBatchSize"
            );
        }
        uint256 batchMintAmount = quantity > maxBatchSize ? maxBatchSize : quantity;

        uint256 numChunks = quantity / batchMintAmount;

        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, batchMintAmount);
        }
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (!reveal) {
            return _placeHolderURI;
        }

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, (tokenId + 1).toString(), ".json"))
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPlaceHolderURI(string memory _uri) external onlyOwner {
        _placeHolderURI = _uri;
    }

    function setPreSaleSigner(address signer) external onlyOwner {
        preSaleSigner = signer;
    }

    function setCurrentSaleAmount(uint _currentSaleAmount) external onlyOwner {
        currentSaleAmount = _currentSaleAmount;
    }

    // withdraw ether
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // utility functions

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function setPublicSalePrice(uint _price) external onlyOwner {
        publicSalePrice = _price;
    }

    function setPresalePrice(uint _price) external onlyOwner {
        presalePrice = _price;
    }

    function setWalletLimit(uint _limit) external onlyOwner {
        maxAmountPerWallet = _limit;
    }
}

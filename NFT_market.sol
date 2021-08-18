// SPDX-License-Identifier: erenakyildiz
pragma solidity 0.8.0;
import "https://github.com/0xcert/ethereum-erc721/src/contracts/tokens/nf-token-metadata.sol";
import "https://github.com/0xcert/ethereum-erc721/src/contracts/ownership/ownable.sol";

contract NFT is NFTokenMetadata, Ownable {
    
    constructor() {
    nftName = "name";
    nftSymbol = "nftSymbol";
  }
    function mint(address _to, uint256 _tokenId, string calldata _uri) external onlyOwner {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }
    
    
}



contract regularSale {
    
    
    struct NFTdata{

        uint256 price;

        address owner;
    }
    
    
    mapping(address => mapping(uint256 => NFTdata))public nft_information;
    mapping(address => uint256)public user_info;
    
    function depositNFT(address nftAddress, uint256 ID) public payable{
        NFT token = NFT(nftAddress);
        require(token.ownerOf(ID) == msg.sender, "You dont own this token.");
        require(token.getApproved(ID) == address(this), "please approve this contract.");
        token.transferFrom(msg.sender, address(this),ID );
        NFTdata memory info;
        info.price = 0; // set price as 0, and when transfer is tried to be called, if 0 then revert.
        info.owner = msg.sender;
        nft_information[nftAddress][ID] = info;
        
    }
    
    function setPriceForNFT(address senderNftAddress, uint256 senderID, uint256 senderPrice) public{
        
        require(nft_information[senderNftAddress][senderID].owner == msg.sender);
        require(nft_information[senderNftAddress][senderID].owner != address(0x0));
        nft_information[senderNftAddress][senderID].price = senderPrice;
        
    }
    
    function purchase(address nftAddress, uint256 ID) public payable{
        //nft_information[nftAddress][ID]
        require(nft_information[nftAddress][ID].price != 0);
        require(nft_information[nftAddress][ID].owner != msg.sender);
        require(nft_information[nftAddress][ID].price == msg.value);
        user_info[nft_information[nftAddress][ID].owner] += msg.value;
        nft_information[nftAddress][ID].price = 0;
        nft_information[nftAddress][ID].owner = msg.sender;
    }
    
    function withdrawNFT(address nftAddress, uint256 ID) public{
        require(nft_information[nftAddress][ID].owner == msg.sender);
        nft_information[nftAddress][ID].owner = address(0x0);
        NFT(nftAddress).transferFrom(address(this), msg.sender, ID);
    }
    
    function withdrawBalance(uint256 amount) public {
        require(amount <= user_info[msg.sender]);
        user_info[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        
    }
    
}



contract auction{
    
    struct NFTdata{
        uint256 maxBid;
        address maxBidder;
        address owner;
        uint256 time;
    }
    
    // nft_informaion holds the data needed for the NFT's auctionng proccess.
    // user_info holds the balances of the users.
    // the only problem is that the user must know what tokens they own that is in this contract, but this can be done with a database.
    
    
    //for full decentralisation, remove the //* parts of this code (warning cost will be significantly higher.)
    
    
    mapping(address => mapping(uint256 => NFTdata))public nft_information;
    mapping(address => uint256)public user_info;
    //*mapping(address => address[] ) public userNFTS // maps the user to their NFT's to search easily.
   
    // deposit some balance to this contract.
    function _depositBalance() public payable{
        user_info[msg.sender] += msg.value;
    }
    
    //deposit an NFT to this contract.
    function _depositNFT(address nftAddress,uint256 ID) public payable{
        NFT token = NFT(nftAddress);
        require(token.ownerOf(ID) == msg.sender, "You dont own this token.");
        require(token.getApproved(ID) == address(this), "please approve this contract.");
        token.transferFrom(msg.sender, address(this),ID );
        nft_information[nftAddress][ID].time = 0;
        nft_information[nftAddress][ID].owner = msg.sender;
        //*userNFTS[msg.sender].push(nftAddress);
    }
    

    // withdraw money from this contract.
    function withdrawBalance(uint256 amount) public{
        require(user_info[msg.sender] >= amount);
        user_info[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
    

    // withdraw an NFT from this contract.
    function withdrawNFT(address nftAddress, uint256 ID) public {
        require(nft_information[nftAddress][ID].owner == msg.sender);
        require(nft_information[nftAddress][ID].time < block.timestamp);
        nft_information[nftAddress][ID].owner = address(0x0);
        NFT(nftAddress).transferFrom(address(this),msg.sender,ID);
        //* for (uint256 i = 0; i < userNFTS[msg.sender].lenght; i++){
        //* if(userNFTS[msg.sender][i] == nftAddress) {
    //*      delete userNFTS[msg.sender][i]; // this leaves a gap, you need to push everything again which is a big problem for gas prices.
    //*      userNFTS[msg.sender][i] = userNFTS[msg.sender][userNFTS[msg.sender].lenght]; // this also fixes the problem. NOT TESTED DONT USE WITHOUT TESTING
    //*      delete userNFTS[msg.sender[userNFTS[msg.sender].lenght]];
        //*}
    //* }
    }
    

    // bid on an ongoing auction pretty self explainatory.
    function bid(uint256 amount, address nftAddress, uint256 ID) public{
        require(nft_information[nftAddress][ID].time > block.timestamp);
        require(amount > nft_information[nftAddress][ID].maxBid);
        require(user_info[msg.sender] >= amount);
        require(msg.sender != nft_information[nftAddress][ID].owner); // owner can not bid on their own token.
        user_info[msg.sender] -= amount;
        
        
        if(nft_information[nftAddress][ID].maxBidder != nft_information[nftAddress][ID].owner){
             user_info[nft_information[nftAddress][ID].maxBidder] += nft_information[nftAddress][ID].maxBid; 
        }
       
        nft_information[nftAddress][ID].maxBidder = msg.sender;
        nft_information[nftAddress][ID].maxBid = amount;
        
    }

    //starts the auction proccess, the user must first deposit the NFT they wish to auction, and they must not have started an auction that has not ended yet.
    function startAuction(uint256 startBid, uint256 time, address nftAddress, uint256 ID) public {
        require(nft_information[nftAddress][ID].owner == msg.sender);
        require(nft_information[nftAddress][ID].time < block.timestamp);
        require(startBid != 0);
        
        nft_information[nftAddress][ID].maxBidder = msg.sender;
        nft_information[nftAddress][ID].maxBid = startBid;
        nft_information[nftAddress][ID].time = block.timestamp + time;
        
        
    }


    //the sender or the receiver can end the auction, the receiver function sends money to the owner first, then sets receiver as the owner of the token. (security purposes)
    function endAuctionForReceiver(address nftAddress, uint256 ID) public { 
        require(nft_information[nftAddress][ID].time < block.timestamp);
        require(msg.sender == nft_information[nftAddress][ID].maxBidder);
        
        user_info[nft_information[nftAddress][ID].owner] += nft_information[nftAddress][ID].maxBid;
        nft_information[nftAddress][ID].owner = nft_information[nftAddress][ID].maxBidder;
        
    }
    // if sender wishes to end the auction, the nft is sent to the max bidder and money is received afterwards. (security purposes)
    function endAuctionForSender(address nftAddress, uint256 ID) public {
        require(nft_information[nftAddress][ID].time < block.timestamp);
        require(msg.sender == nft_information[nftAddress][ID].owner);
        
        nft_information[nftAddress][ID].owner = nft_information[nftAddress][ID].maxBidder;
        user_info[nft_information[nftAddress][ID].owner] += nft_information[nftAddress][ID].maxBid;
        
    }
}

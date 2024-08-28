// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
/*
 @author junfeiLi
*/
/*铸币操作*/
// 部分已经阉割后的合约源码仅供参考  --
contract  CreateCoin is ERC721URIStorage,ERC721Royalty,Ownable{
     uint private _tokenIds;
     uint96  public royaltyFee = 100; //版权费用比例分母是10000
     address public  feeCollector ; //费用收集
     uint public  createCoinFee = 1 gwei;//铸币费用
     constructor(address initialOwner) ERC721('IndustrialComponents','IND') Ownable(initialOwner) payable  {
        feeCollector = msg.sender;
     }
     function setRoyaltyFee(uint96 fee) external onlyOwner {
        royaltyFee = fee;
     }
     function setFeeCollector(address ad) external  onlyOwner{
        feeCollector = ad;
     }
     function setCreateCoinFee(uint fee) external  onlyOwner{
        createCoinFee = fee;
     }
     // 铸币
    function min(address ad,string memory tokenUri) external payable  returns (uint) {
           require(msg.value>=createCoinFee,'you must give 1 gwei');
           uint256 newItemId = _tokenIds++;
           _mint(ad, newItemId);
           _setTokenURI(newItemId, tokenUri);
           //设置版权费
           _setTokenRoyalty(newItemId,ad,royaltyFee);
           return  newItemId;
    }
    function withDraw() public onlyOwner{
        (bool success,bytes memory data) =   feeCollector.call{value:address(this).balance}("");
        require(success,'transfer faild');
    }
    function getTth() external  view  returns (uint) {
        return address(this).balance;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Royalty,ERC721URIStorage) returns (bool) {
       return  super.supportsInterface(interfaceId);
    }   
    function tokenURI(uint256 tokenId) public view virtual override(ERC721,ERC721URIStorage)  returns (string memory) {
         return  super.tokenURI(tokenId);
    }
}
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./libs/IBEP20.sol";
import "./libs/SafeBEP20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Presale is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    // Maps user to the number of tokens owned
    mapping (address => uint256) public tokensOwned;
    // The number of unclaimed tokens the user has
    mapping (address => uint256) public tokensUnclaimed;

    // Token
    IBEP20 public TOKEN;
    // Sale active
    bool public isSaleActive;
    // Claim active
    bool public isClaimActive;
    // Starting timestamp
    uint256 public startingTimeStamp;
    // Total Token
    uint256 public totalTokenForSale = 100000 ether;
    // Total Token sold
    uint256 public totalTokensSold = 0;
    // Price of presale Token, 10 BUSD
    uint256 public BUSDPerToken = 10;
    // Amount of BUSD received in presale
    uint256 public busdReceived = 0;
    // Hardcap
    uint256 public HARD_CAP = 1000000 ether;
    // BUSD token
    IBEP20 public BUSD;

    address payable owner;

    modifier onlyOwner(){
        require(msg.sender == owner, "You're not the owner");
        _;
    }

    event TokenBuy(address user, uint256 tokens);
    event TokenClaim(address user, uint256 tokens);

    constructor (address _Token, address _BUSD, uint256 _startingTimestamp) public {
        TOKEN = IBEP20(_Token);
        BUSD = IBEP20(_BUSD);
        isSaleActive = true;
        owner = msg.sender;
        startingTimeStamp = _startingTimestamp;
    }

    function buy (uint256 _amount) public nonReentrant {
        require(isSaleActive, "Presale has not started");

        address _buyer = msg.sender;
        uint256 tokens = _amount.div(BUSDPerToken);

        require (busdReceived +  _amount <= HARD_CAP, "Presale hardcap reached");
        require(block.timestamp >= startingTimeStamp, "Presale has not started");

        BUSD.safeTransferFrom(msg.sender, address(this), _amount);

        tokensOwned[_buyer] = tokensOwned[_buyer].add(tokens);
        tokensUnclaimed[_buyer] = tokensUnclaimed[_buyer].add(tokens);
        totalTokensSold = totalTokensSold.add(tokens);
        busdReceived = busdReceived.add(_amount);
        emit TokenBuy(msg.sender, tokens);
    }

    function setSaleActive(bool _isSaleActive) external onlyOwner {
        isSaleActive = _isSaleActive;
    }

    function setClaimActive(bool _isClaimActive) external onlyOwner {
        isClaimActive = _isClaimActive;
    }
    
    function getTokensLeft() external view returns (uint256) {
        return TOKEN.balanceOf(address(this));
    }

    function claimTokens () external {
        require (isClaimActive, "Claim is not allowed yet");
        require (tokensOwned[msg.sender] > 0, "User should own some tokens");
        require (tokensUnclaimed[msg.sender] > 0, "User should have unclaimed tokens");
        require (TOKEN.balanceOf(address(this)) >= tokensUnclaimed[msg.sender], "There are not enough tokens to transfer.");

        TOKEN.safeTransfer(msg.sender, tokensUnclaimed[msg.sender]);
        emit TokenClaim(msg.sender, tokensUnclaimed[msg.sender]);
        tokensUnclaimed[msg.sender] = 0;
    }

    function withdrawFunds() external onlyOwner {
        BUSD.safeTransfer(msg.sender, BUSD.balanceOf(address(this)));
    }

    function withdrawUnsoldToken() external onlyOwner {
        uint256 amount = TOKEN.balanceOf(address(this)) - totalTokensSold;
        TOKEN.safeTransfer(msg.sender, amount);
    }

    function withdrawAllToken() external onlyOwner {
        TOKEN.safeTransfer(msg.sender, TOKEN.balanceOf(address(this)));
    }
}
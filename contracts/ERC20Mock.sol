// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract ERC20Mock is ERC20Permit, Ownable {
    mapping(address => uint256) public mintedAt;
    uint256 public constant MINT_WINDOW = 24 hours;
    uint256 public mintLimit;

    uint8 private _decimals;

    bool public hasMintRestrictions;

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialAmount,
        uint8 decimals_,
        address _owner
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        _decimals = decimals_;
        mintLimit = 1000 * (10 ** _decimals);

        transferOwnership(_owner);

        _mint(address(this), _initialAmount);

        hasMintRestrictions = true;
    }

    function toggleRestrictions() external onlyOwner {
        hasMintRestrictions = !hasMintRestrictions;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mintTo(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function updateMintLimit(uint256 _newVal) external onlyOwner {
        mintLimit = _newVal;
    }

    function extractTokens(uint256 _amount) external onlyOwner {
        _transfer(address(this), msg.sender, _amount);
    }

    function freeMint(uint256 _val) public {
        if (hasMintRestrictions) {
            require(_val <= mintLimit, "ERC20Mock: amount too big");
            require(
                mintedAt[msg.sender] + MINT_WINDOW <= block.timestamp,
                "ERC20Mock: too early"
            );
        }

        mintedAt[msg.sender] = block.timestamp;

        _mint(msg.sender, _val);
    }

    //WETH behaviour
    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    //WETH behaviour
    function withdraw(uint256 wad) public {
        require(balanceOf(msg.sender) >= wad, "Error");
        _burn(msg.sender, wad);
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    receive() external payable {}
}

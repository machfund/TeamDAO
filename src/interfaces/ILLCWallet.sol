pragma ton-solidity >= 0.47.0;

interface ILLCWallet {
    function getExt() external returns (
        mapping(address => uint32) custodians
    );
}
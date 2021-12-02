pragma ton-solidity >= 0.47.0;

interface ILLCWalletResolver {
    function resolveLLCWallet(address addrAuthor, uint32 id) external returns (address addrLLCWallet);
    function resolveLLCWalletCodeHash(address addrAuthor) external view returns (uint256 codeHashLLCWallet);
}
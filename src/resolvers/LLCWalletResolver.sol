pragma ton-solidity >= 0.47.0;

import '../LLCWallet.sol';

contract LLCWalletResolver {
    TvmCell _codeLLCWallet;

    function resolveLLCWallet(address addrAuthor, uint32 id) public view returns (address addrLLCWallet) {
        TvmCell state = _buildLLCWalletState(addrAuthor, id);
        uint256 hashState = tvm.hash(state);
        addrLLCWallet = address.makeAddrStd(0, hashState);
    }

    function resolveLLCWalletCodeHash(address addrAuthor) external view returns (uint256 codeHashLLCWallet) {
        TvmCell code = _buildLLCWalletCode(addrAuthor);
        codeHashLLCWallet = tvm.hash(code);
    }

    function _buildLLCWalletState(address addrAuthor, uint32 id) internal view returns (TvmCell) {
        return tvm.buildStateInit({
            contr: LLCWallet,
            varInit: {_id: id},
            code: _buildLLCWalletCode(addrAuthor)
        });
    }

    function _buildLLCWalletCode(
        address addrAuthor
    ) internal view inline returns (TvmCell) {
        TvmBuilder salt;
        salt.store(addrAuthor);
        return tvm.setCodeSalt(_codeLLCWallet, salt.toCell());
    }
}

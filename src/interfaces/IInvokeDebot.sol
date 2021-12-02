pragma ton-solidity >=0.47.0;


interface IInvokeDebot {
    function debotEntryPoint(address addrLLCMultisig, address _addrMultisig, address addrLLCService, address _addrLLCServiceDebot) external;
}

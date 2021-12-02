pragma ton-solidity >= 0.47.0;

interface ILLCService {
    function deployLLCWallet(
        mapping(address => uint32) custodians
    ) external;
    function getExt() external returns (
        uint128 staticDeployFee,
        uint32 deployedWalletsCounter,
        address addrAdmin,
        address feeReciever,
        uint128 currentBalance,
        uint128 distributionFee
    );
    function setStaticDeployFee(
        uint128 staticDeployFee
    ) external;
    function setDistributionFee(uint128 distributionFee) external;
    function setFeeReciever(address feeReciever) external;
    function transferFees() external;
}
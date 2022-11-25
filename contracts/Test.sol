pragma ever-solidity ^0.63.0;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "flatqube/contracts/DexPlatform.sol";
import "flatqube/contracts/libraries/DexPlatformTypes.sol";
import "@broxus/contracts/contracts/utils/RandomNonce.sol";


contract Test is RandomNonce {

    constructor() public {
        tvm.accept();
    }

    function test(address left, address right) public pure returns (address pair, uint256, uint256, uint16, uint16, TvmCell, TvmCell) {
        TvmBuilder builder;
        (left.value < right.value) ? builder.store(left, right) : builder.store(right, left);
        address root = address.makeAddrStd(0, 0x5eb5713ea9b4a0f3a13bc91b282cde809636eb1e68d2fcb6427b9ad78a5a9008);
        TvmCell data = tvm.buildDataInit({
            contr: DexPlatform,
            varInit: {
                root: root,
                type_id: uint8(DexPlatformTypes.Pool),
                params: builder.toCell()
            },
            pubkey: 0
        });
        uint256 codeHash = 0xff2fa008bebd79a69fdb40aed7831b0f3c3c7a81e41cb526c07260fc12d53e8f;
        uint256 dataHash = tvm.hash(data);
        uint16 codeDepth = 8;  // todo 8 or 9 ?
        uint16 dataDepth = data.depth();
        uint256 hash = tvm.stateInitHash(codeHash, dataHash, codeDepth, dataDepth);
        return (address(hash), codeHash, dataHash, codeDepth, dataDepth, data, builder.toCell());
    }
//    function _buildInitData(uint8 type_id, TvmCell params) internal view returns (TvmCell) {
//        return tvm.buildStateInit({
//            contr: DexPlatform,
//            varInit: {
//                root: _dexRoot(),
//                type_id: type_id,
//                params: params
//            },
//            pubkey: 0,
//            code: platform_code
//        });
//    }
}

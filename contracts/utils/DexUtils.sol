pragma ever-solidity ^0.63.0;

import "flatqube/contracts/DexPlatform.sol";
import "flatqube/contracts/libraries/DexPlatformTypes.sol";


library DexUtils {

    uint256 constant DEX_ROOT_VALUE = 0x5eb5713ea9b4a0f3a13bc91b282cde809636eb1e68d2fcb6427b9ad78a5a9008;
    uint256 constant DEX_PLATFORM_CODE_HASH = 0xff2fa008bebd79a69fdb40aed7831b0f3c3c7a81e41cb526c07260fc12d53e8f;
    uint16 constant DEX_PLATFORM_CODE_DEPTH = 8;

    function pairAddress(address left, address right) public returns (address) {
        TvmBuilder builder;
        (left.value < right.value) ? builder.store(left, right) : builder.store(right, left);
        address root = address.makeAddrStd(0, DEX_ROOT_VALUE);
        TvmCell data = tvm.buildDataInit({
            contr: DexPlatform,
            varInit: {
                root: root,
                type_id: DexPlatformTypes.Pool,
                params: builder.toCell()
            },
            pubkey: 0
        });
        uint256 dataHash = tvm.hash(data);
        uint16 dataDepth = data.depth();
        return address(tvm.stateInitHash(DEX_PLATFORM_CODE_HASH, dataHash, DEX_PLATFORM_CODE_DEPTH, dataDepth));
    }

}

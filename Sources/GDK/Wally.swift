import Foundation
import ga.wally

public let WALLY_EC_SIGNATURE_RECOVERABLE_LEN = EC_SIGNATURE_RECOVERABLE_LEN
public let WALLY_BLINDING_FACTOR_LEN = BLINDING_FACTOR_LEN

public func sigToDer(sig: [UInt8]) throws -> [UInt8] {
    let sigPtr = UnsafePointer(sig)
    let derPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(EC_SIGNATURE_DER_MAX_LEN))
    var written: Int = 0
    if wally_ec_sig_to_der(sigPtr, sig.count, derPtr, Int(EC_SIGNATURE_DER_MAX_LEN), &written) != WALLY_OK {
        throw GaError.GenericError()
    }
    let der = Array(UnsafeBufferPointer(start: derPtr, count: written))
    // derPtr.deallocate()
    return der
}

public func bip32KeyFromParentToBase58(isMainnet: Bool = true, pubKey: [UInt8], chainCode: [UInt8], branch: UInt32 ) throws -> String {
    let version = isMainnet ? BIP32_VER_MAIN_PUBLIC : BIP32_VER_TEST_PUBLIC
    var subactkey: UnsafeMutablePointer<ext_key>?
    var branchkey: UnsafeMutablePointer<ext_key>?
    var xpubPtr: UnsafeMutablePointer<Int8>?
    let pubKey_: UnsafePointer<UInt8> = UnsafePointer(pubKey)
    let chainCode_: UnsafePointer<UInt8> = UnsafePointer(chainCode)
    defer {
        bip32_key_free(subactkey)
        bip32_key_free(branchkey)
        wally_free_string(xpubPtr)
    }

    if bip32_key_init_alloc(UInt32(version), UInt32(0), UInt32(0), chainCode_, chainCode.count,
                             pubKey_, pubKey.count, nil, 0, nil, 0, nil, 0, &subactkey) != WALLY_OK {
        throw GaError.GenericError()
    }
    if bip32_key_from_parent_alloc(subactkey, branch, UInt32(BIP32_FLAG_KEY_PUBLIC | BIP32_FLAG_SKIP_HASH), &branchkey) != WALLY_OK {
        throw GaError.GenericError()
    }
    if bip32_key_to_base58(branchkey, UInt32(BIP32_FLAG_KEY_PUBLIC), &xpubPtr) != WALLY_OK {
        throw GaError.GenericError()
    }
    return String(cString: xpubPtr!)
}

public func sha256d(_ input: [UInt8]) throws -> [UInt8] {
    let inputPtr: UnsafePointer<UInt8> = UnsafePointer(input)
    let outputPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(SHA256_LEN))
    if wally_sha256d(inputPtr, input.count, outputPtr, Int(SHA256_LEN)) != WALLY_OK {
        throw GaError.GenericError()
    }
    return Array(UnsafeBufferPointer(start: outputPtr, count: Int(SHA256_LEN)))
}

public func asset_final_vbf(values: [UInt64], numInputs: Int, abf: [UInt8], vbf: [UInt8]) throws -> [UInt8] {
    let valuesPtr: UnsafePointer<UInt64> = UnsafePointer(values)
    let abfPtr: UnsafePointer<UInt8> = UnsafePointer(abf)
    let vbfPtr: UnsafePointer<UInt8> = UnsafePointer(vbf)
    let len = Int(BLINDING_FACTOR_LEN)
    let bufferPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: len)
    if wally_asset_final_vbf(valuesPtr, values.count, numInputs, abfPtr, abf.count, vbfPtr, vbf.count, bufferPtr, len) != WALLY_OK {
        throw GaError.GenericError()
    }
    return Array(UnsafeBufferPointer(start: bufferPtr, count: len))
}

public func flatten(_ inputs: [[UInt8]], fixedSize: Int32?) -> [UInt8] {
    return inputs
        .reduce([UInt8](), { (prev, item) in
            if let size = fixedSize, item.count < size {
                return prev + item + [UInt8](repeating: 0, count: Int(size) - item.count)
            }
            return prev + item
        })
}

public func bip32KeyFromBase58(_ input: String) throws -> ga.ext_key {
    var output: UnsafeMutablePointer<ga.ext_key>?
    let base58: UnsafeMutablePointer<CChar> = strdup(input)!
    if bip32_key_from_base58_alloc(base58, &output) != WALLY_OK {
        throw GaError.GenericError()
    }
    guard let output = output else {
        throw GaError.GenericError()
    }
    return output.pointee
}


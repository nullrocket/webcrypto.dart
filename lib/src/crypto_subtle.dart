/// This library attempts to expose the definitions necessary to use the
/// browsers `window.crypto.subtle` APIs.
@JS()
library common;

import '../webcrypto.dart' show HashAlgorithm, KeyUsage;
import 'dart:async';
import 'package:js/js.dart';
import 'dart:typed_data';
import 'dart:html' show DomException;

/// Minimal interface for promises as returned from the browsers WebCrypto API.
@JS('Promise')
class Promise<T> {
  external Promise then(
      void Function(T) onAccept, void Function(DomException) onReject);
}

/// Convert a promise to a future.
Future<T> promiseAsFuture<T>(Promise<T> promise) {
  ArgumentError.checkNotNull(promise, 'promise');

  final c = Completer<T>();
  promise.then(allowInterop(Zone.current.bindUnaryCallback((T result) {
    c.complete(result);
  })), allowInterop(Zone.current.bindUnaryCallback((DomException e) {
    c.completeError(e);
  })));
  return c.future;
}

/// Convert [HashAlgorithm] to Web Cryptography compatible string.
String hashAlgorithmToString(HashAlgorithm hash) {
  ArgumentError.checkNotNull(hash, 'hash');

  switch (hash) {
    case HashAlgorithm.sha1:
      return 'SHA-1';
    case HashAlgorithm.sha256:
      return 'SHA-256';
    case HashAlgorithm.sha384:
      return 'SHA-384';
    case HashAlgorithm.sha512:
      return 'SHA-512';
  }
  // This is an invariant we want to check in production.
  throw AssertionError(
    'HashAlgorithm value with index: ${hash.index} is unknown',
  );
}

/// Convert [List<KeyUsage>] to list of Web Cryptography compatible strings.
List<String> keyUsagesToStrings(List<KeyUsage> usages) {
  ArgumentError.checkNotNull(usages, 'usages');

  return usages.map((usage) {
    switch (usage) {
      case KeyUsage.encrypt:
        return 'encrypt';
      case KeyUsage.decrypt:
        return 'decrypt';
      case KeyUsage.sign:
        return 'sign';
      case KeyUsage.verify:
        return 'verify';
      case KeyUsage.deriveKey:
        return 'deriveKey';
      case KeyUsage.deriveBits:
        return 'deriveBits';
      case KeyUsage.wrapKey:
        return 'wrapKey';
      case KeyUsage.unwrapKey:
        return 'unwrapKey';
    }
    // This is an invariant we want to check in production.
    throw AssertionError(
      'KeyUsage value with index: ${usage.index} is unknown',
    );
  }).toList();
}

/// Convert [List<String>] to list of [KeyUsage] ignoring unknown values.
List<KeyUsage> stringsToKeyUsages(List<String> usages) {
  ArgumentError.checkNotNull(usages, 'usages');

  return usages
      .map((usage) {
        switch (usage) {
          case 'encrypt':
            return KeyUsage.encrypt;
          case 'decrypt':
            return KeyUsage.decrypt;
          case 'sign':
            return KeyUsage.sign;
          case 'verify':
            return KeyUsage.verify;
          case 'deriveKey':
            return KeyUsage.deriveKey;
          case 'deriveBits':
            return KeyUsage.deriveBits;
          case 'wrapKey':
            return KeyUsage.wrapKey;
          case 'unwrapKey':
            return KeyUsage.unwrapKey;
        }
        // Ignore unknown values, we'll filter these out later
        return null;
      })
      .where((s) => s != null)
      .toList();
}

/// Convert [BigInt] to [Uint8List] formatted as [BigInteger][1] following
/// the Web Cryptography specification.
///
/// [1]: https://www.w3.org/TR/WebCryptoAPI/#big-integer
Uint8List bigIntToUint8ListBigInteger(BigInt integer) {
  // TODO: Implement bigIntToUint8ListBigInteger for all positive integers
  if (integer != BigInt.from(65537)) {
    throw UnimplementedError('Only supports 65537 for now');
  }
  return Uint8List.fromList([0x01, 0x00, 0x01]); // 65537
}

/// Minimal interface for the CryptoKey type.
@JS('CryptoKey')
class CryptoKey {
  /// Returns the _type_ of this key, as one of:
  ///  * `'private'`
  ///  * `'public'`
  ///  * `'secret'`
  external String get type;

  /// True, if this key can be extracted.
  external bool get extractable;

  /// Ways in which this key can be used, list of one or more of:
  ///  * `'encrypt'`,
  ///  * `'decrypt'`,
  ///  * `'sign'`,
  ///  * `'verify'`,
  ///  * `'deriveKey'`,
  ///  * `'deriveBits'`,
  ///  * `'wrapKey'`,
  ///  * `'unwrapKey'`.
  external List<String> get usages;
}

/// Interface for the [CryptoKeyPair][1].
///
/// [1]: https://www.w3.org/TR/WebCryptoAPI/#keypair
@JS('CryptoKeyPair')
class CryptoKeyPair {
  external CryptoKey get privateKey;
  external CryptoKey get publicKey;
}

/// Anonymous object to be used for constructing the `algorithm` parameter in
/// `subtle.crypto` methods.
///
/// Note this only works because [WebIDL specification][1] for converting
/// dictionaries say to ignore properties whose values are `null` or
/// `undefined`. Otherwise, this object would define a lot of properties that
/// are not permitted. If two parameters for any algorithms in the Web
/// Cryptography specification has conflicting tyoes in the future, we might
/// have to split this into multiple types. But so they don't have conflicting
/// parameters there is no reason to make a type per algorithm.
///
/// [1]: https://www.w3.org/TR/WebIDL-1/#es-dictionary
@JS()
@anonymous
class Algorithm {
  external String get name;
  external int get modulusLength;
  external Uint8List get publicExponent;
  external String get hash;
  external int get saltLength;
  external TypedData get label;
  external String get namedCurve;
  external CryptoKey get public;
  external TypedData get counter;
  external int get length;
  external TypedData get iv;
  external TypedData get additionalData;
  external int get tagLength;
  external TypedData get salt;
  external TypedData get info;
  external int get iterations;

  external factory Algorithm({
    String name,
    int modulusLength,
    Uint8List publicExponent,
    String hash,
    int saltLength,
    TypedData label,
    String namedCurve,
    CryptoKey public,
    TypedData counter,
    int length,
    TypedData iv,
    TypedData additionalData,
    int tagLength,
    TypedData salt,
    TypedData info,
    int iterations,
  });
}

@JS('crypto.getRandomValues')
external Promise<ByteBuffer> getRandomValues(TypedData array);

@JS('crypto.subtle.decrypt')
external Promise<ByteBuffer> decrypt(
  Algorithm algorithm,
  CryptoKey key,
  TypedData data,
);

@JS('crypto.subtle.encrypt')
external Promise<ByteBuffer> encrypt(
  Algorithm algorithm,
  CryptoKey key,
  TypedData data,
);

@JS('crypto.subtle.exportKey')
external Promise<ByteBuffer> exportKey(
  String format,
  CryptoKey key,
);

@JS('crypto.subtle.generateKey')
external Promise<CryptoKey> generateKey(
  Algorithm algorithm,
  bool extractable,
  List<String> usages,
);

@JS('crypto.subtle.generateKey')
external Promise<CryptoKeyPair> generateKeyPair(
  Algorithm algorithm,
  bool extractable,
  List<String> usages,
);

@JS('crypto.subtle.digest')
external Promise<ByteBuffer> digest(String algorithm, TypedData data);

@JS('crypto.subtle.importKey')
external Promise<CryptoKey> importKey(
  String format,
  TypedData keyData,
  Algorithm algorithm,
  bool extractable,
  List<String> usages,
);

@JS('crypto.subtle.sign')
external Promise<ByteBuffer> sign(
  Algorithm algorithm,
  CryptoKey key,
  TypedData data,
);

@JS('crypto.subtle.verify')
external Promise<bool> verify(
  Algorithm algorithm,
  CryptoKey key,
  TypedData signature,
  TypedData data,
);

// TODO: crypto.subtle.unwrapKey
// TODO: crypto.subtle.wrapKey
// TODO: crypto.subtle.deriveKey
// TODO: crypto.subtle.unwrapBits

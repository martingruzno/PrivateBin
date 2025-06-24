# [![PrivateLinkShare](https://cdn.rawgit.com/PrivateBin/assets/master/images/preview/logoSmall.png)](https://privatebin.info/)

*Current version: 1.0.0*

**PrivateBin** is a minimalist, open source online
[pastebin](https://en.wikipedia.org/wiki/Pastebin)
where the server has zero knowledge of pasted data.

Data is encrypted and decrypted in the browser using 256bit AES in
[Galois Counter mode](https://en.wikipedia.org/wiki/Galois/Counter_Mode).

This is a fork of [PrivateBin](https://github.com/PrivateBin/PrivateBin).

## JS asset compilation
Run `openssl dgst -sha512 -binary js/privatebin.js | openssl enc -base64` in the container. You need to change `js/privatebin.js` for the asset you need to recompile.

To be honest, it's not an asset compilation, but rather regeneration of the SRI hashes. Afterwards, these hashes need to be updatet in `Configuration.php`
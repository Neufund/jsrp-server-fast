# jsrp-server-fast

[![Greenkeeper badge](https://badges.greenkeeper.io/Neufund/jsrp-server-fast.svg)](https://greenkeeper.io/)

This package is a fork of [jsrp](https://github.com/alax/jsrp) which uses
[`bignum`](https://github.com/justmoon/node-bignum) as a big number library instead of 
[`jsbn`](https://github.com/andyperlitch/jsbn)

## Bignum
`bignum` is not pure JS. It uses OpenSSL as a backend

### Pros
* Performance
    * Thanks to the native implementation of `powm` it's 20-30 times faster then pure JS implementation

### Cons
* It uses OpenSSL big num under the hood, so it **can not be used in the browser**

## Installation
    npm install jsrp-server-fast

## Usage
```javascript
    var jsrp = require('jsrp-server-fast');
```

## Example

For an example usage take a look at the original [jsrp](https://github.com/alax/jsrp#example) repo.

You should only use `jsrp.server` in your code, but `jsrp.client` is left for test purposes.

## API Reference

For the API description take a look at the original [jsrp](https://github.com/alax/jsrp#api-reference) repo.

## Testing

First, install the dependencies:

	npm install

Also, you will need Mocha and CoffeeScript if you don't have them already:

	npm install -g mocha coffee-script

Then simply run:

	npm test

This library uses the same test suite as the original one, but it runs much faster (`235ms` compared to `6s` on my computer) thanks to native OpenSSL bignum library used.

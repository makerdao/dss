const ethUtil = require('ethereumjs-util');
const sigUtil = require('eth-sig-util');
const utils = sigUtil.TypedDataUtils;

//Our lad Cal wants to send 2 dai to del, by signing a cheque and paying a 1 dai fee to msg.sender

const calprivKeyHex = '4af1bceebf7f3634ec3cff8a2c38e51178d5d4ce585c52d6043e5e2cc3418bb0'
const calprivKey = new Buffer.from(calprivKeyHex, 'hex')
const cal = ethUtil.privateToAddress(calprivKey);
const del = new Buffer.from('dd2d5d3f7f1b35b7a0601d6a00dbb7d44af58479', 'hex');
const dai = new Buffer.from('11Ee1eeF5D446D07Cf26941C7F2B4B1Dfb9D030B', 'hex');
console.log('cals address: ' + '0x' + cal.toString('hex'));
console.log('dels address: ' + '0x' + del.toString('hex'));
let typedData = {
  types: {
      EIP712Domain: [
          { name: 'name', type: 'string' },
          { name: 'version', type: 'string' },
          { name: 'chainId', type: 'uint256' },
          { name: 'verifyingContract', type: 'address' },
      ],
    Permit: [
          { name: 'holder', type: 'address' },
          { name: 'spender', type: 'address' },
          { name: 'nonce', type: 'uint256' },
          { name: 'expiry', type: 'uint256' },
          { name: 'allowed', type: 'bool' },
      ],
  },
  primaryType: 'Permit',
  domain: {
      name: 'Dai Stablecoin',
      version: '1',
      chainId: 99,
      verifyingContract: '0x11Ee1eeF5D446D07Cf26941C7F2B4B1Dfb9D030B', //in hevm
  },
  message: {
      holder: '0x'+cal.toString('hex'),
      spender: '0x'+del.toString('hex'),
      nonce: 0,
      expiry: 604411200 + 3600,
      allowed: true
  },
};

let hash = ethUtil.bufferToHex(utils.hashStruct('EIP712Domain', typedData.domain, typedData.types))
console.log('EIP712DomainHash: ' + hash);
hash = ethUtil.bufferToHex(utils.hashType('Permit', typedData.types))
console.log('Permit Typehash: ' + hash);
hash = ethUtil.bufferToHex(utils.hashStruct('Permit', typedData.message, typedData.types))
console.log('Permit (from cal to del) hash: ' + hash);
const sig = sigUtil.signTypedData(calprivKey, { data: typedData });
console.log('signed permit: ' + sig);

let r = sig.slice(0,66);
let s = '0x'+ sig.slice(66,130);
let v = ethUtil.bufferToInt(ethUtil.toBuffer('0x'+sig.slice(130,132),'hex'));

console.log('r: ' + r)
console.log('s: ' + s)
console.log('v: ' + v)

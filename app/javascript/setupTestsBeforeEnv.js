const { TextEncoder, TextDecoder } = require('util');
const { ReadableStream } = require('stream/web');
const { MessagePort } = require('worker_threads');

// Polyfills for older jsdom environment since we're stuck on enzyme.
window.TextEncoder = TextEncoder;
window.TextDecoder = TextDecoder;
window.ReadableStream = ReadableStream;
window.MessagePort = MessagePort;

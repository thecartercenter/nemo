import { TextEncoder, TextDecoder } from 'util';
import { Blob } from 'buffer';
import { ReadableStream, WritableStream, TransformStream } from 'stream/web';
import { MessageChannel, MessagePort } from 'worker_threads';

if (typeof global.TextEncoder === 'undefined') global.TextEncoder = TextEncoder;
if (typeof global.TextDecoder === 'undefined') global.TextDecoder = TextDecoder;
if (typeof global.Blob === 'undefined') global.Blob = Blob;
if (typeof global.ReadableStream === 'undefined') global.ReadableStream = ReadableStream;
if (typeof global.WritableStream === 'undefined') global.WritableStream = WritableStream;
if (typeof global.TransformStream === 'undefined') global.TransformStream = TransformStream;
if (typeof global.MessageChannel === 'undefined') global.MessageChannel = MessageChannel;
if (typeof global.MessagePort === 'undefined') global.MessagePort = MessagePort;

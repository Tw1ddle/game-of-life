package websocket;

import haxe.io.Bytes;
import haxe.io.Encoding;
import hx.ws.Types;
import hx.ws.Buffer;
import hx.ws.WebSocket;

/**
   Websocket that sends and receives images (describing game of life patterns)
   Assumes the images are in RGBA8888 format
**/
class PatternImageStream {
	private var ws:WebSocket;
	
	public var onConnected:Void->Void = ()-> {
		trace("Connected");
	};
	
	public var onMessage:Bytes->Void = (bytes:Bytes)-> {
		trace("Read data: " + bytes);
	};
	
	public var onDisconnected:Void->Void = ()-> {
		trace("Disconnected");
	};
	
	public var onError:String->Void = (s:String)-> {
		trace("Error: " + s);
	};
	
	public function new() {
	}
	
	public function connect(uri:String) {
		trace("Connecting");
		
		ws = new WebSocket(uri);
		ws.binaryType = BinaryType.ARRAYBUFFER;
		
		ws.onopen = ()-> {
			onConnected();
		};
		
		ws.onmessage = (msg:Dynamic)-> {
			if (msg.type == "binary") {
				var buffer:Buffer = msg.data;
				readBinaryData(buffer);
			} else {
				trace("Received text-based message, but this is binary-only. Ignoring it");
			}
		};
		
		ws.onclose = ()-> {
			onDisconnected();
			ws = null;
		};
		
		ws.onerror = (err:String)-> {
			onError(err.toString());
		};
	}
	
	public function disconnect() {
		ws.close();
		ws = null;
	}
	
	private function readBinaryData(buffer:Buffer) {
		var bytes:Bytes = buffer.readAllAvailableBytes();
		onMessage(bytes);
	}
}
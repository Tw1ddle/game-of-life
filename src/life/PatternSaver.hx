package life;

import js.three.WebGLRenderTarget;
import js.html.Uint8Array;

/**
 * Expands and saves plain text patterns
 * @see https://www.conwaylife.com/wiki/Plaintext
 */
class PlaintextWriter {
	public static function savePixelsToPlaintext(pixels:Array<Bool>, width:Int, height:Int, patternName:String):Array<String> {
		var plainText = new Array<String>();
		plainText.push("!Name: " + patternName);
		plainText.push("!This is a pattern saved from pixels in Sam Twidale's Game of Life plain text exporter");
		for(h in 0...height) {
			var line:String = "";
			for(w in 0...width) {
				line = line + (pixels[h * width + w] == false ? "." : "O");
			}
			plainText.push(line);
		}
		return plainText;
	}
}
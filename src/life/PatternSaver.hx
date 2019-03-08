package life;

import js.three.WebGLRenderTarget;
import js.html.Uint8Array;

// TODO

/**
 * Expands and saves run length encoded patterns.
 * @see http://www.conwaylife.com/wiki/RLE
 */
class RLEWriter {
	/**
	 * Saves the state of the given render target as a string array, in the run-length encoded format (.rle).
	 * @return	The .rle file representing the current render target.
	 */
	public function saveStateToRle(target:WebGLRenderTarget, ?comments:Array<String>, ?name:String, ?author:String, ?rules:String):Array<String> {		
		var pixels = new js.html.Uint8Array(width * height * 4);
		renderer.readRenderTargetPixels(cast current, 0, 0, width, height, pixels);
		
		var state:Array<String> = [];
		
		if (comments != null && comments.length != 0) {
			for (comment in comments) {
				state.push("#C " + comment);
			}
		}
		
		if (name != null && name.length != 0) {
			state.push("#N " + name);
		}
		
		if (author != null && author.length != 0) {
			state.push("#O " + author);
		}
		
		// TODO skipping saving a P for now, need to add
		
		if (rules != null && rules.length != 0) {
			state.push("#R " + rules);
		}
		
		// TODO
		var currentRun:Int = 0;
		
		for (y in 0...height) {
			for (x in 0...width) {
				// TODO
			}
		}
		
		// TODO split lines to be 70 chars max (ugh)
		
		state[state.length - 1] = state[state.length - 1] + "!";
		
		return state;
	}
}
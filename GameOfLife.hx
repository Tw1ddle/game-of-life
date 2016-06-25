package;

import shaders.Clear;
import shaders.Life;
import shaders.Stamp;
import three.Color;
import three.Mesh;
import three.OrthographicCamera;
import three.PixelFormat;
import three.PlaneBufferGeometry;
import three.Scene;
import three.ShaderMaterial;
import three.Texture;
import three.TextureFilter;
import three.WebGLRenderTarget;
import three.WebGLRenderTargetOptions;
import three.WebGLRenderer;
import three.Wrapping;

/**
 * A WebGL/three.js implementation of Conway's Game of Life.
 * Uses two WebGLRenderTargets to alternate between the current and next state of the simulation.
 */
class GameOfLife {
	private var renderer:WebGLRenderer;
	private var camera:OrthographicCamera;
	private var scene:Scene;
	private var params:WebGLRenderTargetOptions; // The ping-pong render target parameters
	private var ping:WebGLRenderTarget; // The first render target
	private var pong:WebGLRenderTarget; // The second render target
	public var current(default, null):WebGLRenderTarget; // The render target that should be displayed next
	private var lifeMaterial(default, null):ShaderMaterial; // Material used to step the simulation
	private var stampMaterial(default, null):ShaderMaterial; // Material used to stamp patterns onto the render targets, for seeding/interactive editing of the world
	private var clearMaterial(default, null):ShaderMaterial; // Material used to clear the world
	private var mesh:Mesh;
	public var paused(default, null):Bool; // Whether the simulation is paused or not
	
	/**
	 * Creates a new Game of Life simulator.
	 * @param	renderer	The three.js WebGL renderer to use.
	 * @param	width		The width of the ping-pong render targets.
	 * @param	height		The height of the ping-pong render targets.
	 */
	public function new(renderer:WebGLRenderer, width:Int, height:Int) {
		this.renderer = renderer;
		camera = new OrthographicCamera(-0.5, 0.5, 0.5, -0.5, 0, 1);
		scene = new Scene();
		params = { minFilter: TextureFilter.NearestFilter, magFilter: TextureFilter.NearestFilter, format: cast PixelFormat.RGBAFormat, wrapS: Wrapping.RepeatWrapping, wrapT: Wrapping.RepeatWrapping };
		ping = new WebGLRenderTarget(width, height, params);
		pong = new WebGLRenderTarget(width, height, params);
		current = ping;
		lifeMaterial = new ShaderMaterial( {
			vertexShader: Life.vertexShader,
			fragmentShader: Life.fragmentShader,
			uniforms: Life.uniforms
		});
		lifeMaterial.uniforms.tUniverse.value = null;
		
		stampMaterial = new ShaderMaterial( {
			vertexShader: Stamp.vertexShader,
			fragmentShader: Stamp.fragmentShader,
			uniforms: Stamp.uniforms
		});
		stampMaterial.uniforms.tStamp.value = null;
		stampMaterial.uniforms.tLast.value = null;
		
		clearMaterial = new ShaderMaterial( {
			vertexShader: Clear.vertexShader,
			fragmentShader: Clear.fragmentShader,
			uniforms: Clear.uniforms
		});
		
		mesh = new Mesh(new PlaneBufferGeometry(1, 1));
		mesh.material = lifeMaterial;
		scene.add(mesh);
		
		paused = false;
	}
	
	/**
	 * Step/update/tick the Game of Life simulation
	 * @param	overridePaused	Whether to force the update despite the game being paused.
	 */
	public function step(overridePaused:Bool = false):Void {
		if (paused && !overridePaused) {
			return;
		}
		
		// Swap render targets
		current = current == ping ? pong : ping;
		
		// Set uniforms
		lifeMaterial.uniforms.tUniverse.value = current.texture;
		lifeMaterial.uniforms.texelSize.value.set(1 / current.width, 1 / current.height);
		lifeMaterial.uniforms.liveColor.value.set(1.0, 1.0, 1.0, 1.0);
		lifeMaterial.uniforms.deadColor.value.set(0.0, 0.0, 0.0, 1.0);
		
		// Render the scene into the non-current render target
		var nonCurrent = current == ping ? pong : ping;
		renderer.render(this.scene, this.camera, nonCurrent, true);
	}
	
	/**
	 * Stamps a texture onto the world.
	 * @param	x	The horizontal percentage across the world that the upper-left corner of the texture will be drawn.
	 * @param	y	The vertical percentage across the world that the upper-left corner of the texture will be drawn.
	 * @param	pattern	The texture to stamp onto the world.
	 */
	public function stampPattern(x:Float, y:Float, pattern:Texture):Void {
		mesh.material = stampMaterial;
		
		// Scale to render target coordinates
		x = Std.int(x * current.width);
		y = Std.int(y * current.height);
		
		// Set uniforms
		stampMaterial.uniforms.tStamp.value = pattern;
		stampMaterial.uniforms.tLast.value = current.texture;
		stampMaterial.uniforms.pos.value.set(x / current.width, (current.height - y - pattern.image.height) / current.height);
		stampMaterial.uniforms.size.value.set(pattern.image.width / current.width, pattern.image.height / current.height);
		
		// Render the scene into the non-current render target
		var nonCurrent = current == ping ? pong : ping;
		renderer.render(this.scene, this.camera, nonCurrent, true);
		
		mesh.material = lifeMaterial;
	}
	
	/**
	 * Clears the world to the given color.
	 * @param	color	The color to clear the world to.
	 */
	public function clear(color:Color):Void {
		mesh.material = clearMaterial;
		
		clearMaterial.uniforms.clearColor.value.set(color.r, color.g, color.b, 1.0);
		
		renderer.render(this.scene, this.camera, ping, true);
		renderer.render(this.scene, this.camera, pong, true);
		
		mesh.material = lifeMaterial;
	}
	
	public function togglePaused():Void {
		paused = !paused;
	}
	
	/**
	 * Checks whether the cell at the given coordinate within the current render target is alive or dead.
	 * @param	x	The x-coordinate of the cell.
	 * @param	y	The y-coordinate of the cell.
	 * @return	True if the cell is alive, false if the cell is dead.
	 */
	public function isCellLive(x:Float, y:Float):Bool {
		var buffer = new js.html.Uint8Array(4);
		renderer.readRenderTargetPixels(current, Std.int(x * current.width), current.height - Std.int(y * current.height), 1, 1, buffer);
		return buffer[0] == 255 ? true : false;
	}
	
	/**
	 * Saves the state of the current render target as a string array, in the run-length encoded format (.rle).
	 * @return	The .rle file representing the current render target.
	 */
	// TODO
	public function saveStateToRle(?comments:Array<String>, ?name:String, ?author:String, ?rules:String):Array<String> {
		var width = Std.int(current.width);
		var height = Std.int(current.height);
		
		var pixels = new js.html.Uint8Array(width * height * 4);
		renderer.readRenderTargetPixels(current, 0, 0, current.width, current.height, pixels);
		
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
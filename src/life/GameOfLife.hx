package life;

import js.three.Color;
import js.three.Mesh;
import js.three.OrthographicCamera;
import js.three.PlaneBufferGeometry;
import js.three.Scene;
import js.three.ShaderMaterial;
import js.three.Texture;
import js.three.WebGLRenderTarget;
import js.three.WebGLRenderTargetOptions;
import js.three.WebGLRenderer;
import shaders.Clear;
import shaders.Life;
import shaders.Stamp;

/**
 * A WebGL/three.js implementation of Conway's Game of Life.
 * Uses two WebGLRenderTargets to alternate between the current and next state of the simulation.
 */
class GameOfLife {
	private var renderer:WebGLRenderer;
	private var scene:Scene;
	private var camera:OrthographicCamera;
	private var pingOrPong:Bool; // False means ping should be displayed next, true means pong should be displayed next
	private var ping:WebGLRenderTarget; // The first render target
	private var pong:WebGLRenderTarget; // The second render target
	private var current(get, never):WebGLRenderTarget; // The current render target that will be displayed next
	private var nonCurrent(get, never):WebGLRenderTarget; // The non-current render target that isn't being displayed 
	private var lifeMaterial(default, null):ShaderMaterial; // Material used to step the simulation
	private var stampMaterial(default, null):ShaderMaterial; // Material used to stamp patterns onto the render targets, for seeding/interactive editing of the world
	private var clearMaterial(default, null):ShaderMaterial; // Material used to clear the world
	private var mesh:Mesh;
	
	public var paused(default, null):Bool; // Whether the simulation is paused or not
	public var currentTexture(get, never):Texture; // The texture held by the current render target
	public var width(get, never):Int; // The width of the current render target
	public var height(get, never):Int; // The height of the current render target
	
	/**
	 * Creates a new Game of Life simulator.
	 * @param	renderer	The three.js WebGL renderer to use.
	 * @param	width		The width of the ping-pong render targets.
	 * @param	height		The height of the ping-pong render targets.
	 */
	public function new(renderer:WebGLRenderer, width:Int, height:Int) {
		this.renderer = renderer;
		scene = new Scene();
		camera = new OrthographicCamera(-0.5, 0.5, 0.5, -0.5, 0, 1);
		createRenderTargets(width, height);
		pingOrPong = false;
		
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
		
		var geom = new PlaneBufferGeometry(1, 1);
		mesh = new Mesh(cast geom);
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
		pingOrPong = !pingOrPong;
		
		// Set uniforms
		lifeMaterial.uniforms.tUniverse.value = currentTexture;
		lifeMaterial.uniforms.texelSize.value.set(1 / width, 1 / height);
		lifeMaterial.uniforms.liveColor.value.set(1.0, 1.0, 1.0, 1.0);
		lifeMaterial.uniforms.deadColor.value.set(0.0, 0.0, 0.0, 1.0);
		
		// Render the scene into the non-current render target
		renderer.render(this.scene, this.camera, cast this.nonCurrent, true);
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
		x = Std.int(x * width);
		y = Std.int(y * height);
		
		// Set uniforms
		stampMaterial.uniforms.tStamp.value = pattern;
		stampMaterial.uniforms.tLast.value = currentTexture;
		stampMaterial.uniforms.pos.value.set(x / width, (height - y - pattern.image.height) / height);
		stampMaterial.uniforms.size.value.set(pattern.image.width / width, pattern.image.height / height);
		
		// Render the scene into the non-current render target
		renderer.render(this.scene, this.camera, cast this.nonCurrent, true);
		
		mesh.material = lifeMaterial;
	}
	
	/**
	 * Clears the world to the given color.
	 * @param	color	The color to clear the world to.
	 */
	public function clear(color:Color):Void {
		mesh.material = clearMaterial;
		
		clearMaterial.uniforms.clearColor.value.set(color.r, color.g, color.b, 1.0);
		
		renderer.render(this.scene, this.camera, cast ping, true);
		renderer.render(this.scene, this.camera, cast pong, true);
		
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
		var buffer = new js.lib.Uint8Array(4);
		renderer.readRenderTargetPixels(cast current, Std.int(x * width), height - Std.int(y * height), 1, 1, buffer);
		return buffer[0] == 255 ? true : false;
	}
	
	/**
	 * Creates/recreates the ping-pong render targets with the given (power of two) widths and heights.
	 * @param	width The width of the render targets.
	 * @param	height The height of the render targets.
	 */
	public function createRenderTargets(width:Int, height:Int):Void {
		var params = cast { minFilter: cast ThreeVars.NearestFilter, magFilter: cast ThreeVars.NearestFilter, format: cast ThreeVars.RGBAFormat, wrapS: cast ThreeVars.RepeatWrapping, wrapT: cast ThreeVars.RepeatWrapping };
		ping = new WebGLRenderTarget(width, height, params);
		pong = new WebGLRenderTarget(width, height, params);
	}
	
	private function get_currentTexture():Texture {
		return current.texture;
	}
	
	private function get_width():Int {
		Sure.sure(ping.width == pong.width);
		return Std.int(current.width);
	}
	
	private function get_height():Int {
		Sure.sure(ping.height == pong.height);
		return Std.int(current.height);
	}
	
	private function get_current():WebGLRenderTarget {
		return pingOrPong == false ? ping : pong;
	}
	
	private function get_nonCurrent():WebGLRenderTarget {
		return pingOrPong == false ? pong : ping;
	}
}
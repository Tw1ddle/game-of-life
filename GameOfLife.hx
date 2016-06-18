package;

import shaders.Clear;
import shaders.Life;
import shaders.Stamp;
import three.Mesh;
import three.OrthographicCamera;
import three.PixelFormat;
import three.PlaneBufferGeometry;
import three.Scene;
import three.ShaderMaterial;
import three.Texture;
import three.TextureFilter;
import three.Vector4;
import three.WebGLRenderTarget;
import three.WebGLRenderTargetOptions;
import three.WebGLRenderer;
import three.Wrapping;

/**
 * A WebGL/three.js implementation of Conway's Game of Life.
 * Uses two WebGLRenderTargets to alternate between the current and next state of the simulation.
 */
class GameOfLife {
	private var camera:OrthographicCamera;
	private var scene:Scene;
	private var params:WebGLRenderTargetOptions;
	private var ping:WebGLRenderTarget;
	private var pong:WebGLRenderTarget;
	public var current(default, null):WebGLRenderTarget;
	private var lifeMaterial(default, null):ShaderMaterial;
	private var stampMaterial(default, null):ShaderMaterial;
	private var clearMaterial(default, null):ShaderMaterial;
	private var mesh:Mesh;
	public var paused(default, null):Bool;
	
	private var renderer:WebGLRenderer;
	
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
		clearMaterial.uniforms.clearColor.value = new Vector4(0.5, 0.5, 0.5, 1.0);
		
		mesh = new Mesh(new PlaneBufferGeometry(1, 1));
		mesh.material = lifeMaterial;
		scene.add(mesh);
		
		paused = false;
	}
	
	public function render(overridePaused:Bool = false):Void {
		if (paused && !overridePaused) {
			return;
		}
		
		// Swap render targets
		current = current == ping ? pong : ping;
		lifeMaterial.uniforms.tUniverse.value = current.texture;
		
		var nonCurrent = current == ping ? pong : ping;
		
		// Render the game of life 2D scene into the non-current render target
		renderer.render(this.scene, this.camera, nonCurrent, true);
	}
	
	public function stampPattern(x:Int, y:Int, pattern:Texture):Void {
		mesh.material = stampMaterial;
		stampMaterial.uniforms.tStamp.value = pattern;
		stampMaterial.uniforms.tLast.value = current.texture;
		
		stampMaterial.uniforms.pos.value.set(x / current.width, (current.height - y - pattern.image.height) / current.height);
		stampMaterial.uniforms.size.value.set(pattern.image.width / current.width, pattern.image.height / current.height);
		
		trace(stampMaterial.uniforms.pos.value);
		trace(stampMaterial.uniforms.size.value);
		
		var nonCurrent = current == ping ? pong : ping;
		
		renderer.render(this.scene, this.camera, nonCurrent, true);
		
		mesh.material = lifeMaterial;
	}
	
	public function clear():Void {
		mesh.material = clearMaterial;
		
		renderer.render(this.scene, this.camera, ping, true);
		renderer.render(this.scene, this.camera, pong, true);
		
		mesh.material = lifeMaterial;
	}
	
	public function togglePaused():Void {
		paused = !paused;
	}
	
	public function isCellLive(x:Int, y:Int):Bool {
		var buffer = new js.html.Uint8Array(4);
		renderer.readRenderTargetPixels(current, x, y, 1, 1, buffer);
		return buffer[3] == 255 ? true : false; // TODO fix
	}
}
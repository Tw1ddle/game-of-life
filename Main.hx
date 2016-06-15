package;

import js.Browser;
import js.html.DivElement;
import shaders.Life;
import three.Color;
import three.Material;
import three.Mesh;
import three.MeshLambertMaterial;
import three.OrthographicCamera;
import three.PixelFormat;
import three.PlaneBufferGeometry;
import three.PlaneGeometry;
import three.Scene;
import three.ShaderMaterial;
import three.Texture;
import three.TextureFilter;
import three.WebGLRenderTarget;
import three.WebGLRenderTargetOptions;
import three.WebGLRenderer;
import webgl.Detector;

// Automatic HTML code completion, you need to point these to your debug/release HTML
#if debug
@:build(CodeCompletion.buildLocalFile("bin/debug/index.html"))
#else
@:build(CodeCompletion.buildLocalFile("bin/release/index.html"))
#end

class GameOfLife {
	private var camera:OrthographicCamera;
	private var scene:Scene;
	private var params:WebGLRenderTargetOptions;
	private var ping:WebGLRenderTarget;
	private var pong:WebGLRenderTarget;
	private var current:WebGLRenderTarget;
	public var material(default, null):ShaderMaterial;
	private var renderer:WebGLRenderer;
	
	public function new(renderer:WebGLRenderer, width:Int, height:Int) {
		this.renderer = renderer;
		camera = new OrthographicCamera( -1, 1, 1, -1, 0, 1);
		scene = new Scene();
		params = { minFilter: TextureFilter.LinearFilter, magFilter: TextureFilter.NearestFilter, format: cast PixelFormat.RGBAFormat };
		ping = new WebGLRenderTarget(width, height, params);
		pong = new WebGLRenderTarget(width, height, params);
		current = ping;
		material = new ShaderMaterial( {
			vertexShader: Life.vertexShader,
			fragmentShader: Life.fragmentShader,
			uniforms: Life.uniforms
		});
		material.uniforms.tUniverse.value = current.texture;
		
		var mesh = new Mesh(new PlaneBufferGeometry(2, 2), material);
		scene.add(mesh);
	}
	
	public function render():Void {
		// Swap render targets
		current = current == ping ? pong : ping;
		material.uniforms.tUniverse.value = current.texture;
		
		var nonCurrent = current == ping ? pong : ping;
		
		// Render the game of life 2D scene into the non-current render target
		renderer.render(this.scene, this.camera, nonCurrent, true);
	}
	
	public function isCellLive(x:Int, y:Int):Bool {
		var buffer = new js.html.Uint8Array(4);
		renderer.readRenderTargetPixels(current, x, y, 1, 1, buffer);
		trace(buffer);
		return buffer[3] == 255 ? true : false; // TODO fix
	}
	
	public function stampPattern(x:Int, y:Int, pattern:Texture):Void {
		// todo render pattern texture/pixels to rendertarget
	}
}

class Main {
	private static inline var WEBSITE_URL:String = "http://www.samcodes.co.uk/project/game-of-life/"; // Hosted demo URL
	private static inline var REPO_URL:String = "https://github.com/Tw1ddle/game-of-life/"; // Code repository URL
	
	private var renderer:WebGLRenderer;
	private var scene:Scene;
	private var camera:OrthographicCamera;
	private var lifeEffect:GameOfLife;
	private var gameDiv:DivElement;

	private static function main():Void {
		var main = new Main();
	}

	private inline function new() {
		// Wait for the window to load before creating the sliders, starting the simulation input etc
		Browser.window.onload = onWindowLoaded;
	}

	private inline function onWindowLoaded():Void {
		gameDiv = Browser.document.createDivElement();
		
		// WebGL support check
		var glSupported:WebGLSupport = Detector.detect();
		if (glSupported != SUPPORTED_AND_ENABLED) {
			var unsupportedInfo = Browser.document.createElement('div');
			unsupportedInfo.style.position = 'absolute';
			unsupportedInfo.style.top = '10px';
			unsupportedInfo.style.width = '100%';
			unsupportedInfo.style.textAlign = 'center';
			unsupportedInfo.style.color = '#ffffff';
			
			switch(glSupported) {
				case WebGLSupport.NOT_SUPPORTED:
					unsupportedInfo.innerHTML = 'Your browser does not support WebGL. Click <a href="' + REPO_URL + '" target="_blank">here for project info</a> instead.';
				case WebGLSupport.SUPPORTED_BUT_DISABLED:
					unsupportedInfo.innerHTML = 'Your browser supports WebGL, but the feature appears to be disabled. Click <a href="' + REPO_URL + '" target="_blank">here for project info</a> instead.';
				default:
					unsupportedInfo.innerHTML = 'Could not detect WebGL support. Click <a href="' + REPO_URL + '" target="_blank">here for project info</a> instead.';
			}
			
			gameDiv.appendChild(unsupportedInfo);
			return;
		}
		
		// Setup WebGL renderer
        renderer = new WebGLRenderer( { antialias: true } );
		renderer.autoClear = false;
		renderer.setClearColor(new Color(0xff0000));
		renderer.setPixelRatio(Browser.window.devicePixelRatio);
		
		// Scene setup
		scene = new Scene();
		
		// Camera setup
		camera = new OrthographicCamera(-1, 1, 1, -1, 0, 1);
		
		// Setup Game of Life shader effect
		lifeEffect = new GameOfLife(renderer, 500, 500);
		
		// Populate scene
		scene.add(camera);
		
		// TODO use a texture rendering material...
		var mesh = new Mesh(new PlaneBufferGeometry(2, 2), lifeEffect.material);
		scene.add(mesh);
		
		// Initial renderer setup
		onResize();
		
		// Event setup
		// Window resize event
		Browser.window.addEventListener("resize", function():Void {
			onResize();
		}, true);
		
		renderer.domElement.addEventListener("mousedown", function(e:Dynamic):Void {
			e.preventDefault();
			
			var x:Int = Std.int(e.clientX - renderer.domElement.offsetLeft);
			var y:Int = Std.int(e.clientY - renderer.domElement.offsetTop);
			
			onPointerDown(x, y);
		}, false);
		
		renderer.domElement.addEventListener("touchdown", function(e:Dynamic):Void {
			e.preventDefault();
			
		}, false);
		
		// Present game and start animation loop
		gameDiv.appendChild(renderer.domElement);
		var gameAttachPoint = Browser.document.getElementById("game");
		gameAttachPoint.appendChild(gameDiv);
		Browser.window.requestAnimationFrame(animate);
	}
	
	private function animate(time:Float):Void {
		lifeEffect.render();
		
		// Render the world scene to the screen
		renderer.render(scene, camera);
		
		Browser.window.requestAnimationFrame(animate);
	}
	
	// Called when browser window resizes
	private function onResize():Void {
		renderer.setSize(500, 500);
	}
	
	// Called when the user clicks or taps
	private function onPointerDown(x:Int, y:Int):Void {
		var live:Bool = lifeEffect.isCellLive(x, y);
		
		trace(live);
	}
}
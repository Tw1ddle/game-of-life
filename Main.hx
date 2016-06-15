package;

import js.Browser;
import js.html.DivElement;
import three.Color;
import three.OrthographicCamera;
import three.Scene;
import three.WebGLRenderer;
import webgl.Detector;

using StringTools;

// Automatic HTML code completion, you need to point these to your debug/release HTML
#if debug
@:build(CodeCompletion.buildLocalFile("bin/debug/index.html"))
#else
@:build(CodeCompletion.buildLocalFile("bin/release/index.html"))
#end

class Main {
	private static inline var WEBSITE_URL:String = "http://www.samcodes.co.uk/project/game-of-life/"; // Hosted demo URL
	private static inline var REPO_URL:String = "https://github.com/Tw1ddle/game-of-life/"; // Code repository URL
	
	private var renderer:WebGLRenderer;
	private var scene:Scene;
	private var camera:OrthographicCamera;
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
		renderer.setClearColor(new Color(0x000000));
		renderer.setPixelRatio(Browser.window.devicePixelRatio);
		
		// Initial renderer setup
		onResize();
		
		// Event setup
		// Window resize event
		Browser.window.addEventListener("resize", function():Void {
			onResize();
		}, true);
		
		// Scene setup
		scene = new Scene();
		
		// Camera setup
		camera = new OrthographicCamera( -0.5, 0.5, 0.5, -0.5, 1, 1000);
		
		// Present game and start animation loop
		gameDiv.appendChild(renderer.domElement);
		var gameAttachPoint = Browser.document.getElementById("game");
		gameAttachPoint.appendChild(gameDiv);
		Browser.window.requestAnimationFrame(animate);
	}
	
	private function animate(time:Float):Void {
		renderer.render(scene, camera);
		
		Browser.window.requestAnimationFrame(animate);
	}
	
	// Called when browser window resizes
	private function onResize():Void {
		renderer.setSize(500, 500);
	}
}
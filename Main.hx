package;

import js.Browser;
import js.html.ButtonElement;
import js.html.DivElement;
import js.html.Element;
import js.html.SelectElement;
import js.html.TextAreaElement;
import js.nouislider.NoUiSlider;
import shaders.Copy;
import three.Color;
import three.Mapping;
import three.Mesh;
import three.OrthographicCamera;
import three.PlaneBufferGeometry;
import three.Scene;
import three.ShaderMaterial;
import three.Texture;
import three.TextureFilter;
import three.WebGLRenderer;
import three.Wrapping;
import webgl.Detector;

using StringTools;

// Automatic HTML code completion, you need to point these to your debug/release HTML
#if debug
@:build(CodeCompletion.buildLocalFile("bin/debug/index.html"))
#else
@:build(CodeCompletion.buildLocalFile("bin/release/index.html"))
#end
class ID {}

// Stores the embedded pattern files from the /embed folder as arrays of strings for use at runtime
@:build(PatternFileReaderMacro.build("embed"))
@:keep
class Patterns {
}

class Main {
	private static inline var WEBSITE_URL:String = "http://www.samcodes.co.uk/project/game-of-life/"; // Hosted demo URL
	private static inline var REPO_URL:String = "https://github.com/Tw1ddle/game-of-life/"; // Code repository URL
	
	private static inline var DEFAULT_PATTERN_NAME:String = "gosperglidergun_rle"; // Name of the default pattern preset
	
	private var renderer:WebGLRenderer; // The WebGL renderer
	private var clearColor:Color; // The color to clear the Game of Life area to when manually cleared
	private var scene:Scene;
	private var camera:OrthographicCamera;
	private var gameOfLife:GameOfLife;
	private var copyMaterial:ShaderMaterial; // For rendering the final game of life texture to the screen
	private var gameDiv:DivElement; // The HTML div the Game of Life simulation is nested in
	
	private var simulationFramerate:Float; // The simulation/update/tick framerate
	
	private var selectedPatternName(default, set):String; // Name of the currently selected pattern file (name of the corresponding member variable in the Patterns class)
	
	private var patternPresetListElement:SelectElement = cast Browser.document.getElementById(ID.patternpresetlist);
	private var patternFileEditElement:TextAreaElement = cast Browser.document.getElementById(ID.patternfileedit);
	private var lifeClearButtonElement:ButtonElement = cast Browser.document.getElementById(ID.lifeclearbutton);
	private var lifeStepButtonElement:ButtonElement = cast Browser.document.getElementById(ID.lifestepbutton);
	private var runPauseButtonElement:ButtonElement = cast Browser.document.getElementById(ID.liferunpausebutton);
	
	private var simulationFramerateSlider:Element = cast Browser.document.getElementById(ID.simulationframerateslider);

	private static function main():Void {
		var main = new Main();
	}

	private inline function new() {
		for (name in Type.getClassFields(Patterns)) {
			// Populate the embedded pattern select dropdown
			var option = Browser.document.createOptionElement();
			option.appendChild(Browser.document.createTextNode(name));
			option.value = name;
			patternPresetListElement.appendChild(option);
			
			/*
			#if debug // Check that all the embedded patterns are supported, can be read, expanded without errors etc
			var data:Array<String> = Reflect.field(Patterns, name);
			Sure.sure(data != null && data.length != 0);
			var grid = PatternLoader.expandToBoolGrid(name, data);
			Sure.sure(grid.length != 0);
			#end
			*/
		}
		
		Sure.sure(Reflect.field(Patterns, DEFAULT_PATTERN_NAME));
		selectedPatternName = DEFAULT_PATTERN_NAME;
		
		simulationFramerate = 30;
		
		Browser.window.onload = onWindowLoaded; // Wait for the window to load before creating the input elements, starting the simulation input etc
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
		renderer.setPixelRatio(Browser.window.devicePixelRatio);
		
		clearColor = new Color(0x000000);
		
		// Scene setup
		scene = new Scene();
		
		// Camera setup
		camera = new OrthographicCamera(-0.5, 0.5, 0.5, -0.5, 0, 1);
		
		// Setup Game of Life shader effect
		gameOfLife = new GameOfLife(renderer, 256, 256);
		
		copyMaterial = new ShaderMaterial({
			vertexShader: Copy.vertexShader,
			fragmentShader: Copy.fragmentShader,
			uniforms: Copy.uniforms
		});
		copyMaterial.uniforms.tTexture.value = null;
		
		// Populate scene
		var mesh = new Mesh(new PlaneBufferGeometry(1, 1), copyMaterial);
		scene.add(mesh);
		
		// Initial renderer setup
		onResize();
		
		// Event setup
		patternPresetListElement.addEventListener("change", function() {
			selectedPatternName = patternPresetListElement.value;
		}, false);
		
		lifeClearButtonElement.addEventListener("click", function() {
			gameOfLife.clear(clearColor);
		}, false);
		
		lifeStepButtonElement.addEventListener("click", function() {
			if (!gameOfLife.paused) {
				gameOfLife.togglePaused();
				onPauseToggled();
			}
			
			gameOfLife.step(true);
		}, false);
		
		runPauseButtonElement.addEventListener("click", function() {
			gameOfLife.togglePaused();
			onPauseToggled();
		}, false);
		
		// Window resize event
		Browser.window.addEventListener("resize", function():Void {
			onResize();
		}, true);
		
		renderer.domElement.addEventListener("mousedown", function(e:Dynamic):Void {
			e.preventDefault();
			
			var rect = renderer.domElement.getBoundingClientRect();
			var size = renderer.getSize();
			var x = (e.clientX - rect.left) / size.width;
			var y = (e.clientY - rect.top) / size.height;
			
			onPointerDown(x, y);
		}, false);
		
		renderer.domElement.addEventListener("touchstart", function(e:Dynamic):Void {
			e.preventDefault();
			
			var rect = renderer.domElement.getBoundingClientRect();
			var size = renderer.getSize();
			var x = (e.touches[0].clientX - rect.left) / size.width;
			var y = (e.touches[0].clientY - rect.top) / size.height;
			
			onPointerDown(x, y);
		}, false);
		
		NoUiSlider.create(simulationFramerateSlider, {
			start: [ simulationFramerate ],
			connect: 'lower',
			range: {
				'min': [ 1, 1 ],
				'max': [ 300 ]
			},
			pips: {
				mode: 'range',
				density: 10,
			}
		});
		createTooltips(simulationFramerateSlider);
		untyped simulationFramerateSlider.noUiSlider.on(UiSliderEvent.CHANGE, function(values:Array<Float>, handle:Int, rawValues:Array<Float>):Void {
			simulationFramerate = Std.int(values[handle]);
		});
		untyped simulationFramerateSlider.noUiSlider.on(UiSliderEvent.UPDATE, function(values:Array<Float>, handle:Int, rawValues:Array<Float>):Void {
			updateTooltips(simulationFramerateSlider, handle, Std.int(values[handle]));
		});
		
		// Setup a default world
		selectedPatternName = "roteightor_cells";
		onPointerDown(0.1, 0.1);
		onPointerDown(0.7, 0.15);
		onPointerDown(0.2, 0.5);
		onPointerDown(0.65, 0.55);
		onPointerDown(0.2, 0.8);
		onPointerDown(0.85, 0.85);
		selectedPatternName = "ringoffire_rle";
		onPointerDown(0.35, 0.2);
		onPointerDown(0.1, 0.3);
		onPointerDown(0.1, 0.7);
		onPointerDown(0.55, 0.4);
		onPointerDown(0.35, 0.75);
		onPointerDown(0.65, 0.85);
		selectedPatternName = "backrake1_106_lif";
		onPointerDown(0.83, 0.7);
		selectedPatternName = DEFAULT_PATTERN_NAME;
		
		// Present game and start simulation loop
		gameDiv.appendChild(renderer.domElement);
		var gameAttachPoint = Browser.document.getElementById("game");
		gameAttachPoint.appendChild(gameDiv);
		animate();
	}
	
	/**
	 * Main update loop.
	 * @param	time	The time since the last frame of animation.
	 */
	private function animate():Void {
		gameOfLife.step();
		
		// Render the game of life scene to the screen
		copyMaterial.uniforms.tTexture.value = gameOfLife.current.texture;
		renderer.render(scene, camera);
		
		var nextFrameDelay = Std.int((1.0 / this.simulationFramerate) * 1000.0);
		Browser.window.setTimeout(function():Void {
			this.animate();
		}, nextFrameDelay);
	}
	
	/**
	 * Triggered when the user resizes the browser.
	 */
	private function onResize():Void {
		var size = previousPowerOfTwo(Browser.window.innerWidth);
		renderer.setSize(size, size);
	}
	
	/**
	 * Call when you pause or unpause the Game of Life simulation.
	 */
	private function onPauseToggled():Void {
		if (gameOfLife.paused) {
			runPauseButtonElement.innerHTML = "<h2>Run</h2>";
		} else {
			runPauseButtonElement.innerHTML = "<h2>Pause</h2>";
		}
	}
	
	/**
	 * Called when the user clicks or taps the Game of Life world.
	 * @param	x	The percentage distance the pointer was across the renderer view element.
	 * @param	y	The percentage distance the pointer was up the renderer view element.
	 */
	private function onPointerDown(x:Float, y:Float):Void {
		var patternGrid = PatternLoader.expandToBoolGrid(selectedPatternName, Reflect.field(Patterns, selectedPatternName));
		var texture = getTextureForPattern(selectedPatternName, patternGrid);
		gameOfLife.stampPattern(x, y, texture);
		gameOfLife.step(true);
		texture.dispose();
		
		/*
		// Debug code, create all the patterns
		for (name in Type.getClassFields(Patterns)) {
			var data = Reflect.field(Patterns, name);
			var grid = PatternLoader.expandToBoolGrid(name, data);
			if (grid != null) {
				var texture = getTextureForPattern(name, grid);
			}
		}
		*/
	}
	
	/**
	 * Gets a random pattern file from the embedded Patterns class.
	 * @return	The content of the pattern file.
	 */
	private function getRandomPattern():Array<String> {
		var patterns = Type.getClassFields(Patterns);
		var randomFieldIndex = Std.int(Math.random() * (patterns.length - 1));
		return Reflect.field(Patterns, patterns[randomFieldIndex]);
	}
	
	/**
	 * Gets the next power of 2.
	 * @param	x	The value to compute the next power of 2 above.
	 * @return	The next power of 2 above x.
	 */
	private inline function nextPowerOfTwo(x:Int):Int {
		var result:Int = 1;
		while (result < x) {
			result <<= 1;
		}
		return result;
	}
	
	/**
	 * Gets the previous power of 2.
	 * @param	x	The value to compute the previous power of 2 below.
	 * @return	The previous power of 2 below x.
	 */
	private inline function previousPowerOfTwo(x:Int):Int {
		var result:Int = 1;
		while (result << 1 < x) {
			result <<= 1;
		}
		return result;
	}
	
	/**
	 * Gets the texture for the given pattern.
	 * @param	patternGrid	The array of bools indicating the state of the cells.
	 * @return	A texture representing the grid.
	 */
	private function getTextureForPattern(name:String, patternGrid:Array<Array<Bool>>):Texture {
		var maxWidth:Int = 0;
		for (line in patternGrid) {
			if (line.length > maxWidth) {
				maxWidth = line.length;
			}
		}
		
		var canvas = Browser.document.createCanvasElement();
		canvas.width = maxWidth;
		canvas.height = patternGrid.length;
		var ctx = canvas.getContext("2d");
		
		ctx.beginPath();
		ctx.rect(0, 0, canvas.width, canvas.height);
		ctx.fillStyle = "black";
		ctx.fill();
		
		for (y in 0...patternGrid.length) {
			for (x in 0...patternGrid[y].length) {
				if (patternGrid[y][x] == true) {
					ctx.beginPath();
					ctx.rect(x, y, 1, 1);
					ctx.fillStyle = "white";
					ctx.fill();
				}
			}
		}
		
		// Debug - stamp the name of the pattern on the texture
		/*
		ctx.font = "14px Arial";
		ctx.fillText(name, 10, 15);
		*/
		
		var tex = new Texture(canvas, Mapping.UVMapping, Wrapping.ClampToEdgeWrapping, Wrapping.ClampToEdgeWrapping, TextureFilter.NearestFilter, TextureFilter.NearestFilter);
		tex.generateMipmaps = false;
		tex.needsUpdate = true;
		
		// For debug viewing
		/*
		gameDiv.appendChild(canvas);
		*/
		
		return tex;
	}
	
	/*
	 * Helper method to create tooltips on sliders
	 */
	private function createTooltips(slider:Element):Void {
		var tipHandles = slider.getElementsByClassName("noUi-handle");
		for (i in 0...tipHandles.length) {
			var div = js.Browser.document.createElement('div');
			div.className += "tooltip";
			tipHandles[i].appendChild(div);
			updateTooltips(slider, i, 0);
		}
	}

	/*
	 * Helper method to update the tooltips on sliders
	 */
	private function updateTooltips(slider:Element, handleIdx:Int, value:Float):Void {
		var tipHandles = slider.getElementsByClassName("noUi-handle");
		tipHandles[handleIdx].innerHTML = "<span class='tooltip'>" + Std.string(value) + "</span>";
	}
	
	/**
	 * Helper function for setting the currently selected pattern. When this updates, so should the content of the pattern file textbox.
	 * @param	patternName	The name of the member variable in the Patterns class that corresponds to the file.
	 * @return	The current pattern name.
	 */
	private function set_selectedPatternName(patternName:String):String {
		selectedPatternName = patternName;
		
		var fileContent:Array<String> = Reflect.getProperty(Patterns, patternName);
		Sure.sure(fileContent.length > 0);
		
		// Ensure empty lines count as newlines in the text edit
		var content = "";
		for (line in fileContent) {
			content += line + "\r";
		}
		patternFileEditElement.value = content;
		
		if (patternPresetListElement.value != patternName) {
			patternPresetListElement.value = patternName;
		}
		
		return selectedPatternName;
	}
}
package;

import haxe.ds.StringMap;
import js.Browser;
import js.html.ButtonElement;
import js.html.CanvasElement;
import js.html.DivElement;
import js.html.Element;
import js.html.SelectElement;
import js.html.TextAreaElement;
import js.nouislider.NoUiSlider;
import js.three.Color;
import js.three.Mesh;
import js.three.OrthographicCamera;
import js.three.PlaneBufferGeometry;
import js.three.Scene;
import js.three.ShaderMaterial;
import js.three.Texture;
import js.three.WebGLRenderer;
import life.GameOfLife;
import life.PatternLoader;
import life.PatternSaver;
import life.Patterns;
import shaders.Copy;
import webgl.Detector;
import websocket.PatternImageStream;
import haxe.io.Bytes;

using StringTools;

// Automatic HTML code completion, you need to point these to your HTML
@:build(CodeCompletion.buildLocalFile("../bin/index.html"))
class ID {}

class Main {
	private static inline var WEBSITE_URL:String = "https://www.samcodes.co.uk/project/game-of-life/"; // Hosted demo URL
	private static inline var REPO_URL:String = "https://github.com/Tw1ddle/game-of-life/"; // Code repository URL
	
	private static inline var DEFAULT_PATTERN_NAME:String = "pattern_gosperglidergun_rle"; // Name of the default pattern preset
	
	private var renderer:WebGLRenderer; // The WebGL renderer
	private var scene:Scene;
	private var camera:OrthographicCamera;
	private var gameOfLife:GameOfLife;
	private var clearColor:Color; // The color to clear the Game of Life area to when manually cleared
	private var copyMaterial:ShaderMaterial; // For rendering the final game of life texture to the screen
	private var simulationFramerate:Float; // The simulation/update/tick framerate
	
	private var cachedCanvasMap:StringMap<CanvasElement>; // Map that caches references to canvas elements per pattern
	private var selectedPatternName(default, set):String; // Name of the currently selected pattern file (name of the corresponding member variable in the Patterns class)
	
	private var gameDiv:DivElement = null; // The HTML div the Game of Life simulation will be nested in
	private var patternPresetListElement:SelectElement = cast Browser.document.getElementById(ID.patternpresetlist);
	private var patternFileEditElement:TextAreaElement = cast Browser.document.getElementById(ID.patternfileedit);
	private var lifeClearButtonElement:ButtonElement = cast Browser.document.getElementById(ID.lifeclearbutton);
	private var lifeStepButtonElement:ButtonElement = cast Browser.document.getElementById(ID.lifestepbutton);
	private var runPauseButtonElement:ButtonElement = cast Browser.document.getElementById(ID.liferunpausebutton);
	private var simulationFramerateSlider:Element = cast Browser.document.getElementById(ID.simulationframerateslider);
	private var patternPreviewContainer:ButtonElement = cast Browser.document.getElementById(ID.usedpatternscontainer);
	private var randomPatternButtonElement:ButtonElement = cast Browser.document.getElementById(ID.randompatternbutton);
	private var clearPreviousPatternsButtonElement:ButtonElement = cast Browser.document.getElementById(ID.clearpreviouspatterns);

	private static function main():Void {
		var main = new Main();
	}

	private inline function new() {
		for (name in Type.getClassFields(life.Patterns)) {
			// Populate the embedded pattern select dropdown
			var option = Browser.document.createOptionElement();
			option.appendChild(Browser.document.createTextNode(name));
			option.value = name;
			patternPresetListElement.appendChild(option);
		}
		
		clearColor = new Color(0x000000);
		
		cachedCanvasMap = new StringMap();
		
		Sure.sure(Reflect.field(life.Patterns, DEFAULT_PATTERN_NAME) != null);
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
		var mesh = new Mesh(cast new PlaneBufferGeometry(1, 1), copyMaterial);
		scene.add(mesh);
		
		// Initial renderer setup
		onResize();
		
		// Event setup
		patternPresetListElement.addEventListener("change", function() {
			selectedPatternName = patternPresetListElement.value;
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
		
		randomPatternButtonElement.addEventListener("click", function() {
			var fields = Type.getClassFields(Patterns);
			var randomField = fields[Std.int((fields.length - 1) * Math.random())];
			var fileContent = Reflect.field(Patterns, randomField);
			var patternGrid = PatternLoader.expandToBoolGrid(randomField, fileContent);
			var canvas = getCanvasForPattern(randomField, patternGrid);
			selectedPatternName = randomField;
			addCanvasToPreview(randomField, canvas);
		}, false);
		
		lifeClearButtonElement.addEventListener("click", function() {
			gameOfLife.clear(clearColor);
		}, false);
		
		clearPreviousPatternsButtonElement.addEventListener("click", function() {
			patternPreviewContainer.innerHTML = "";
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
			
			if (e.which == 3 || e.button == 2) { // Right click
				fillPixel(x, y);
			} else {
				onPointerDown(x, y);
			}
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
		selectedPatternName = "pattern_lightspeedoscillator1_rle";
		onPointerDown(0.04, 0.10);
		selectedPatternName = "pattern_lightspeedoscillator3_rle";
		onPointerDown(0.35, 0.05);
		selectedPatternName = "pattern_lightspeedoscillator2_rle";
		onPointerDown(0.66, 0.10);
		selectedPatternName = "pattern_linepuffer_rle";
		onPointerDown(0.2, 0.6);
		selectedPatternName = "pattern_roteightor_rle";
		onPointerDown(0.15, 0.8);
		onPointerDown(0.80, 0.75);
		selectedPatternName = "pattern_spacefiller1_rle";
		
		// Present game and start simulation loop
		gameDiv.appendChild(renderer.domElement);
		var gameAttachPoint = Browser.document.getElementById("game");
		gameAttachPoint.innerHTML = "";
		gameAttachPoint.appendChild(gameDiv);

		// Try connecting to a local WebSocket to receive images from elsewhere
		// You can connect by adding a parameter to the ip/port
		tryConnectWebSocket();

		animate();
	}
	
	/**
	 * Main update loop.
	 * @param	time	The time since the last frame of animation.
	 */
	private function animate():Void {
		gameOfLife.step();
		
		// Render the game of life scene to the screen
		copyMaterial.uniforms.tTexture.value = gameOfLife.currentTexture;
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
		var width:Int = Std.int(Math.max(128, previousPowerOfTwo(Std.int(Browser.window.innerWidth))));
		var height:Int = Std.int(Math.max(128, previousPowerOfTwo(Std.int(Browser.window.innerHeight))));
		var downscaledWidth:Int = previousPowerOfTwo(width);
		var downscaledHeight:Int = previousPowerOfTwo(height);
		
		// Size has changed enough to trigger a rescale of the render targets
		if (downscaledWidth != gameOfLife.width || downscaledHeight != gameOfLife.height) {
			gameOfLife.clear(clearColor);
			gameOfLife.createRenderTargets(downscaledWidth, downscaledHeight);
		}
		
		renderer.setSize(width, height);
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
		var canvas = getCanvasForPattern(selectedPatternName, patternGrid);
		addCanvasToPreview(selectedPatternName, canvas);
		var texture = getTexture(canvas);
		gameOfLife.stampPattern(x, y, texture);
		gameOfLife.step(true);
		texture.dispose();
	}

	/**
	 * Bring a pixel to life. Called when the user right clicks the Game of Life world using a mouse.
	 * @param	x	The percentage distance the pointer was across the renderer view element.
	 * @param	y	The percentage distance the pointer was up the renderer view element.
	 */
	private function fillPixel(x:Float, y:Float):Void {
		// Could use this to kill live cells too
		/*
		var pattern = null;
		if (gameOfLife.isCellLive(x, y)) {
			pattern = [[false]]; // Kill the cell
		} else {
			pattern = [[true]]; // Bring the cell to life
		}
		*/
		
		var texture = getTexture(getCanvasForPattern("single_pixel_for_mouse_painting", [[true]]));
		gameOfLife.stampPattern(x, y, texture);
		gameOfLife.step(true);
		texture.dispose();
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
	 * Creates a canvas element for the given name and pattern
	 * @param	name	The name of the pattern
	 * @param	patternGrid	The grid of booleans representing the pattern
	 * @return	The new canvas element representing the pattern
	 */
	private inline function getCanvasForPattern(name:String, patternGrid:Array<Array<Bool>>):CanvasElement {
		if (cachedCanvasMap.exists(name)) {
			return cachedCanvasMap.get(name);
		}
		
		var maxWidth:Int = 0;
		for (line in patternGrid) {
			if (line.length > maxWidth) {
				maxWidth = line.length;
			}
		}
		
		var canvas = Browser.document.createCanvasElement();
		canvas.id = name;
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
		
		cachedCanvasMap.set(name, canvas);
		return canvas;
	}
	
	/**
	 * Adds the given canvas to the pattern previews pane
	 * @param	name	The name of the pattern
	 * @param	canvas	The canvas to add to the pane
	 */
	private inline function addCanvasToPreview(name:String, canvas:CanvasElement):Void {
		// Check if the canvas already exists in the pane
		if (Browser.document.getElementById(name) != null) {
			return;
		}
		
		// Create pattern preview element
		var patternPreviewDiv:DivElement = Browser.document.createDivElement();
		patternPreviewDiv.className = "patternpreviewcontainer";
		var patternTitle:Element = Browser.document.createElement("h3");
		patternTitle.innerHTML = name;
		patternPreviewDiv.appendChild(canvas);
		patternPreviewDiv.appendChild(patternTitle);
		
		canvas.className = "previewcanvas previewcanvashighlight";
		var width = Math.min(200, canvas.width * 4);
		canvas.setAttribute("style", "width: " + Std.string(width) + "px");
		
		patternPreviewDiv.addEventListener("click", function(e:Dynamic):Void {
			selectedPatternName = canvas.id;
		});
		
		updateHighlightedPattern(name);
		patternPreviewContainer.insertBefore(patternPreviewDiv, patternPreviewContainer.firstChild);
	}
	
	/**
	 * Creates a texture from the given canvas
	 * @param	canvas	The canvas to create a texture with.
	 * @return	A texture made using the canvas.
	 */
	private function getTexture(canvas:CanvasElement):Texture {
		var tex = new Texture(canvas, cast ThreeVars.UVMapping, cast ThreeVars.ClampToEdgeWrapping, cast ThreeVars.ClampToEdgeWrapping, cast ThreeVars.NearestFilter, cast ThreeVars.NearestFilter);
		tex.generateMipmaps = false;
		tex.needsUpdate = true;
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
	 * Helper function that highlights the current pattern in the pattern preview area.
	 */
	private inline function updateHighlightedPattern(name:String):Void {
		for (canvas in cachedCanvasMap) {
			if (canvas.id == name) {
				canvas.classList.add("previewcanvashighlight");
			} else {
				canvas.classList.remove("previewcanvashighlight");
			}
		}
	}
	
	/**
	 * Helper function for setting the currently selected pattern. When this updates, so should the content of the pattern file textbox.
	 * @param	patternName	The name of the member variable in the Patterns class that corresponds to the file.
	 * @return	The current pattern name.
	 */
	private function set_selectedPatternName(patternName:String):String {
		updateHighlightedPattern(patternName);
		
		selectedPatternName = patternName;
		
		var fileContent:Array<String> = Reflect.field(life.Patterns, patternName);
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
	
	/**
	 * Gets the next power of 2.
	 * @param	x	The value to compute the next power of 2 above.
	 * @return	The next power of 2 above x.
	 */
	private static inline function nextPowerOfTwo(x:Int):Int {
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
	private static inline function previousPowerOfTwo(x:Int):Int {
		var result:Int = 1;
		while (result << 1 < x) {
			result <<= 1;
		}
		return result;
	}

	/*
	 * Checks if the query string in the browser bar location is empty
	 */ 
	 private static inline function isQueryStringEmpty():Bool {
		var params = Browser.window.location.search.substring(1);
		if (params == null || params == "") {
			return true;
		}
		return false;
	}

	/*
	 * Returns the address/port given in the query string, if one is there
	 */ 
	private function getWebSocketHostAndPort():String {
		if (isQueryStringEmpty()) {
			return null;
		}
		var params = Browser.window.location.search.substring(1);
		var splitParams = params.split("&");
		for (param in splitParams) {
			var kv = param.split("=");
			if (kv.length < 2) {
				continue;
			}
			var k = kv[0].urlDecode();
			var v = kv[1].urlDecode();

			if(k == "socket") {
				return v;
			}
		}
		return null;
	}

	/**
	 * Tries to connect to a web socket if an address and port have been supplied in the query string
	 */
	private static var imagesReceivedFromWebSocketCount:Int = 0; // Keeps count of the number of images recieved from the socket
	private inline function tryConnectWebSocket():Void {
		var hostAndPort:String = getWebSocketHostAndPort();
		if(hostAndPort == null) {
			return;
		}

		trace("Got host and port: " + hostAndPort + ", will try to connect to WebSocket");

		var patternImageStream = new PatternImageStream();
		patternImageStream.onConnected = ()-> {
			trace("Connected WebSocket to " + hostAndPort);
		};

		patternImageStream.onMessage = function(data:Bytes) {
			if(data == null || data.length < 8) {
				trace("Failed to receive data, message too small");
				return;
			}
			trace("Received data: " + data.length + " bytes");

			// Interpret message as an RGBA8888 image with 4-byte width and height values at the start
			var width:Int = data.getInt32(0);
			var height:Int = data.getInt32(4);
			if(width * height * 4 != data.length - 8) {
				trace("Image width and height does not match total length: " + Std.string(width * height * 4) + " vs " + Std.string(data.length - 8));
				return;
			}

			// At this point the data has been validated and is good to use as a life image/pattern
			imagesReceivedFromWebSocketCount++;

			// Convert the image into a plaintext file and cache it
			// The pattern is black and white only, so squash the it down to an array of bools
			var blackAndWhite:Array<Bool> = [];
			var i = 8;
			while(i < data.length) {
				blackAndWhite.push(!(data.get(i) == 0 && data.get(i + 1) == 0 && data.get(i + 2) == 0));
				i += 4;
			}

			// NOTE the .cells extension identifies the pattern as a plaintext pattern file,
			//  hich is needed so the code that loads it up later knows what format to treat it as
			var patternName:String = "pattern_from_websocket_ " + imagesReceivedFromWebSocketCount + "_cells";
			var patternPlainText:Array<String> = PlaintextWriter.savePixelsToPlaintext(blackAndWhite, width, height, patternName);
			Reflect.setField(Patterns, patternName, patternPlainText);

			// Add option to the pattern select dropdown
			var option = Browser.document.createOptionElement();
			option.appendChild(Browser.document.createTextNode(patternName));
			option.value = patternName;
			patternPresetListElement.appendChild(option);

			// Add the newly-received pattern to the preview pane
			var grid = PatternLoader.expandToBoolGrid(patternName, Reflect.field(Patterns, patternName));
			var canvas = getCanvasForPattern(patternName, grid);
			addCanvasToPreview(patternName, canvas);

			// Select the pattern
			selectedPatternName = patternName;
		};

		patternImageStream.connect("ws://" + hostAndPort); // NOTE should be wss for HTTPS
	}
}
package;

using StringTools;

/**
 * Factory class that converts pattern files into textures etc.
 */
class PatternReader {
	public static function expandToStringArray(fileName:String, fileContent:Array<String>):Array<String> {
		return if (fileName.endsWith("rle")) {
			RLEReader.expandRle(fileContent);
		} else if (fileName.endsWith("cells")) {
			PlaintextCellsReader.expandCells(fileContent);
		} else if (fileName.endsWith("lif")) {
			//LifeReader.expandLife(fileContent); // TODO implement
			return null;
		} else {
			trace("Unsupported file in pattern embed folder: " + fileName);
			return null;
		}
	}
}

/**
 * Expands and converts "plain text" cells format patterns.
 * @see http://www.conwaylife.com/wiki/Plaintext
 */
class PlaintextCellsReader {
	public static function expandCells(cells:Array<String>):Array<String> {
		var expandedLines = [];
		
		var width:Int = 0;
		var height:Int = 0;
		for (line in cells) {
			if (line.indexOf("!") != -1) { // Ignore the ! lines
				continue;
			}
			
			if (line.length > width) {
				width = line.length;
			}
			height++;
		}
		
		for (line in cells) {
			if (line.indexOf("!") != -1) { // Ignore the ! lines
				continue;
			}
			
			var expandedLine = line;
			while (expandedLine.length < width) {
				expandedLine += ".";
			}
			expandedLines.push(expandedLine);
		}
		
		return expandedLines;
	}
}

/**
 * Expands and converts run length encoded patterns.
 * @see http://www.conwaylife.com/wiki/RLE
 */
class RLEReader {
	public static function expandRle(rle:Array<String>):Array<String> {
		var width:Int = 0;
		var height:Int = 0;
		var rule:String = "";
		var rlePattern:String = "";
		var runCountMatcher:EReg = ~/[0-9]/i;
		var foundSize:Bool = false;
		
		for (line in rle) {
			if (line.indexOf("#") != -1) {
				continue; // Ignore the # lines
			}
			
			if (!foundSize) { // Look for the width, height and rule
				var components:Array<String> = line.split(",");
				Sure.sure(components.length == 2 || components.length == 3);
				
				var getComponentValue = function(component:String):String {
					var kv = component.split("=");
					Sure.sure(kv.length == 2);
					var v = kv[1].trim();
					Sure.sure(v.length != 0);
					return v;
				}
				
				width = Std.parseInt(getComponentValue(components[0]));
				height = Std.parseInt(getComponentValue(components[1]));
				
				if(components.length == 3) {
					rule = getComponentValue(components[2]);
				}
				
				foundSize = true;
				continue;
			}
			
			rlePattern += line; // Flatten all other lines of RLE encoded b (dead) o (alive) and $ (end of line) cell descriptions into a single string
		}
		
		var result:Array<String> = [];
		var rleRows:Array<String> = rlePattern.split("$");
		for (row in rleRows) {
			var expandedRow:String = "";
			var number:String = "";
			for (i in 0...row.length) {
				var ch = row.charAt(i);
				if (runCountMatcher.match(ch)) {
					number += ch;
				} else if (ch == "o") {
					var runCount = 1;
					if(number.length > 0) {
						runCount = Std.parseInt(number);
					}
					for (i in 0...runCount) {
						expandedRow += "o";
						number = "";
					}
				} else if (ch == "b") {
					var runCount = 1;
					if(number.length > 0) {
						runCount = Std.parseInt(number);
					}
					for (i in 0...runCount) {
						expandedRow += "b";
						number = "";
					}
				}
			}
			result.push(expandedRow);
		}
		
		Sure.sure(result.length > 0);
		return result;
	}
}

// TODO implement this
/**
 * Expands and converts ASCII Life 1.0x format patterns.
 * @see http://www.conwaylife.com/wiki/Life_1.05
 * @see http://www.conwaylife.com/wiki/Life_1.06
 */
class LifeReader {
	/*
	public static function expandLife(life:Array<String>):Array<String> {
		var expandedLines = [];
		
		var formatHeader:String = life[0];
		Sure.sure(formatHeader.indexOf("Life") != -1);
		formatHeader = formatHeader.replace("Life", "");
		formatHeader = formatHeader.replace("#", "");
		formatHeader.trim();
		
		if (formatHeader.endsWith("5")) { // 1.05
			for (line in life) {
				if (line.indexOf("#") != -1) { // Ignore the # lines // TODO handle the #P items
					continue;
				}
				
				// TODO handle the blocks
			}
		} else if (formatHeader.endsWith("6")) { // 1.06
			var xMin:Int = 0;
			var yMin:Int = 0;
			var xMax:Int = 0;
			var yMax:Int = 0;
			var liveCells:Array<{x:Int, y:Int}> = [];
			for (line in life) {
				if (line.indexOf("#") != -1) { // Ignore the # lines
					continue;
				}
				
				if (line.length < 2) {
					continue;
				}
				
				// Gather the coordinates
				trace(line);
				var coordinate = line.split(" ");
				Sure.sure(coordinate.length == 2);
				
				var x = Std.parseInt(coordinate[0]);
				var y = Std.parseInt(coordinate[1]);
				
				if (x < xMin) {
					xMin = x;
				}
				if (x > xMax) {
					xMax = x;
				}
				
				if (y < yMin) {
					yMin = y;
				}
				if (y > yMax) {
					yMax = y;
				}
				
				liveCells.push({x : x, y : y});
			}
			
			var width:Int = Std.int(Math.abs(xMin - xMax));
			var height:Int = Std.int(Math.abs(yMin - yMax));
			
			// Populate grid
			var bufs:Array<StringBuf> = [];
			for (h in 0...height) {
				bufs.push(new StringBuf());
			}
			
			for (liveCell in liveCells) {
				var zeroedX:Int = liveCell.x + Std.int(Math.abs(xMin));
				var zeroedY:Int = liveCell.y + Std.int(Math.abs(yMin));
				
				var buf = bufs[zeroedY];
			}
			
			for (liveCell in liveCells) {
				var zeroedX:Int = liveCell.x + Std.int(Math.abs(xMin));
				var zeroedY:Int = liveCell.y + Std.int(Math.abs(yMin));
				
				trace(zeroedX);
				trace(zeroedY);
				
				var line = expandedLines[zeroedY];
				
				if (line == null) {
					trace("fuck");
				}
				
				trace(line);
				var updatedLine = line.substring(0, zeroedX - 1) + "x" + line.substr(zeroedX);
				expandedLines[zeroedY] = updatedLine;
			}
		} else {
			throw "Did not recognize Life format header";
		}
		
		return expandedLines;
	}
	*/
}
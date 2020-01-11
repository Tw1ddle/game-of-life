package life;

using StringTools;

/**
 * Factory class that converts pattern files into grids of bools.
 */
class PatternLoader {
	public static function expandToBoolGrid(fileName:String, fileContent:Array<String>):Array<Array<Bool>> {
		return if (fileName.endsWith("rle")) {
			RLEReader.expandRle(fileContent);
		} else if (fileName.endsWith("cells")) {
			PlaintextCellsReader.expandCells(fileContent);
		} else if (fileName.endsWith("lif")) {
			LifeReader.expandLife(fileContent);
		} else {
			trace("Unsupported file in pattern embed folder: " + fileName);
			return null;
		}
	}
}

/**
 * Expands and converts run length encoded patterns.
 * @see https://www.conwaylife.com/wiki/RLE
 */
class RLEReader {
	public static function expandRle(rle:Array<String>):Array<Array<Bool>> {
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
		
		var result:Array<Array<Bool>> = [[]];
		var rleRows = rlePattern.replace("$", "$-").split("-");
		for (row in rleRows) {
			var expandedRow:Array<Bool> = [];
			var number:String = "";
			for (letter in 0...row.length) {
				var ch = row.charAt(letter);
				if (runCountMatcher.match(ch)) {
					number += ch;
				} else if (ch == "o") {
					var runCount = 1;
					if(number.length > 0) {
						runCount = Std.parseInt(number);
					}
					for (i in 0...runCount) {
						expandedRow.push(true);
						number = "";
					}
				} else if (ch == "b") {
					var runCount = 1;
					if(number.length > 0) {
						runCount = Std.parseInt(number);
					}
					for (i in 0...runCount) {
						expandedRow.push(false);
						number = "";
					}
				} else if (ch == "$") {
					Sure.sure(letter == row.length - 1);
					result.push(expandedRow);
					var runCount = 1;
					if(number.length > 0) {
						runCount = Std.parseInt(number);
					}
					var blankRow = [];
					for (i in 0...width) {
						blankRow.push(false);
					}
					for (i in 0...runCount - 1) {
						result.push(blankRow.copy());
					}
					number = "";
				}
			}
			
			if(row.indexOf("!") != -1 && row.indexOf("#") == -1) {// Catch the final line if it doesn't contain a $
				result.push(expandedRow);
			}
		}
		
		for (row in result) {
			while (row.length < width) {
				row.push(false);
			}
		}
		
		Sure.sure(result.length > 0);
		return result;
	}
}

/**
 * Expands and converts "plain text" cells format patterns.
 * @see https://www.conwaylife.com/wiki/Plaintext
 */
class PlaintextCellsReader {
	public static function expandCells(cells:Array<String>):Array<Array<Bool>> {
		var expandedLines = [[]];
		
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
			
			var expandedLine:Array<Bool> = [];
			
			for (i in 0...line.length) {
				expandedLine.push(line.charAt(i) == "." ? false : true);
			}
			
			while (expandedLine.length < width) {
				expandedLine.push(false);
			}
			
			expandedLines.push(expandedLine);
		}
		
		return expandedLines;
	}
}

/**
 * Expands and converts ASCII Life 1.0x format patterns.
 * @see https://www.conwaylife.com/wiki/Life_1.05
 * @see https://www.conwaylife.com/wiki/Life_1.06
 */
class LifeReader {
	public static function expandLife(life:Array<String>):Array<Array<Bool>> {
		var expandedLines = [[]];
		
		var formatHeader:String = life[0];
		Sure.sure(formatHeader.indexOf("Life") != -1);
		formatHeader = formatHeader.replace("Life", "");
		formatHeader = formatHeader.replace("#", "");
		formatHeader.trim();
		
		if (formatHeader.endsWith("5")) { // 1.05
			var blockOriginX:Int = 0;
			var blockOriginY:Int = 0;
			var cells:Array<{x:Int, y:Int, live:Bool}> = [];
			var xMin:Int = 0;
			var yMin:Int = 0;
			var y:Int = 0;
			for (line in life) {
				if (line.length == 0) { // Ignore empty lines
					continue;
				} else if (line.indexOf("#p") != -1 || line.indexOf("#P") != -1) { // Get the cell block top left origin
					var coordinate = line.split(" ");
					Sure.sure(coordinate.length == 3);
					
					y = 0;
					blockOriginX = Std.parseInt(coordinate[1]);
					blockOriginY = Std.parseInt(coordinate[2]);
					if (blockOriginX < xMin) {
						xMin = blockOriginX;
					}
					if (blockOriginY < yMin) {
						yMin = blockOriginY;
					}
					
					continue;
				} else if (line.indexOf("#") != -1) { // Ignore any other # lines
					continue;
				}
				
				// Should be a line of dots and stars
				for (x in 0...line.length) {
					if (line.charAt(x) == ".") {
						cells.push({ x: x + blockOriginX, y: y + blockOriginY, live: false});
					} else if (line.charAt(x) == "*") {
						cells.push({ x: x + blockOriginX, y: y + blockOriginY, live: true});
					}
				}
				y++;
			}
			
			var xMax:Int = 0;
			var yMax:Int = 0;
			for (i in 0...cells.length) {
				if (cells[i].x > xMax) {
					xMax = cells[i].x;
				}
				if (cells[i].y > yMax) {
					yMax = cells[i].y;
				}
			}
			
			var width:Int = Std.int(Math.abs(xMin - xMax));
			var height:Int = Std.int(Math.abs(yMin - yMax));
			
			// Fill grid with falses
			for (y in 0...height) {
				var line = [];
				for (x in 0...width) {
					line.push(false);
				}
				expandedLines.push(line);
			}
			
			// Fill in the cells
			for (cell in cells) {
				expandedLines[cell.y - yMin][cell.x - xMin] = cell.live;
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
				
				if (line.length < 2) { // Blank lines or ones with spaces?
					continue;
				}
				
				// Gather the live cell coordinates
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
			
			// Fill grid with falses
			for (y in 0...height) {
				var line = [];
				for (x in 0...width) {
					line.push(false);
				}
				expandedLines.push(line);
			}
			
			// Fill in the live cells
			for (cell in liveCells) {
				expandedLines[cell.y - yMin][cell.x - xMin] = true;
			}
		} else {
			throw "Did not recognize Life format header";
		}
		
		return expandedLines;
	}
}
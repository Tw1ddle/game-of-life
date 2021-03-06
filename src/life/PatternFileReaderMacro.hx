package life;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr.Access.APublic;
import haxe.macro.Expr.Access.AStatic;
import haxe.macro.Expr.Field;
import haxe.macro.Expr.FieldType.FVar;
import util.FileReader;
import sys.FileSystem;

using StringTools;

/**
 * Build macro for reading Life patterns from files at compile time
 */
@:access(util.FileReader)
class PatternFileReaderMacro {
	public static function build(directoryPath:String):Array<Field> {
		var fields = Context.getBuildFields();
		
		var splitter = new EReg("\\r\\n|\\n|\\r", "g");
		
        try {
            var files = FileSystem.readDirectory(directoryPath);
            for (i in 0...files.length) {
				if(FileSystem.isDirectory(directoryPath + "/" + files[i])) {
					continue; // Skip directories
				}
				
				if (files[i].endsWith(".md")) {
					//trace("Skipping non-pattern: " + files[i]);
					continue; // Skip readme
				}
				
                var data = FileReader.loadFileAsString(directoryPath + "/" + files[i]);
				
				var file = files[i];
				
				// Take a filename e.g. 1beacon.cells and replace disallowed characters with underscores: 1beacon_cells
				// Also remove leading numbers (Haxe field names have restrictions on them)
				var name = "pattern_" + file.replace(".", "_").replace("+", "_").replace("-", "_");
				
				var lines = splitter.split(data);
				
				// Remove empty lines
				//lines = Lambda.array(Lambda.filter(lines, function(line:String):Bool {
				//	return line.length != 0 && line.trim().length != 0;
				//}));

				var field = {
					name: name,
					doc: file,
					meta: [],
					access: [APublic, AStatic],
					kind: FVar(macro:Array<String>, macro $v{lines}),
					pos: Context.currentPos()
				};
				
				fields.push(field);
            }
        } catch (e:Dynamic) {
            Context.error('Failed to find directory $directoryPath: $e', Context.currentPos());
        }
		
		return fields;
	}
}

#end
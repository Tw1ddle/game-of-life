package life;

import life.PatternFileReaderMacro;

// Stores the embedded pattern files from the /embed folder as arrays of strings for use at runtime
@:build(life.PatternFileReaderMacro.build("embed"))
@:keep
class Patterns {
}
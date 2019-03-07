package;

// Stores the embedded pattern files from the /embed folder as arrays of strings for use at runtime
@:build(PatternFileReaderMacro.build("embed"))
@:keep
class Patterns {
}
module webadapter.utils;

public import std.stdio;

alias p    = std.stdio.writeln;
alias puts = std.stdio.writeln;

class ArgumentError : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}
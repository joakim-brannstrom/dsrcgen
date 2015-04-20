/// Written in the D programming language.
/// Date: 2015, Joakim Brännström
/// License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
/// Author: Joakim Brännström (joakim.brannstrom@gmx.com)
module dsrcgen.base;
import std.algorithm;
import std.ascii;
import std.conv;

struct KV {
    string k;
    string v;

    this(T)(string k, T v) {
        this.k = k;
        this.v = to!string(v);
    }
}

struct AttrSetter {
    static AttrSetter instance;

    template opDispatch(string name) {
        @property auto opDispatch(T)(T v) {
            static if (name.length > 1 && name[$ - 1] == '_') {
                return KV(name[0 .. $ - 1], v);
            }
            else {
                return KV(name, v);
            }
        }
    }
}

interface BaseElement {
    abstract string render();
    abstract string _render_indent(int level);
    abstract string _render_recursive(int level);
    abstract string _render_post_recursive(int level);
}

class Text(T) : T {
    string contents;
    this(string contents) {
        this.contents = contents;
    }

    override string _render_indent(int level) {
        return contents;
    }
}

class BaseModule : BaseElement {
    int indent_width = 4;

    BaseElement[] children;
    int sep_lines;
    int suppress_indent_;

    this() {
    }

    this(int indent_width) {
        this.indent_width = indent_width;
    }

    /// Number of levels to suppress indent
    void suppress_indent(int levels) {
        this.suppress_indent_ = levels;
    }

    void set_indentation(int ind) {
        this.indent_width = ind;
    }

    auto reset() {
        children.length = 0;
        return this;
    }

    /// Separate with at most count empty lines.
    void sep(int count = 1) {
        count -= sep_lines;
        if (count <= 0)
            return;
        foreach (i; 0 .. count) {
            children ~= new Text!(typeof(this))(newline);
        }

        sep_lines += count;
    }

    string indent(string s, int level) {
        level = max(0, level);
        char[] indent;
        indent.length = indent_width * level;
        indent[] = ' ';

        return to!string(indent) ~ s;
    }

    void append(BaseElement e) {
        children ~= e;
        sep_lines = 0;
    }

    override string _render_indent(int level) {
        return "";
    }

    override string _render_recursive(int level) {
        level -= suppress_indent_;
        string s = _render_indent(level);

        foreach (e; children) {
            s ~= e._render_recursive(level + 1);
        }
        s ~= _render_post_recursive(level);

        return s;
    }

    override string _render_post_recursive(int level) {
        return "";
    }

    override string render() {
        string s = _render_indent(0);
        foreach (e; children) {
            s ~= e._render_recursive(0 - suppress_indent_);
        }
        s ~= _render_post_recursive(0);

        return _render_recursive(0);
    }
}

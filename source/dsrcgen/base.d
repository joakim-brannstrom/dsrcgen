/// Written in the D programming language.
/// Date: 2015, Joakim Brännström
/// License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
/// Author: Joakim Brännström (joakim.brannstrom@gmx.com)
module dsrcgen.base;

struct KV {
    string k;
    string v;

    this(T)(string k, T v) {
        import std.conv : to;

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
    abstract string _render_indent(int parent_level, int level);
    abstract string _render_recursive(int parent_level, int level);
    abstract string _render_post_recursive(int parent_level, int level);
}

class Text(T) : T {
    private string contents;

    this(string contents) {
        this.contents = contents;
    }

    override string _render_indent(int parent_level, int level) {
        return contents;
    }
}

class BaseModule : BaseElement {
    this() {
    }

    this(int indent_width) {
        this.indent_width = indent_width;
    }

    /// Number of levels to suppress indent of children.
    /// Propagated to leafs.
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
        import std.ascii : newline;

        count -= sep_lines;
        if (count <= 0)
            return;
        foreach (i; 0 .. count) {
            children ~= new Text!(typeof(this))(newline);
        }

        sep_lines += count;
    }

    void append(BaseElement e) {
        children ~= e;
        sep_lines = 0;
    }

    string indent(string s, int parent_level, int level) {
        import std.algorithm : max;
        import std.conv : to;

        level = max(0, parent_level, level);
        char[] indent;
        indent.length = indent_width * level;
        indent[] = ' ';

        return to!string(indent) ~ s;
    }

    override string _render_indent(int parent_level, int level) {
        return "";
    }

    override string _render_recursive(int parent_level, int level) {
        import std.algorithm : max;

        string s = _render_indent(parent_level, level);

        // suppressing is intented to affects children. The current leaf is
        // intented according to the parent or propagated level.
        int child_level = level - suppress_indent_;
        foreach (e; children) {
            // lock indent to the level of the parent. it allows a suppression of many levels of children.
            s ~= e._render_recursive(max(parent_level, child_level), child_level + 1);
        }
        s ~= _render_post_recursive(parent_level, level);

        return s;
    }

    override string _render_post_recursive(int parent_level, int level) {
        return "";
    }

    override string render() {
        return _render_recursive(0 - suppress_indent_, 0 - suppress_indent_);
    }

private:
    int indent_width = 4;
    int suppress_indent_;

    BaseElement[] children;
    int sep_lines;
}

/// Written in the D programming language.
/// Date: 2015, Joakim Brännström
/// License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
/// Author: Joakim Brännström (joakim.brannstrom@gmx.com)
module dsrcgen.cpp;
import std.algorithm;
import std.ascii;
import std.conv;
import std.string;

import tested;

import dsrcgen.base;
import dsrcgen.c;

version (unittest) {
    shared static this() {
        import std.exception;

        enforce(runUnitTests!(dsrcgen.cpp)(new ConsoleTestResultWriter), "Unit tests failed.");
    }
}

mixin template CppModuleX() {
    // Suites
    /** Suites for C++ definitions for a class.
     * Useful for implementiong ctor, dtor and member methods for a class.
     * Params:
     *  class_name = name of the class.
     *  headline = whatever to append after class_name.
     * Example:
     * ----
     * class_suite("Simple", "Simple()");
     * ----
     * Generated code:
     * ----
     * Simple::Simple() {
     * }
     * ----
     */
    auto class_suite(T0, T1)(T0 class_name, T1 headline) {
        auto tmp = format("%s::%s", to!string(class_name), to!string(headline));
        auto e = new Suite!(typeof(this))(to!string(tmp));
        append(e);
        return e;
    }

    auto class_suite(T0, T1, T2)(T0 rval, T1 class_name, T1 headline) {
        auto tmp = format("%s %s::%s", to!string(rval),
            to!string(class_name), to!string(headline));
        auto e = new Suite!(typeof(this))(to!string(tmp));
        append(e);
        return e;
    }

    auto ctor(T0, T...)(T0 class_name, auto ref T args) {
        string params = this.paramsToString(args);

        auto e = suite(format("%s(%s)", to!string(class_name), params));
        return e;
    }

    auto ctor(T)(T class_name) {
        auto e = suite(format("%s()", to!string(class_name)));
        return e;
    }

    auto ctor_body(T0, T...)(T0 class_name, auto ref T args) {
        string params = this.paramsToString(args);

        auto e = class_suite(class_name, format("%s(%s)", to!string(class_name), params));
        return e;
    }

    auto ctor_body(T)(T class_name) {
        auto e = class_suite(class_name, format("%s()", to!string(class_name)));
        return e;
    }

    /** Virtual d'tor.
     * Params:
     *  virtual_ = if evaluated to true prepend with virtual.
     *  class_name = name of the class to create a d'tor for.
     * Example:
     * ----
     * dtor(true, "Foo");
     * ----
     * TODO better solution for virtual. A boolean is kind of adhoc.
     */
    auto dtor(T)(bool virtual_, T class_name) {
        auto e = suite(format("%s%s%s()", virtual_ ? "virtual " : "",
            class_name[0] == '~' ? "" : "~", to!string(class_name)));
        return e;
    }

    auto dtor(T)(T class_name) {
        auto e = suite(format("%s%s()", class_name[0] == '~' ? "" : "~", to!string(class_name)));
        return e;
    }

    /// Definition for a dtor.
    auto dtor_body(T)(T class_name) {
        string s = to!string(class_name);
        if (s[0] == '~') {
            s = s[1 .. $];
        }
        auto e = class_suite(class_name, format("~%s()", s));
        return e;
    }

    auto namespace(T)(T name) {
        string n = to!string(name);
        auto e = suite(format("namespace %s", n));
        e[$.end = format("} //NS:%s%s", n, newline)];
        return e;
    }

    auto class_(T)(T name) {
        string n = to!string(name);
        auto e = suite(format("class %s", n));
        e[$.end = format("};%s", newline)];
        return e;
    }

    auto class_(T0, T1)(T0 name, T1 inherit) {
        string n = to!string(name);
        string ih = to!string(inherit);
        if (ih.length == 0) {
            return class_(name);
        }
        else {
            auto e = suite(format("class %s : %s", n, ih));
            e[$.end = format("};%s", newline)];
            return e;
        }
    }

    auto public_() {
        auto e = suite("public:");
        e[$.begin = newline, $.end = ""];
        return e;
    }

    auto protected_() {
        auto e = suite("protected:");
        e[$.begin = newline, $.end = ""];
        return e;
    }

    auto private_() {
        auto e = suite("private:");
        e[$.begin = newline, $.end = ""];
        return e;
    }

    auto method(T0, T1)(bool virtual_, T0 return_type, T1 name, bool const_) {
        auto e = suite(format("%s%s %s()%s", virtual_ ? "virtual " : "",
            to!string(return_type), to!string(name), const_ ? " const" : ""));
        return e;
    }

    auto method(T0, T1, T...)(bool virtual_, T0 return_type, T1 name, bool const_,
        auto ref T args) {
        string params = this.paramsToString(args);

        auto e = suite(format("%s%s %s(%s)%s", virtual_ ? "virtual " : "",
            to!string(return_type), to!string(name), params, const_ ? " const" : ""));
        return e;
    }

    auto method_body(T0, T1, T2)(T0 return_type, T1 class_name, T2 name, bool const_) {
        auto e = suite(format("%s %s::%s()%s", to!string(return_type),
            to!string(class_name), to!string(name), const_ ? " const" : ""));
        return e;
    }

    auto method_body(T0, T1, T2, T...)(in T0 return_type, in T1 class_name,
        in T2 name, bool const_, auto ref T args) {
        string params = this.paramsToString(args);

        auto e = suite(format("%s %s::%s(%s)%s", to!string(return_type),
            to!string(class_name), to!string(name), params, const_ ? " const" : ""));
        return e;
    }

private:
    string paramsToString(T...)(auto ref T args) {
        string params;
        if (args.length >= 1) {
            params = to!string(args[0]);
        }
        if (args.length >= 2) {
            foreach (v; args[1 .. $]) {
                params ~= ", " ~ to!string(v);
            }
        }
        return params;
    }
}

class CppModule : BaseModule {
    mixin CModuleX;
    mixin CppModuleX;
}

/// Code generation for C++ header.
struct CppHModule {
    CppModule doc;
    CppModule header;
    CppModule content;
    CppModule footer;

    this(string ifdef_guard) {
        // Must suppress indentation to generate what is expected by the user.
        doc = new CppModule;
        with (doc) {
            // doc is a container of the modules so should not affect indent.
            // header, content and footer is containers so should not affect indent.
            // ifndef guard usually never affect indent.
            suppress_indent(1);
            header = base;
            header.suppress_indent(1);
            with (IFNDEF(ifdef_guard)) {
                suppress_indent(1);
                define(ifdef_guard);
                content = base;
                content.suppress_indent(1);
            }
            footer = base;
            footer.suppress_indent(1);
        }
    }

    auto render() {
        return doc.render();
    }
}

@name("Test of C++ suits") unittest {
    string expect = "
    namespace foo {
    } //NS:foo
    class Foo {
        Foo();
        Foo(int y);
        ~Foo();
    };
    class Foo : Bar {
    };
    public:
        return 5;
    protected:
        return 7;
    private:
        return 8;
";
    auto x = new CppModule();
    with (x) {
        sep;
        namespace("foo");
        with (class_("Foo")) {
            auto ctor0 = ctor("Foo");
            ctor0[$.begin = "", $.end = ";" ~ newline, $.noindent = true];
            auto ctor1 = ctor("Foo", "int y");
            ctor1[$.begin = "", $.end = ";" ~ newline, $.noindent = true];
            auto dtor0 = dtor("Foo");
            dtor0[$.begin = "", $.end = ";" ~ newline, $.noindent = true];
        }
        class_("Foo", "Bar");
        with (public_) {
            return_(5);
        }
        with (protected_) {
            return_(7);
        }
        with (private_) {
            return_(8);
        }
    }

    auto rval = x.render();
    assert(rval == expect, rval);
}

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
    auto ctor(T0, T...)(T0 class_name, auto ref T args) {
        string params;
        if (args.length >= 1) {
            params = to!string(args[0]);
        }
        if (args.length >= 2) {
            foreach (v; args[1 .. $]) {
                params ~= ", " ~ to!string(v);
            }
        }

        auto e = suite(format("%s(%s)", to!string(class_name), params));
        return e;
    }

    auto ctor(T)(T class_name) {
        auto e = suite(format("%s()", to!string(class_name)));
        return e;
    }

    auto dtor(T)(T class_name) {
        auto e = suite(format("%s%s()", class_name[0] == '~' ? "" : "~", to!string(class_name)));
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
}

class CppModule : BaseModule {
    mixin CModuleX;
    mixin CppModuleX;
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

module datastructure;

import std.algorithm, std.container.rbtree, std.functional, std.range, std.traits, std.typecons;
import std.exception : enforce;
import std.array : empty, front, popFront;
import core.exception : RangeError;

/// Key-value storage with sorted keys.
SortedKeyValue!(Key, Value, less) sortedKeyValue(Key, Value, alias less="a<b")()
{
    alias Ret = typeof (return);
    alias Impl = typeof (Ret.init.impl);
    return Ret(new Impl);
}
/// ditto
struct SortedKeyValue(Key, Value, alias less="a<b")
{
    /// associative array operations.
    Value opIndexAssign(in Value value, in Key key)
    {
        remove(key);
        impl.insert(KV(key, value));
        return value;
    }
    /// ditto
    Value opIndexOpAssign(string op, V)(in V value, in Key key)
        if (is (typeof (mixin ("Value.init"~op~"V.init")) : Value))
    {
        return opIndexAssign(mixin ("opIndex(key)"~op~"value"), key);
    }
    /// ditto
    Value opIndex(in Key key) const
    {
        auto _ret = impl.equalRange(KV(key, Value.init));
        (!_ret.empty).enforce!RangeError("Range violation: no key in KeyValueTree");
        auto ret = _ret.front[1];
        _ret.popFront;
        assert (_ret.empty, "Multiple values for the same key");
        return ret;
    }
    /// ditto
    @property bool empty() const
    {
        return length == 0;
    }
    /// ditto
    bool remove(in Key key)
    {
        auto kv = KV(key, Value.init);
        if (kv !in impl)
            return false;
        impl.removeKey(kv);
        return true;
    }
    /// ditto
    @property size_t length() const
    {
        return impl.length;
    }
    /// ditto
    void clear()
    {
        impl.clear;
    }
    /// ditto
    auto byKey()
    {
        return impl[].map!(_ => _.key);
    }
    /// ditto
    auto byValue()
    {
        return impl[].map!(_ => _.value);
    }
    /// ditto
    auto byKeyValue()
    {
        return impl[];
    }
    /// ditto
    alias opIndex = byKeyValue;
    /// smallest key according to less, and its associated value.
    KV front()
    {
        return impl.front;
    }
    /// ditto
    Key frontKey()
    {
        return front.key;
    }
    /// ditto
    Value frontValue()
    {
        return front.value;
    }
    /// largest key according to less, and its associated value.
    KV back()
    {
        return impl.back;
    }
    /// ditto
    Key backKey()
    {
        return back.key;
    }
    /// ditto
    Value backValue()
    {
        return back.value;
    }
    /// remove the smallest element according to less.
    void removeFront()
    {
        impl.removeFront;
    }
    /// remove the largest element according to less.
    void removeBack()
    {
        impl.removeBack;
    }
private:
    alias KV = Tuple!(Key, "key", Value, "value");
    RedBlackTree!(KV, ((a, b) => binaryFun!less(a[0], b[0]))) impl;
}
///
unittest
{
    import std.exception;
    auto t = sortedKeyValue!(int, int);
    t[0].assertThrown!RangeError;
    t[0] = 0;
    t[1] = 1;
    assert (t.length == 2 && t[0] == 0 && t[1] == 1);
    t[0] = 2;
    assert (t.length == 2 && t[0] == 2 && t[1] == 1);
    assert (t.byKey.equal([0, 1]));
    assert (t.byValue.equal([2, 1]));
    assert (t[].equal([t.KV(0, 2), t.KV(1, 1)]));
    t.clear;
    assert (t.empty);
}
///
unittest
{
    auto t = sortedKeyValue!(int, int);
    t[0] = 0;
    t[1] = 1;
    t[2] = 2;
    t[3] = 3;
    assert (t.frontKey == 0);
    t.removeFront;
    assert (t.frontValue == 1);
    assert (t.backKey == 3);
    t.removeBack;
    assert (t.backValue == 2);
}
/// helper functions for SortedKeyValue.
auto sortedKeyValue(alias less="a<b", AA)(AA aa)
    if (isAssociativeArray!AA)
{
    static if (is (AA : Value[Key], Key, Value))
    {
        auto ret = sortedKeyValue!(Key, Value, less);
        foreach (kv; aa.byKeyValue)
            ret[kv.key] = kv.value;
        return ret;
    }
    else static assert (false);
}
/// ditto
auto sortedKeyValue(alias less="a<b", TR)(TR elems)
    if (isInputRange!TR && is (typeof (elems.front[0])) && is (typeof (elems.front[1])))
{
    alias Key = typeof (ElementType!TR.init[0]);
    alias Value = typeof (ElementType!TR.init[1]);
    auto ret = sortedKeyValue!(Key, Value, less);
    foreach (kv; elems)
        ret[kv[0]] = kv[1];
    return ret;
}
///
unittest
{
    auto t = sortedKeyValue!(int, int);
    t[0] = 1;
    t[1] = 2;
    t[2] = 3;
    t[3] = 4;
    t[3] %= 4;
    assert (t[3] == 0);
    assert ([0:1, 1:2, 2:3, 3:0].sortedKeyValue[].equal(t[]));
    assert ([[0, 1], [1, 2], [2, 3], [3, 0]].sortedKeyValue[].equal(t[]));
    alias T = Tuple!(int, int);
    alias P = Tuple!(int, "myKey", int, "myValue");
    assert ([T(0, 1), T(1, 2), T(2, 3), T(3, 0)].sortedKeyValue[].equal(t[]));
    assert ([P(0, 1), P(1, 2), P(2, 3), P(3, 0)].sortedKeyValue[].equal(t[]));
}

/// Key-value storage with sorted keys.
KeySortedValue!(Key, Value, lessValue, lessKey) keySortedValue(Key, Value, alias lessValue="a<b", alias lessKey="a<b")()
{
    alias Ret = typeof (return);
    alias ImplKV = typeof (Ret.init.implKV);
    alias ImplVK = typeof (Ret.init.implVK);
    return Ret(new ImplVK);
}
/// ditto
struct KeySortedValue(Key, Value, alias lessValue="a<b", alias lessKey="a<b")
{
    /// associative array operations.
    Value opIndexAssign(in Value value, in Key key)
    {
        remove(key);
        implKV[key] = value;
        implVK.insert(VK(value, key));
        return value;
    }
    /// ditto
    Value opIndexOpAssign(string op, V)(in V value, in Key key)
        if (is (typeof (mixin ("Value.init"~op~"V.init")) : Value))
    {
        return opIndexAssign(mixin ("opIndex(key)"~op~"value"), key);
    }
    /// ditto
    Value opIndex(in Key key) const
    {
        return implKV[key];
    }
    /// ditto
    @property bool empty() const
    {
        return length == 0;
    }
    /// ditto
    bool remove(in Key key)
    {
        if (auto vp = key in implKV)
            implVK.removeKey(VK(*vp, key));
        return implKV.remove(key);
    }
    /// ditto
    @property size_t length() const
    {
        return implKV.length;
    }
    /// ditto
    void clear()
    {
        implKV.clear;
        implVK.clear;
    }
    /// ditto
    auto byKey()
    {
        return implVK[].map!(_ => _.key);
    }
    /// ditto
    auto byValue()
    {
        return implVK[].map!(_ => _.value);
    }
    /// ditto
    auto byKeyValue()
    {
        return implVK[].map!(_ => KV(_.key, _.value));
    }
    /// ditto
    alias opIndex = byKeyValue;
    invariant
    {
        assert (implKV.length == implVK.length);
    }
private:
    alias VK = Tuple!(Value, "value", Key, "key");
    alias KV = Tuple!(Key, "key", Value, "value");
    RedBlackTree!(VK, ((a, b) => binaryFun!lessValue(a.value, b.value) || (!binaryFun!lessValue(b.value, a.value) && binaryFun!lessKey(a.key, b.key)))) implVK;
    Value[Key] implKV;
}
///
unittest
{
    import std.exception;
    auto t = keySortedValue!(int, int);
    t[0].assertThrown!RangeError;
    t[0] = 0;
    t[1] = 1;
    assert (t.length == 2 && t[0] == 0 && t[1] == 1);
    t[0] += 2;
    assert (t.length == 2 && t[0] == 2 && t[1] == 1);
    assert (t.byKey.equal([1, 0]));
    assert (t.byValue.equal([1, 2]));
    assert (t[].equal([t.KV(1, 1), t.KV(0, 2)]));
    t.clear;
    assert (t.empty);
}
/// helper functions for SortedKeyValue.
auto keySortedValue(alias lessValue="a<b", alias lessKey="a<b", AA)(AA aa)
    if (isAssociativeArray!AA)
{
    static if (is (AA : Value[Key], Key, Value))
    {
        auto ret = keySortedValue!(Key, Value, lessValue, lessKey);
        foreach (kv; aa.byKeyValue)
            ret[kv.key] = kv.value;
        return ret;
    }
    else static assert (false);
}
/// ditto
auto keySortedValue(alias lessValue="a<b", alias lessKey="a<b", TR)(TR elems)
    if (isInputRange!TR && is (typeof (elems.front[0])) && is (typeof (elems.front[1])))
{
    alias Key = typeof (ElementType!TR.init[0]);
    alias Value = typeof (ElementType!TR.init[1]);
    auto ret = keySortedValue!(Key, Value, lessValue, lessKey);
    foreach (kv; elems)
        ret[kv[0]] = kv[1];
    return ret;
}
///
unittest
{
    auto t = keySortedValue!(int, int);
    t[0] = 1;
    t[1] = 2;
    t[2] = 3;
    t[3] = 4;
    t[3] %= 4;
    assert (t[3] == 0);
    assert ([0:1, 1:2, 2:3, 3:0].keySortedValue[].equal(t[]));
    assert ([[0, 1], [1, 2], [2, 3], [3, 0]].keySortedValue[].equal(t[]));
    alias T = Tuple!(int, int);
    alias P = Tuple!(int, "myKey", int, "myValue");
    assert ([T(0, 1), T(1, 2), T(2, 3), T(3, 0)].keySortedValue[].equal(t[]));
    assert ([P(0, 1), P(1, 2), P(2, 3), P(3, 0)].keySortedValue[].equal(t[]));
}

unittest
{
    import std.stdio : stderr;
    stderr.writefln("All green: %s", __MODULE__);
}

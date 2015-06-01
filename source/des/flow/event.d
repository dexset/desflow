module des.flow.event;

import std.traits;
import std.string : format;

import core.time;

import des.stdx.pdata;

import des.flow.base;
import des.flow.sysevdata;

///
interface EventProcessor { /++ +/ void processEvent( in Event ); }

///
interface EventBus { /++ +/ void pushEvent( in Event ); }

/// Pass data between threads
struct Event
{
    /// `ulong.max` reserved system event code
    enum system_code = ulong.max;

    alias typeof(this) Self;

    ///
    ulong code;

    ///
    ulong timestamp;

    /// information in event
    PData data;

    /++ generate system event
        returns:
         Event
     +/
    static auto system( SysEvData sed )
    {
        Self ev;
        ev.code = system_code;
        ev.timestamp = currentTick;
        ev.data = PData(sed);
        return ev;
    }

    ///
    this(T)( ulong code, in T value )
        if( is( typeof(PData(value)) ) )
    in {
        assert( code != system_code,
                "can't create event by system code" );
    }
    body {
        this.code = code;
        timestamp = currentTick;
        data = PData(value);
    }

    private enum base_ctor =
    q{
        this( in Event ev ) %s
        {
            code = ev.code;
            timestamp = ev.timestamp;
            data = ev.data;
        }
    };

    mixin( format( base_ctor, "" ) );
    mixin( format( base_ctor, "const" ) );
    mixin( format( base_ctor, "immutable" ) );
    mixin( format( base_ctor, "shared" ) );
    mixin( format( base_ctor, "shared const" ) );

    @property
    {
        ///
        bool isSystem() pure const
        { return code == system_code; }

        /// elapsed time before create event
        ulong elapsed() const
        { return currentTick - timestamp; }

        /// get data as type T
        T as(T)() const { return data.as!T; }
        /// get data as type T
        T as(T)() shared const { return data.as!T; }
        /// get data as type T
        T as(T)() immutable { return data.as!T; }

        ///
        immutable(void)[] getUntypedData() const { return data.data; }
        ///
        immutable(void)[] getUntypedData() shared const { return data.data; }
        ///
        immutable(void)[] getUntypedData() immutable { return data.data; }
    }
}

///
unittest
{
    auto a = Event( 1, [ 0.1, 0.2, 0.3 ] );
    assertEq( a.as!(double[]), [ 0.1, 0.2, 0.3 ] );
    auto b = Event( 1, "some string"w );
    assertEq( b.as!wstring, "some string"w );
    auto c = Event( 1, "some str" );
    auto d = shared Event( c );
    assertEq( c.as!string, "some str" );
    assertEq( d.as!string, "some str" );
    assertEq( c.code, d.code );

    struct TestStruct { double x, y; string info; immutable(int)[] data; }

    auto ts = TestStruct( 10.1, 12.3, "hello", [1,2,3,4] );
    auto e = Event( 1, ts );

    auto f = shared Event( e );
    auto g = immutable Event( e );
    auto h = shared const Event( e );

    assertEq( e.as!TestStruct, ts );
    assertEq( f.as!TestStruct, ts );
    assertEq( g.as!TestStruct, ts );
    assertEq( h.as!TestStruct, ts );

    assertEq( Event(f).as!TestStruct, ts );
    assertEq( Event(g).as!TestStruct, ts );
    assertEq( Event(h).as!TestStruct, ts );
}

unittest
{
    auto a = Event( 1, [ 0.1, 0.2, 0.3 ] );
    assert( !a.isSystem );
    auto b = Event.system( SysEvData.init );
    assert( b.isSystem );
}

unittest
{
    static class Test { int[string] info; }
    static assert( !__traits(compiles,PData(0,new Test)) );
}

unittest
{
    import std.conv;
    import std.string;

    static class Test
    {
        int[string] info;

        static Test load( in void[] data )
        {
            auto str = cast(string)data.dup;
            auto elems = str.split(",");
            int[string] buf;
            foreach( elem; elems )
            {
                auto key = elem.split(":")[0];
                auto val = to!int( elem.split(":")[1] );
                buf[key] = val;
            }
            return new Test( buf );
        }

        this( in int[string] I )
        {
            foreach( key, val; I )
                info[key] = val;
            info.rehash();
        }

        auto dump() const
        {
            string[] buf;
            foreach( key, val; info ) buf ~= format( "%s:%s", key, val );
            return cast(immutable(void)[])( buf.join(",").idup );
        }
    }

    auto tt = new Test( [ "ok":1, "no":3, "yes":5 ] );
    auto a = Event( 1, tt.dump() );
    auto ft = Test.load( a.data );
    assertEq( tt.info, ft.info );
    tt.info.remove("yes");
    assertNotEq( tt.info, ft.info );

    auto b = Event( 1, "ok:1,no:3" );
    auto ft2 = Test.load( b.data );
    assertEq( tt.info, ft2.info );
}

///
unittest
{
    static struct TestStruct { double x, y; string info; immutable(int)[] data; }
    auto ts = TestStruct( 3.14, 2.7, "hello", [ 2, 3, 4 ] );

    auto a = Event( 8, ts );
    auto ac = const Event( a );
    auto ai = immutable Event( a );
    auto as = shared Event( a );
    auto acs = const shared Event( a );

    assertEq( a.as!TestStruct, ts );
    assertEq( ac.as!TestStruct, ts );
    assertEq( ai.as!TestStruct, ts );
    assertEq( as.as!TestStruct, ts );
    assertEq( acs.as!TestStruct, ts );
}

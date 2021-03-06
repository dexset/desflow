module des.flow.base;

import std.datetime;

///
class FlowException : Exception
{
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) @safe pure nothrow 
    { super( msg, file, line ); }
}

/// Control work element commands
enum Command
{
    START, ///
    PAUSE, ///
    STOP,  ///
    REINIT,/// destroy work element and create it
    CLOSE  /// destroy work element
};


package
{
    import des.ts;
    import des.log;
    import des.arch.emm;

    @property ulong currentTick() { return Clock.currAppTick().length; }

    version(unittest)
    {
        import std.math;
        import std.traits;
        import std.range;

        bool creationTest(T)( T a )
            if( is( Unqual!T == T ) )
        {
            auto cn_a = const T( a );
            auto im_a = immutable T( a );
            auto sh_a = shared T( a );
            auto sc_a = shared const T( a );
            auto si_a = shared immutable T( a );
            auto a_cn = T( cn_a );
            auto a_im = T( im_a );
            auto a_sh = T( sh_a );
            auto a_sc = T( sc_a );
            auto a_si = T( si_a );
            return a_cn == a &&
                   a_im == a &&
                   a_sh == a &&
                   a_sc == a &&
                   a_si == a;
        }
    }
}

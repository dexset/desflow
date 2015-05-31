module des.flow.signal;

import des.flow.base;

/// Control signal
struct CtrlSignal
{
    ///
    ulong code;

pure nothrow @nogc:
    ///
    this( ulong code ) { this.code = code; }
    ///
    this( in CtrlSignal s ) { this.code = s.code; }
}

///
interface CtrlSignalProcessor { /++ +/ void processCtrlSignal( in CtrlSignal ); }

///
interface CtrlSignalBus { /++ +/ void sendCtrlSignal( in CtrlSignal ); }

unittest
{
    assert( creationTest( CtrlSignal(0) ) );
}

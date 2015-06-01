module des.flow.element;

import des.flow.base;

import des.flow.event;
import des.flow.signal;

/++
Inner interpret of thread

action must be in:
  * preparation               -> ctor
  * last actions before start -> process special input event
  * actions on pause          -> process special input event
  * processing                -> process
  * terminate all             -> selfDestroy( external memory manager )
+/
abstract class WorkElement : EventBus, CtrlSignalBus, ExternalMemoryManager
{
    mixin EMM;
    mixin ClassLogger;

private:

    ///
    CtrlSignalProcessor signal_processor;

    ///
    EventProcessor event_listener;

public:

    /// main work function
    abstract void process();

    ///
    EventProcessor[] getEventProcessors() { return []; }

    ///
    final void setEventListener( EventProcessor ep )
    {
        event_listener = ep;
        logger.Debug( "set event listener [%s]", ep );
    }

    /// push event to event listener if it exists
    final void pushEvent( in Event ev )
    {
        logger.trace( "push event with code [%d] timestamp [%d] to listener [%s]", ev.code, ev.timestamp, event_listener );
        if( event_listener !is null )
            event_listener.processEvent( ev );
    }

    ///
    final void setCtrlSignalProcessor( CtrlSignalProcessor sp )
    in { assert( sp !is null ); } body
    {
        signal_processor = sp;
        logger.Debug( "set signal processor [%s]", sp );
    }

    /// send signal to signal processor if it exists
    final void sendCtrlSignal( in CtrlSignal sg )
    {
        logger.trace( "send signal [%s] to processor [%s]", sg, signal_processor );
        if( signal_processor !is null )
            signal_processor.processCtrlSignal( sg );
    }
}

///
unittest
{
    struct TestStruct { double x, y; string info; immutable(int)[] data; }
    auto ts = TestStruct( 3.14, 2.7, "hello", [ 2, 3, 4 ] );

    class TestElement: WorkElement
    {
        override void process(){}
    }

    class TestSignalProcessor : CtrlSignalProcessor
    { void processCtrlSignal( in CtrlSignal s ) { assertEq( s.code, 0 ); } }

    auto elem = new TestElement;
    elem.setCtrlSignalProcessor( new TestSignalProcessor );

    elem.sendCtrlSignal( CtrlSignal(0) );

    size_t cnt = 0;
    elem.setEventListener( new class EventProcessor {
        void processEvent( in Event ev )
        { cnt++; assertEq( ev.as!TestStruct, ts ); }
        });

    auto ev = Event( 8, ts );
    elem.pushEvent( ev );
    elem.pushEvent( const Event( ev ) );
    elem.pushEvent( shared Event( ev ) );
    elem.pushEvent( immutable Event( ev ) );
    elem.pushEvent( const shared Event( ev ) );
    elem.pushEvent( shared const Event( ev ) );
    elem.pushEvent( immutable shared Event( ev ) );
    elem.pushEvent( shared immutable Event( ev ) );
    assertEq( cnt, 8 );
}

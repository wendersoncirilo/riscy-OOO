import Vector::*;
import Types::*;

// a timer to track latency of multiple misses

// To prevent assert failure, start() and done() methods should be called even
// when performance stats is not on

interface LatencyTimer#(numeric type num, numeric type timeWidth);
    method Action start(Bit#(TLog#(num)) idx);
    method ActionValue#(Bit#(timeWidth)) done(Bit#(TLog#(num)) idx);
endinterface

module mkLatencyTimer(LatencyTimer#(num, timeWidth)) provisos(
    //Add#(1, a__, num),
    Alias#(idxT, Bit#(TLog#(num))),
    Alias#(timeT, Bit#(timeWidth))
);
    Reg#(Vector#(num, timeT)) timer <- mkReg(replicate(0));
    Reg#(Vector#(num, Bool)) started <- mkReg(replicate(False)); // for checking purposes

    RWire#(idxT) startEn <- mkRWire;
    RWire#(idxT) doneEn <- mkRWire;

    (* fire_when_enabled, no_implicit_conditions *)
    rule canon;
        Vector#(num, timeT) timerNext = timer;
        Vector#(num, Bool) startedNext = started;
        // apply done
        if(doneEn.wget matches tagged Valid .i) begin
            startedNext[i] = False;
            doAssert(started[i], "timer must be valid");
        end
        // incr timer
        for(Integer i = 0; i < valueof(num); i = i+1) begin
            timeT t = timer[i];
            if(t < maxBound) begin
                timerNext[i] = t + 1;
            end
        end
        // apply start
        if(startEn.wget matches tagged Valid .i) begin
            timerNext[i] = 0;
            startedNext[i] = True;
            doAssert(!started[i], "timer must be invalid");
        end
        // update states
        timer <= timerNext;
        started <= startedNext;
    endrule

    method Action start(idxT i);
        startEn.wset(i);
    endmethod

    method ActionValue#(timeT) done(idxT i);
        doneEn.wset(i);
        return timer[i];
    endmethod
endmodule

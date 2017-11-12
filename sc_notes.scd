s.makeWindow
newServer = Server.new("exra-host")
s.inspect
UGen.browse
Server.internal.options.memSize = 8192 * 32;
~a = 1
currentEnvironment

e = Environment.make;
e.use { ~one = nil; ~two = 2; ~three = 3; };

f = { |one, two, three|
  ("one " + one).postln;
  ("two " + two).postln;
  ("three " + three).postln;
};

e.use {
  f.valueEnvir(e)
};

c = TempoClock.new;
c.tempo = 0.5;

r = Routine({
  1.postln;
  1.yield; // yield time happens in beats
  2.postln;
  1.yield;
  3.postln;
})

r.reset;
c.sched(0, r);

e = Env([0.001, 1, 0.001], [0.03, 0.47], \exp);

SynthDef(\kick, {
  Out.ar(0,
    (SinOsc.ar(XLine.kr(100, 40, 0.5, doneAction: 2), 0, 0.5) * EnvGen.kr(e)) ! 2
  );
}).send(s);

SynthDef(\snare, {
  Out.ar(0,
    (PinkNoise.ar * EnvGen.kr(e) * 0.5) ! 2
  );
}).send(s);

r = Routine {
  loop {
    Synth(\kick);
    1.yield;
    Synth(\snare);
    0.5.yield;
    Synth(\kick);
    1.5.yield;
    Synth(\snare);
    1.yield;
  }
};

c.sched(0, r);
c.tempo = 2;
c.clear;

~test = Buffer.alloc(s, 1024);
t = TempoClock(1);
c = Condition.new(false);
// A function to create random wavetables:

~wrand = { |bufnum, startTime, size, segments, minVal, maxVal, interp, action|
  var pointVals, segLengths, env, sampVals;

  pointVals = Array.rand(segments, minVal, maxVal).cubed;
  segLengths = (Array.rand(segments - 1, 1, 100).cubed).normalizeSum;
  env = Env(pointVals, segLengths, interp);
  sampVals = sampVals.addAll(env.asSignal(size));

  SystemClock.sched(startTime, {
    bufnum.sendCollection(sampVals, action: action)
  });
};

~process1 = { |interpol|
  var routine = Routine ({
    loop ({
      ~wrand.value(~test, 0, ~test.numFrames, 5.rrand(500), -1.rrand(-0.333), 1.0.rrand(0.333), interpol, 2, action: {|buf|

        p.free;
        q.free;

        p = {
          Out.ar(0,
            PlayBuf.ar(1, ~test, BufRateScale.kr(~test) * 1.0111, loop: 1) * 0.2
          );
        }.play;

        q = {
          Out.ar(1,
            PlayBuf.ar(1, ~test, BufRateScale.kr(~test) * 0.98567, loop: 1) * 0.2
          )
        }.play;
      });

      [0.125, 0.25, 0.5, 1].wchoose([0.85, 0.09, 0.04, 0.02]).wait;
      c.wait;

      // do it twice to avoid glitches from freeing
      ~wrand.value(~test, 0, ~test.numFrames, 5.rrand(500), -1.rrand(-0.333), 1.0.rrand(0.333), interpol, 2, action: {|buf|

        // free the other two synths if they're playing
        x.free;
        y.free;

        x = {
          Out.ar(0,
            PlayBuf.ar(1, ~test, BufRateScale.kr(~test) * 1.0139, loop: 1) * 0.2
          )
        }.play;

        y = {
          Out.ar(1,
            PlayBuf.ar(1, ~test, BufRateScale.kr(~test) * 0.98432, loop: 1) * 0.2
          )
        }.play;

      });

      [0.125, 0.25, 0.5, 1].wchoose([0.85, 0.1, 0.04, 0.01]).wait;
      c.wait;

    });
  });

  routine.play(t);
};


c.test = false;
c.signal;

~process1.value(\sin); // choose an interpolation type
t.tempo_(1); // change the tempo
p.free; q.free; x.free; y.free;
~test.free

a = Signal.newClear(256);
a.waveFill({ arg x, old, i; sin(x)}, 0, 3pi);
a.plot

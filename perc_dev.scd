SynthDef(\squig, {
  var sig, env, dur;

  dur = MouseX.kr(0.005, 1);

  env = EnvGen.kr(
    Env.perc(0.01, dur),
    doneAction: 2
  );

  sig = SinOsc.ar(
    WhiteNoise.kr.range(90, 16000), 0, 0.1
  );

  Out.ar([0, 1], sig * env);
}).add;

SynthDef(\noisy_cable, {
  var sig, env, dur, bFreq;

  dur = MouseX.kr(0.005, 1);

  env = EnvGen.kr(
    Env.perc(0.1, dur),
    doneAction: 2
  );

  bFreq = MouseY.kr(1, 1000);

  sig = SinOsc.ar(bFreq, 0, 0.1) * SinOsc.ar(bFreq * LFNoise2.ar(100).range(0.1, 1.5), 0, 0.1);
  sig = AllpassC.ar(sig, 0.1, SinOsc.kr(10).range(0.01, 0.1), dur);

  sig = sig * env * 50.dbamp;
  sig = sig.tanh;

  Out.ar([0, 1], sig);
}).add;

SynthDef(\rip, {
  var sig, env, dur, bFreq;

  dur = MouseX.kr(0.005, 1);

  env = EnvGen.kr(
    Env.perc(0.1, dur),
    doneAction: 2
  );

  sig = 100.collect {
    Pulse.ar(XLine.kr(100, 10, dur), rrand(0, 0.5), 0.5);
  }.mean;
  sig = MoogVCF.ar(sig, XLine.kr(100, 10000, dur), 0.1);
  sig = AllpassC.ar(sig, 0.21, 0.2, dur);

  Out.ar([0, 1], sig);
}).add;

SynthDef(\random_bell, {
  var sig, env, dur, bFreq;

  dur = MouseX.kr(0.005, 1);

  env = EnvGen.kr(
    Env.perc(0.05, dur),
    doneAction: 2
  );

  sig = 20.collect {
    SinOsc.ar(exprand(60, 2200));
  }.mean;

  sig = sig * env;

  Out.ar([0, 1], sig);
}).add;

c = 1;
c = nil;

s.record
s.stopRecording

~clock = TempoClock.new;
~clock.sched(0.5, {Synth(\new); c;});

~grainBuf = Buffer.read(
  s,
  "samples/5sample.wav"
);

SynthDef(\graind, { Out.ar([0, 1], PlayBuf.ar(1, ~grainBuf, BufRateScale.ir(~grainBuf))); }).add
Synth(\graind);

SynthDef(\why_so_hi, {
  var sig, trig, dur;

  dur = MouseX.kr(0.1, 4);

  trig = Impulse.ar(Line.kr(
    1000,
    1,
    dur
  ));

  sig = GrainBuf.ar(
    1,
    trig,
    0.005,
    ~grainBuf,
    BufRateScale.ir(~grainBuf) * TRand.kr(0.1, 1, trig)
  );

  Out.ar([0, 1], sig);
}).add;

Synth(\why_so_hi)

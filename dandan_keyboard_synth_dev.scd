loadRelative("/synth_def_support.scd");
loadRelative("keyboard_synth_defs.scd");

MIDIFunc.trace(false)

if (MIDIClient.initialized.not) {
  MIDIClient.init;
  MIDIIn.connectAll;
  // MIDIClient.restart;
  // MIDIClient.disposeClient;
  MIDIClient.sources.postln;
};

b = Bus.audio(numChannels: 2);

SynthDef(\verb, {
  |inBus, roomsize=10, revtime=3, damping=0.5, inputbw=0.5, spread=15, drylevel=1|
  var in = In.ar(inBus, 2);

  Out.ar(0, GVerb.ar(in, roomsize, revtime, damping, inputbw, spread, -6.dbamp).mean);
}).load(s);

if (v.isNil) {
  v = Synth(\verb, [inBus: b, roomsize: 30, revtime: 0.2]);

  CmdPeriod.doOnce({
    v = nil;
  });
};

p = MIDIClient.sources.detect { |source|
  source.device == "Digital Piano";
};

g = KeyboardInstrument(p);

c = MIDIClient.sources.detect { |source|
  source.device == "BCR2000" && source.name == "Port 1";
};

t = MIDIClient.sources.detect { |source|
  source.device == "Breath Controller";
};

g.keyboardNote = { |veloc, num, params|
  Synth(\clean_cool, params ++ [
    outBus: b,
    // amp: veloc.linexp(0, 100, -50.dbamp, 1),
    freq: num.midicps,
    amp: veloc.linexp(0, 100, -60.dbamp, 1)
  ]);
};

g.checkParamsForSynth(\clean_cool);


// { var excitation = EnvGen.kr(Env.perc,
//                             MouseButton.kr(0, 1, 0),
//                              timeScale: 0.1, doneAction: 0
//                             ) * PinkNoise.ar(0.4);
//   var tension = MouseX.kr(0.01, 0.1);
//   var loss = MouseY.kr(0.999999, 0.999, 1);
//   MembraneCircle.ar(excitation, tension, loss);
// }.play;
// (
// { var excitation = EnvGen.kr(Env.perc,
//                             MouseButton.kr(0, 1, 0),
//                              timeScale: 0.1, doneAction: 0
//                             ) * PinkNoise.ar(0.4);
//   var tension = MouseX.kr(0.01, 0.1);
//   var loss = MouseY.kr(0.999999, 0.999, 1);
//   MembraneHexagon.ar(excitation, tension, loss);
// }.play;
// )

// SynthDef(\help_dwgpluckedstiff, { |out=0, freq=440, pos = 0.1, amp=0.5, gate=1, c1=1, c3=20, pan=0,fB = 80|
//     var env = Env.new([0,1, 1, 0],[0.001,0.006, 0.0005],[5,-5, -8]);
//     var inp = amp * LFClipNoise.ar(2000) * EnvGen.ar(env,gate);
//     var son = DWGPluckedStiff.ar(freq, amp, gate, pos,c1,c3,inp,fB);
//     DetectSilence.ar(son, 0.001, doneAction:2);
//     Out.ar(out, Pan2.ar(son * 0.1, pan));
// }).add;

// Synth(\help_dwgpluckedstiff, [
//   freq: PC(\a, 1).freq,
//   c1: 10,
//   c3: 3000
// ])

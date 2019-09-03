SynthDef(\growl, {
  arg outBus = 0, amp = 0, freq = 100, gate = 1;
  var sig, env;

  amp = amp * (amp > 0.001);
  amp = amp.lag3(0.012);

  sig = MoogFF.ar(
    Pulse.ar(
      freq * [1.00121312, 0.99843, 1],
      [0.2, 0.1, 0.5],
      [0.7, 0.3, 0.1]
    ).mean +
    Pulse.ar(
      freq * 0.5 * [1.00121312, 0.99843, 1],
      [0.2, 0.1, 0.5],
      [0.7, 0.3, 0.1]
    ).mean,
    freq * 5.75,
    0.2
  );

  env = EnvGen.kr(
    Env([-100.dbamp, 1, -4.dbamp, -100.dbamp], [0.01, 0.2, 0.1], \exp, 2),
    gate, doneAction: 2);

  sig = env * sig * amp;

  Out.ar(outBus, sig.softclip);
}).add;
loadRelative("synth_def_support.scd");
loadRelative("keyboard_synth_defs.scd");

MIDIFunc.trace(false);
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

g.checkParamsForSynth(\growl);
g.buildControlMap(
  \amp, t, 2, { |controlValue| controlValue.linexp(0, 80, -60.dbamp, 1) }
);

g.keyboardNote = { |veloc, num, params|
  Synth(\growl, params ++ [
    outBus: 3,
    freq: num.midicps / 2,
  ]);
};

g.enable;

~kik = Buffer.read(s, "/Users/bion/MainDocuments/art/Bowron/groove/soundfiles/kik9.aiff");
~hat = Buffer.read(s, "/Users/bion/MainDocuments/art/Bowron/groove/soundfiles/hats/hat2.aiff");
~snare = Buffer.read(s, "/Users/bion/MainDocuments/art/Bowron/percussion development/sampz/snare1.wav");

~drums = IdentityDictionary[
  39 -> ~kik,
  36 -> ~kik,

  48 -> ~hat,
  38 -> ~hat,

  45 -> ~snare,
  40 -> ~snare
];

SynthDef(\playbuf_simple, {
  arg outBus, buf, amp=1;

  Out.ar(outBus, PlayBuf.ar(1, buf, BufRateScale.ir(buf), doneAction: 2)*amp);
}).add

~playDrum = { |val, num|
  var buf = ~drums[num];

  Synth(\playbuf_simple, [
    outBus: 4,
    buf: buf,
    amp: -10.dbamp
  ]);
};

f = MIDIFunc.noteOn({ |val, num, chan, src|
  if (src == 902699314) {
    ~playDrum.value(val, num);
  };
});

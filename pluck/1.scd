SynthDef(\string, {arg out=0, freq=440, pan=0, sustain=0.5, amp=0.3;
    var pluck, period, string;

    pluck = PinkNoise.ar(Decay.kr(Impulse.kr(0.005), 0.05));
    period = freq.reciprocal;
    string = CombL.ar(pluck, period, period, sustain*6);
    string = LeakDC.ar(LPF.ar(Pan2.ar(string, pan), 12000)) * amp;

    DetectSilence.ar(string, doneAction: 2);
    Out.ar(out, string)
}).add;

[
  [\a, 2],
  [\a, 3],
  [\b, 4],
  [\c, 5],
  [\d, 5],
  [\e, 5],
  [\g, 5],
  [\b, 5],
  [\g, 6]
].do { |pair|
  Synth(\string, [freq: PC(pair[0], pair[1]).freq, sustain: 5])
};

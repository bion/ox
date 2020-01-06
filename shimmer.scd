SynthDef(\shimmer, {
  |freq, amp = 1, gp = 0.12,
  trigOverlap = 8, vibeRate = 6, vibeWidth = 0.001|
  var grains, trig, pan, harmAmpLFOs, harmAmps,
  vib, rand, vibWidth, vibeAmp, env, sig;

  vibeAmp = EnvGen.kr(Env([0.001, 1], [0.1], \exp));
  vibeWidth = vibeWidth * vibeAmp;
  vib = SinOsc.kr(vibeRate, 0, vibeWidth, 1);

  trig = gp.reciprocal * trigOverlap * LFNoise2.kr(6).range(0.95, 1.05);
  trig = Impulse.kr(trig);

  harmAmps = (1..12).collect { |i| i.reciprocal ** 3};

  sig = GrainSin.ar(
    numChannels: 1,
    trigger: trig,
    dur: gp,
    freq: freq * (1..12) * [0.998123, 1, 1.000123124],
    pan: 0,
    mul: harmAmps
  );

  sig = Mix(sig);

  env = EnvGen.kr(Env([0, 1, 1, 0], [1, 3, 1], \sin));

  Out.ar(0, sig * env * amp ! 2);
}).add;

Synth(\shimmer, [freq: PC(\c, 5).freq, amp: 20.dbamp]);
Synth(\shimmer, [freq: PC(\g, 4).freq, amp: 20.dbamp]);
Synth(\shimmer, [freq: PC(\ef, 4).freq, amp: 20.dbamp]);
Synth(\shimmer, [freq: PC(\ef, 4).freq, amp: 20.dbamp]);

Synth(\default, [freq: PC(\c, 5).freq]);

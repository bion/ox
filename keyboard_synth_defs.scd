SynthDef(\ddsynth, {
  |outBus, freq, amp, envBuf, gate = 1, pPos = 0, pSpread = 0.5, freqMul = 1,
  dur, trigLFOfreq = 4, trigOverlap = 3.5,
  trigLFOrange = 20, gp = 0.12,
  vibeRate = 6.5, vibeWidth = 0.0125,
  harmLFOfreq = 0.5, harmLFOlo = -0.01,
  diss = 0,
  indexLFOfreq = 0.2, indexLFOlo = 0.5, indexLFOhi = 5,
  vibOnset = 0.01|

  var grains, trig, pan, index, harmAmpLFOs, harmAmps,
  vib, rand, vibosc, vibwth, vibamp, env, sig;

  vibamp = EnvGen.kr(Env([0.001, 1], [vibOnset], \exp));
  vibwth = vibeWidth * vibamp;
  vibosc = SinOsc.kr(vibeRate, 0, vibwth);
  rand = LFNoise1.kr(1/6.5, vibwth);
  vib = vibosc + rand + 1;

  trig = gp.reciprocal * trigOverlap;
  trig = Impulse.kr(trig);

  pan = (TRand.kr(-1, 1, trig) * pSpread) + pPos;

  index = LFNoise2.kr(indexLFOfreq).range(indexLFOlo, indexLFOhi);

  harmAmps = Control.names(\harmAmpArray).kr(7.collect { 1 });
  harmAmpLFOs = 7.collect {
    LFNoise2.kr(harmLFOfreq).range(harmLFOlo.dbamp, 1)
  };

  grains = GrainFM.ar(
    numChannels: 2,
    trigger: trig,
    dur: gp,
    carfreq: freq * vib * (1 .. 7),
    modfreq: freq * vib * (1 .. 7),
    index: index,
    pan: pan,
    envbufnum: -1,
    maxGrains: 128,
    mul: harmAmps * harmAmpLFOs
  ).mean;

  grains = LeakDC.ar(grains);

  grains = Array.fill(6*4, {|i|
    var centerFreq, modFreq, multiplier;

    centerFreq = (36 + (i * 4)).midicps;
    modFreq = 2.27 * (centerFreq ** 0.477);
    multiplier = (1.0 - diss) + (diss * SinOsc.kr(modFreq * 0.5, 2pi.rand));

    multiplier * BPF.ar(grains, centerFreq, 0.29);
  }).sum;

  sig = Mix([\soprano, \bass, \tenor, \counterTenor, \alto].collect { |register|
    Vowel(\o, register)
  }.collect(_.asArray).collect(_.flop).flatten.collect { |spec|
    var freq = spec[0];

    BPF.ar(grains, freq, spec[1].dbamp, spec[2] / freq);
  });


  env = EnvGen.kr(
    Env([-100.dbamp, 1, -100.dbamp], [0.1, 0.1], \exp, 1),
    gate, doneAction: 2);

  // env = EnvGen.kr(
  //   Env([-100.dbamp, 1, -4.dbamp, -100.dbamp], [0.01, 0.2, 0.1], \exp, 2),
  //   gate, doneAction: 2);

  Out.ar(outBus, sig * env * Lag2.kr(amp, 0.03));
}).load(s);

SynthDef(\buzzy_gameboy, {
  arg outBus, amp, freq, vib_rate = 11, vib_width = 0.00125,
  gate = 1, gliss = 0, fade = 1, glissDur = 0.5;
  var sig, vib, env;

  freq = Select.kr(gliss, [freq, freq.lag3(glissDur)]);

  vib_rate = vib_rate * LFDNoise3.kr(2).range(0.9, 1.1);
  vib = SinOsc.kr(vib_rate, 0, vib_width) + LFNoise2.kr(1/vib_rate, vib_width/2) + 1;

  sig = Pulse.ar(freq,
    [
      SinOsc.kr(vib_rate).range(0.2, 0.3),
      SinOsc.kr(vib_rate).range(0.4, 0.5),
      SinOsc.kr(vib_rate).range(0.1, 0.2)
    ],
    mul: 0.2).mean +
  SinOsc.ar(-7.midiratio * freq, 0, -8.dbamp * 0.2) +
  SinOsc.ar(2 * freq, 0, -8.dbamp * 0.2);

  sig = MoogFF.ar(sig, freq * 10, 0.2, mul: 2) + sig;

  env = EnvGen.kr(
    Env([-100.dbamp, 1, -4.dbamp, -100.dbamp], [0.01, 0.2, 0.1], \exp, 2),
    gate, doneAction: 2);

  amp = Select.kr(gliss, [amp, amp.lag3(glissDur)]);
  sig = sig * env * 0.25 * amp * fade.lag3(glissDur);

  Out.ar(outBus, sig.softclip ! 2);
}).load(s);

SynthDef(\organish, {
  |outBus, amp, freq, gate = 1, vib_rate = 11, vib_width = 0.00125|
  var sig, env, vib, warm = LFNoise2.kr(vib_rate).range(0.9, 1.1);

  vib_rate = vib_rate * LFDNoise3.kr(2).range(0.9, 1.1);
  vib = SinOsc.kr(vib_rate, 0, vib_width) + LFNoise2.kr(1/vib_rate, vib_width/2) + 1;
  freq = freq * vib;

  sig = MoogFF.ar(
    Pulse.ar(
      freq * [1.00121312, 0.99843, 1, 33.5.midiratio],
      [0.2, 0.1, 0.5] * warm,
      [0.7, 0.3, 0.1]
    ).mean,
    freq * 5.75 * warm,
    0.2
  );

  env = EnvGen.kr(
    Env([-100.dbamp, 1, -4.dbamp, -100.dbamp], [0.01, 0.2, 0.1], \exp, 2),
    gate, doneAction: 2);

  sig = LeakDC.ar(sig);
  sig = sig * env * amp;
  sig = AudioMSG.ar(sig, 8);

  Out.ar(outBus, sig.softclip);
}).load(s);

SynthDef(\clean_cool, {
  |outBus, freq, amp, diss = 0, gate = 1|
  var sig, env;

  sig = Saw.ar(freq, amp);
  sig = MoogFF.ar(sig, freq * 2, 1.4);

  sig = Array.fill(6*4, {|i|
    var centerFreq, modFreq, multiplier;

    centerFreq = (36 + (i * 4)).midicps;
    modFreq = 2.27 * (centerFreq ** 0.477);
    multiplier = (1.0 - diss) + (diss * SinOsc.kr(modFreq * 0.5, 2pi.rand));

    multiplier * BPF.ar(sig, centerFreq, 0.29);
  }).sum;

  env = EnvGen.kr(
    Env([-100.dbamp, 1, -4.dbamp, -100.dbamp], [0.03, 0.2, 0.1], \exp, 2),
    gate, doneAction: 2);

  sig = sig * env;

  Out.ar(outBus, sig ! 2);
}).load(s);

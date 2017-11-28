var synthDefs = [
  SynthDef(\v_control, {
    arg outbus, amp;
    var off = amp > 2;

    Out.kr(outbus, (LinExp.kr(amp, 0, 127, -40.dbamp, 1) * off).lag3(0.01));
  }),

  SynthDef(\p_control_lag, {
    arg outbus, param;

    Out.kr(outbus, param.lag3(0.01) )
  }),

  SynthDef(\p_control, {
    arg outbus, param;

    Out.kr(outbus, param)
  }),

  SynthDef(\metronome_sine, {
    arg outbus, amp;
    var out, env;

    env = EnvGen.kr(Env.perc(0.001, 0.05, amp, -4), doneAction: 2);
    out = SinOsc.ar(1800, 0, env);

    Out.ar(outbus, out);
  }),

  SynthDef(\ixibass, {
    arg out=0, amp=0.3, t_trig=1, freq=100, rq=0.004;
    var env, signal;
    var rho, theta, b1, b2;

    b1 = 1.98 * 0.989999999 * cos(0.09);
    b2 = 0.998057.neg;

    signal = SOS.ar(K2A.ar(t_trig), 0.123, 0.0, 0.0, b1, b2);
    signal = RHPF.ar(signal, freq, rq) + RHPF.ar(signal, freq*0.5, rq);
    signal = Decay2.ar(signal, 0.4, 0.3, signal);

    DetectSilence.ar(signal, 0.01, doneAction: 2);

    Out.ar(out, signal * (amp * 0.45) ! 2);
  }),

  SynthDef(\triggeredPlayBuf, {
    arg trigbus, outbus, buf, amp=1;
    var trig, out;

    trig = In.kr(trigbus, 1);
    out = PlayBuf.ar(1, buf, BufRateScale.kr(buf), loop: 0, trigger: trig);
    Out.ar(outbus, out * amp);
  }),

  SynthDef(\control_env_testing, {
    arg outbus;
    var env;

    env = Control.names([\env]).kr(Env.newClear(64));
    Out.kr(outbus, EnvGen.kr(env, doneAction: 14));
  }),

  SynthDef(\playbuf_stereo_to_mono_to_mons, {
    arg buf, sax_mon, drums_mon, nugs_mon, com_mon, amp;
    var out;

    out = PlayBuf.ar(2, buf, BufRateScale.ir(buf), loop: 1) * amp;

    [sax_mon, drums_mon, nugs_mon, com_mon].do {|bus|
      Out.ar(bus, out);
    };
  }),

  SynthDef(\playbuf_mono, {
    arg outbus, buf, dur, startpos=0, amp=1, gate=1;

    Out.ar(outbus,
      Linen.kr(gate, releaseTime: 0.02, doneAction: 2) *
      EnvGen.kr(Env([0, 1, 1, 0], [0.01, 1, 0.01].normalize), amp,
        timeScale: dur, doneAction: 2) *
      PlayBuf.ar(1, buf, BufRateScale.ir(buf), startPos: startpos, doneAction: 2));
  }),

  SynthDef(\playbuf_simple, {
    arg outbus, buf, amp=1;

    Out.ar(outbus, PlayBuf.ar(1, buf, BufRateScale.ir(buf), doneAction: 2)*amp);
  }),

  SynthDef(\recordbuf_mono, {
    arg inbus, buf, startpos, gate=1;
    var env = Linen.kr(gate, 0.01, releaseTime: 0.01, doneAction: 2);

    RecordBuf.ar(In.ar(inbus, 1) * env, buf, startpos, recLevel: 0.dbamp, preLevel: 0);
  }),

  SynthDef(\route_mono, {
    arg inbus, outbus;

    Out.ar(outbus, In.ar(inbus, 1) );
  }),

  SynthDef(\route_mono_amp, {
    arg inbus, outbus, amp=1;

    Out.ar(outbus, In.ar(inbus, 1) * amp.lag(0.05) );
  }),

  (1..8).collect {|i|
    SynthDef(asSymbol("route_mono_to_" ++ i), {
      arg inbus;

      Out.ar(\outbusses.ir(8 ! i), In.ar(inbus, 1));
    })
  },

  SynthDef(\route_4_chans_to_mono, {
    arg inbusses, outbus;

    Out.ar( outbus, In.ar(inbusses, 4).sum );
  }),

  SynthDef(\route_m2s, {
    arg inbus, outbus;

    Out.ar(outbus, In.ar(inbus, 1) ! 2);
  }),

  SynthDef(\route_m2s_free_on_silence, {
    arg inbus, outbus;
    var in = In.ar(inbus, 1);

    DetectSilence.ar(in, time: 5.0, doneAction: 14);
    in = Compander.ar(in, in, 0.5, 1.0, 0.05, 0.002, 0.01);

    Out.ar(outbus, in ! 2);
  }),

  /* ------------------------ sources --------------------------- */

  SynthDef(\ddsynth, {
    |outBus, amp, pPos, pSpread, freq, envBuf, freqMul = 1,
    dur, trigLFOfreq = 0.2, trigOverlap = 3.5,
    trigLFOrange = 20, trigLFOMul, gp = 0.12,
    vibeRate = 6.5, vibeWidth = 0.0125,
    harmLFOfreq = 0.5, harmLFOlo = -0.01,
    indexLFOfreq = 0.2, indexLFOlo = 0.5, indexLFOhi = 5|
    var grains, trig, pan, index, harmAmpLFOs, harmAmps,
    vib, rand, vibosc, vibwth, vibamp, env, sig;

    vibamp = EnvGen.kr(Env([0.001, 1], [0.6], \exp));
    vibwth = vibeWidth * vibamp;
    vibosc = SinOsc.kr(vibeRate + LFDNoise3.kr(2).range(0.9, 1.1), 0, vibwth);
    rand = LFNoise1.kr(1/6.5, vibwth);
    vib = vibosc + rand + 1;

    trig = (gp.reciprocal * trigOverlap) * 1;

    trig = Impulse.kr(trig);

    pan = (TRand.kr(-1, 1, trig) * pSpread) + pPos;

    index = LFNoise2.kr(indexLFOfreq).range(indexLFOlo, indexLFOhi);

    harmAmps = Control.names(\harmAmpArray).kr(7.collect { 1 });
    harmAmpLFOs = 7.collect { LFNoise2.kr(harmLFOfreq).range(harmLFOlo.dbamp, 1) };

    grains = GrainFM.ar(
      numChannels: 2,
      trigger: trig,
      dur: gp,
      carfreq: freq * vib * (1 .. 7) * freqMul,
      modfreq: freq * vib * (1 .. 7) * freqMul,
      index: index,
      pan: pan,
      envbufnum: envBuf,
      maxGrains: 128,
      mul: harmAmps * harmAmpLFOs
    ).mean;

    grains = LeakDC.ar(grains);

    env = EnvGen.kr(Control.names([\env]).kr(Env.newClear(64)));

    sig = env * amp * grains;

    Out.ar(outBus, sig);
    DetectSilence.ar(sig, doneAction: 2);
  }),

  /* ------------------------ com --------------------------- */

  // SynthDef(\com_ddsynth, {
  //   arg bus, amp, gate = 1, freqLagParam = 0.03, beatDur=1,
  //   gp = 0.12, envBuf, harm_amp_lag = 0.2, index = 0.01, vibwth = 0.005;

  //   var sig, harmAmps, freqs, silencers, freqLag,
  //   vib, rand, vibosc, vibeRate = 6.5,
  //   trigLFOfreq = 0.25, trigLFOMul = 1.5, trigLFOrange = 20, trigOverlap = 3.5;

  //   envBuf = ~synthDefSupport[\sin_buf_1];

  //   freqLag = freqLagParam * beatDur;

  //   freqs = \freqs.kr(Array.fill(10, {1})).lag(freqLag);
  //   silencers = freqs.collect { |freq| freq > 9.0; };

  //   vibosc = SinOsc.kr(vibeRate + LFDNoise3.kr(2).range(0.9, 1.1), 0, vibwth);
  //   rand = LFNoise1.kr(1/6.5, vibwth);
  //   vib = vibosc + rand + 1;

  //   harmAmps = \harmAmpArray.kr(7.collect { 0 }).lag(harm_amp_lag);

  //   sig = freqs.collect({
  //     arg freq, i;
  //     var trig;

  //     trig = Impulse.kr(
  //       (gp.reciprocal * trigOverlap) * (
  //         LFNoise2.kr(trigLFOfreq)
  //         .range(trigLFOrange / 2 * 0.01.neg, trigLFOrange / 2 * 0.01)
  //         * trigLFOMul + 1
  //       )
  //     );

  //     GrainFM.ar(
  //       numChannels: 1,
  //       trigger: trig,
  //       dur: gp,
  //       carfreq: freq * vib * (1 .. 7),
  //       modfreq: freq * vib * (1 .. 7),
  //       index: index,
  //       pan: 0,
  //       envbufnum: envBuf,
  //       maxGrains: 128,
  //       mul: harmAmps * silencers[i]
  //     ).sum;
  //   }).mean * 0.0125;

  //   sig = LeakDC.ar(sig).softclip * amp;
  //   Out.ar(bus, sig * Linen.kr(gate, 0.05, releaseTime: 0.05, doneAction: 2));
  // }),

  SynthDef(\com_fank, {
    arg bus, amp, vib_rate = 11, freqLagParam = 0.03, beatDur=1, vib_width = 0.00125, gate=1;
    var sig, vib, freqs, silencers, ampMul, freq_lag;

    freq_lag = beatDur * freqLagParam;

    // TODO wire up controller for this
    // freq_lag = 0.1;

    freqs = \freqs.kr(Array.fill(10, {1})).lag(freq_lag);

    silencers = freqs.collect { |freq| freq > 9.0; };

    vib_rate = vib_rate * LFDNoise3.kr(2).range(0.9, 1.1);
    vib = SinOsc.kr(vib_rate, 0, vib_width) + LFNoise2.kr(1/vib_rate, vib_width/2) + 1;
    freqs = freqs * vib;

    sig = freqs.collect({|freq, i|
      var thisSig;
      thisSig = Pulse.ar(freq,
        [
          SinOsc.kr(vib_rate).range(0.2, 0.3),
          SinOsc.kr(vib_rate).range(0.4, 0.5),
          SinOsc.kr(vib_rate).range(0.1, 0.2)
        ],
        mul: 0.2 * silencers[i]).mean +
      SinOsc.ar(-7.midiratio * freq, 0, -8.dbamp * 0.2) +
      SinOsc.ar(2 * freq, 0, -8.dbamp * 0.2);

      MoogFF.ar(thisSig, freq * 10, 0.2, mul: 2) + thisSig;
    }).sum;

    ampMul = LinExp.kr(amp, 0, 64, -60.dbamp, -4.dbamp).lag3(0.002) * (amp > 0);
    sig = sig * ampMul * 0.25;

    Out.ar(bus, sig.softclip * Linen.kr(gate, 0.05, releaseTime: 0.05, doneAction: 2));
  }),

  SynthDef(\com_dirt_rhode, {
    arg bus, amp, vib_rate = 11, freqLagParam=0.03, beatDur=1, vib_width = 0.00125, gate=1;
    var sig, env, vib, warm = LFNoise2.kr(vib_rate).range(0.9, 1.1);
    var silencers, freqs, ampMul, detuneMuls, freq_lag;

    freq_lag = beatDur * freqLagParam;
    freqs = \freqs.kr(Array.fill(10, {1})).lag(freq_lag);
    silencers = freqs.collect { |freq| freq > 9.0; };

    vib_rate = vib_rate * LFDNoise3.kr(2).range(0.9, 1.1);
    vib = SinOsc.kr(vib_rate, 0, vib_width) + LFNoise2.kr(1/vib_rate, vib_width/2) + 1;
    freqs = freqs * vib;

    sig = freqs.collect {|freq, i|
      MoogFF.ar(
        Pulse.ar(
          freq * [1.00121312, 0.99843, 1, 33.5.midiratio],
          [0.2, 0.1, 0.5]*warm,
          [0.7, 0.3, 0.1],
          silencers[i]
        ).mean,
        freq * 5.75 * warm,
        0.2
      );
    }.mean;

    sig = LeakDC.ar(sig);
    sig = AudioMSG.ar(sig, 8);
    ampMul = LinExp.kr(amp, 0, 127, -60.dbamp, -4.dbamp).lag3(0.002) * (amp > 0);
    sig = sig * ampMul;

    Out.ar(bus, sig.softclip * Linen.kr(gate, 0.05, releaseTime: 0.05, doneAction: 2));
  }),

  /* ------------------------------- general filters --------------------------------- */

  SynthDef(\cynk_broad, {
    arg bus, gate=1;
    var layer1, layer2, in, chain;

    in = In.ar(bus, 1);
    chain = Fb({|fb|
      PitchShift.ar(fb * 0.9 + in, 0.15, [-24, -12, -5, 0, 7, 12, 24].midiratio, 0, 0.004).mean;
    }, 0.005);

    XOut.ar(bus, Linen.kr(gate, 0.05, releaseTime: 0.05, doneAction: 2), chain);
  }),

  SynthDef(\cynk_hi, {
    arg bus, gate=1;
    var layer1, layer2, in, chain;

    in = In.ar(bus, 1);
    chain = Fb({|fb|
      PitchShift.ar(fb * 0.9 + in, 0.15, [0, 7, 12, 24].midiratio, 0, 0.004).mean;
    }, 0.02);

    XOut.ar(bus, Linen.kr(gate, 0.05, releaseTime: 0.05, doneAction: 2), chain);
  }),

  SynthDef(\cynk_lo, {
    arg bus, gate=1;
    var layer1, layer2, in, chain;

    in = In.ar(bus, 1);
    chain = Fb({|fb|
      PitchShift.ar(fb * 0.9 + in, 0.15, [-24, -12, -7, 0].midiratio, 0, 0.004).mean;
    }, 0.002);

    XOut.ar(bus, Linen.kr(gate, 0.05, releaseTime: 0.05, doneAction: 2), chain);
  }),

  SynthDef(\general_chorus, {
    arg pbus, bus, gate=1;
    var in, chain, control, noise=LFNoise2.kr(4.dup(3));

    in = In.ar(bus, 1);
    chain = PitchShift.ar(in, 0.15, noise.range(0.999, 1.001), 0, 0.005);
    chain = ([in]++chain).mean;

    XOut.ar(bus, Linen.kr(gate, 0.05, releaseTime: 0.05, doneAction: 2), chain);
  }),

  SynthDef(\chorus_compress, {
    arg bus, gate=1;
    var in = In.ar(bus, 1), chain;

    chain = Array.fill(4, {
      var max_delay = rrand(0.01, 0.03);
      DelayC.ar(in, max_delay, LFDNoise3.kr(Rand(0.1, 0.6), 0.25 * max_delay, 0.75 * max_delay));
    });
    chain = Compander.ar(4 * (in + chain), in, 0.4, 1, 8);
    chain = chain * 0.125;

    XOut.ar(bus, Linen.kr(gate, 0.05, releaseTime: 0.05, doneAction: 2), chain);
  }),

  SynthDef(\shaper, {
    arg bus, buf, gate=1;
    var in, chain;

    in = In.ar(bus, 1);
    chain = Shaper.ar(buf, in);

    XOut.ar(bus, Linen.kr(gate, 0.05, releaseTime: 0.05, doneAction: 2), chain);
  }),

  SynthDef(\distort, {
    arg bus, buf, gate=1;
    var in, chain;

    in = In.ar(bus, 1);
    chain = Shaper.ar(buf, in);

    XOut.ar(bus, Linen.kr(gate, 0.05, releaseTime: 0.05, doneAction: 2), chain);
  }),

  SynthDef(\dissonance, {
    arg bus, diss=1, gate=1;
    var in, chain;

    in = In.ar(bus, 1);
    chain = Array.fill(24, {
      arg i;
      var centerFreq = (36+(i*4)).midicps,
      modFreq = 2.27*(centerFreq**4.77);
      ((1.0-diss) + (diss*SinOsc.kr(modFreq*0.5, 2pi.rand)))*BPF.ar(in, centerFreq, 0.29)
    }).sum;

    chain = LeakDC.ar(chain);
    chain = Compander.ar(chain, chain, -4.dbamp, 1, 1/3, 0.002, 0.04);

    XOut.ar(bus, Linen.kr(gate, 0.05, releaseTime: 0.05, doneAction: 2), chain);
  }),

  /* ------------------------------- test ugens --------------------------------- */

  SynthDef(\mouse_x_out, {|outbus, lo, hi, warp=0| Out.kr(outbus, MouseX.kr(lo, hi, warp))}),

  SynthDef(\control_stub, {|bus, value| Out.kr(bus, value) })
].flat.do { |sd| sd.add; };

"synth defs loaded".postln;
nil;

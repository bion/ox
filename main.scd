"ox.scd".loadRelative;

~detune = { |synthName, params, freq|
  [
    Synth(\ddsynth, params ++ [freq: freq]),
    Synth(\ddsynth, params ++ [freq: freq * 0.98329]),
    Synth(\ddsynth, params ++ [freq: freq * 1.0123123])
  ]
};

~chorus = ~defaults.value(
  (
    outBus: 0,
    amp: 0.2,
    gp: 0.8,
    trigOverlap: 12,
    pPos: 0,
    pSpread: 0.15,
    freq: 220,
    vibeWidth: 0.0005,
    envBuf: -1,
    harmAmpArray: (1..7).collect { |i| i }.reverse.collect { |i| (i / 7) ** 2 },
    sharedParams: [\outBus, \amp, \pPos, \envBuf, \env, \vibeWidth, \harmAmpArray],
    run: {
      var params = ~sharedParams.collect { |param|
        [param, currentEnvironment.at(param)]
      }.flatten;

      ~detune.value(\ddsynth, params, ~freq);
    }
  )
);

~names = [\low, \medLow, \med, \medHi, \medHiHi, \hi];

~channels = ~initChannels.value(~names);

~score = ~resolveEnvs.value([
  (
    bpm: 100, bpb: 4, events: [
      ~chorus.value((
        name: \low,
        env: ~env,
        beat: 1,
        freq: PC(\f, 3).freq,
        envs: (env: ~quiet)
      ))
    ]
  ),
  (
    events: [
      (name: \low, env: \env, curve: \exp, val: -10.dbamp),
      ~chorus.value((
        name: \medLow,
        beat: 1,
        env: ~env,
        freq: PC(\gs, 3).freq,
        env: ~quiet,
        envs: (env: ~quiet)
      ))
    ]
  ),
  (
    events: [
      (name: \medLow, env: \env, curve: \exp, val: -10.dbamp),
      ~chorus.value((
        name: \med,
        env: ~env,
        beat: 1,
        freq: PC(\cs, 4).freq,
        envs: (env: ~quiet)
      ))
    ]
  ),
  (
    events: [
      (name: \med, env: \env, curve: \exp, val: -10.dbamp),
      ~chorus.value((
        name: \medHi,
        env: ~env,
        beat: 1,
        freq: PC(\f, 4).freq,
        envs: (env: ~quiet)
      ))
    ]
  ),
  (
    events: [
      (name: \medHi, env: \env, curve: \exp, val: -10.dbamp),
      ~chorus.value((
        name: \medHiHi,
        env: ~env,
        beat: 1,
        freq: PC(\gs, 4).freq,
        envs: (env: ~quiet)
      ))
    ]
  ),
  (
    events: [
      (name: \medHiHi, env: \env, curve: \exp, val: -10.dbamp),
      ~chorus.value((
        name: \hi,
        env: ~env,
        beat: 1,
        freq: PC(\cs, 5).freq,
        envs: (env: ~quiet)
      ))
    ]
  ),
  (events: [(name: \hi, env: \env, curve: \exp, val: -10.dbamp)]),
  (
    events: ~names.collect { |name|
      (name: name, env: \env, curve: \exp, val: -6.dbamp)
    }
  ),
  (events: [(name: \low, env: \env, curve: \exp, val: ~quiet), ~free.value(\low)]),
  (events: [(name: \medLow, env: \env, curve: \exp, val: ~quiet), ~free.value(\medLow)]),
  (events: [(name: \med, env: \env, curve: \exp, val: ~quiet), ~free.value(\med)]),
  (events: [(name: \medHi, env: \env, curve: \exp, val: ~quiet), ~free.value(\medHi)]),
  (events: [(name: \medHiHi, env: \env, curve: \exp, val: ~quiet), ~free.value(\medHiHi)]),
  (events: [(name: \hi, env: \env, curve: \exp, val: ~quiet), ~free.value(\hi)]),
]);

~stop = ~scheduleMeasures.value(~channels, ~score);
~stop.value;
~channels.do { |c| c.finish.value }

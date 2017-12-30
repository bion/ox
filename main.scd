~defaults = { |template|
  { |overrides|
    putAll((), template, overrides)
  };
};

"synth_def_support.scd".loadRelative;
"synth_defs.scd".loadRelative;

~quiet = -60.dbamp;
~resolveEnvs = "resolve_envs.scd".loadRelative[0];
~scheduleMeasures = "schedule_measures.scd".loadRelative[0];

a = ~defaults.value(
  (
    outBus: 0,
    amp: 0.2,
    gp: 0.12,
    trigOverlap: 2,
    pPos: 0,
    pSpread: 0.25,
    freq: 220,
    envBuf: -1,
    harmAmpArray: (1..7).collect { |i| i }.reverse.collect { |i| (i / 7) ** 2 },
    run: {
      Synth(\ddsynth, [
        outBus: ~outBus,
        amp: ~amp,
        pPos: ~pPos,
        pSpread: ~pSpread,
        freq: ~freq,
        envBuf: ~envBuf,
        env: ~env,
        harmAmpArray: ~harmAmpArray
      ]);
      Synth(\ddsynth, [
        outBus: ~outBus,
        amp: ~amp,
        pPos: ~pPos,
        pSpread: ~pSpread,
        freq: ~freq * 0.98329,
        envBuf: ~envBuf,
        env: ~env,
        harmAmpArray: ~harmAmpArray
      ]);
      Synth(\ddsynth, [
        outBus: ~outBus,
        amp: ~amp,
        pPos: ~pPos,
        pSpread: ~pSpread,
        freq: ~freq * 1.0123123,
        envBuf: ~envBuf,
        env: ~env,
        harmAmpArray: ~harmAmpArray
      ]);
    }
  )
);

e = Env([~quiet, 1, 1, ~quiet], [2, 10, 2], \exp).asArray;

b = ~resolveEnvs.value([
  (
    bpm: 100, bpb: 4, events: [
      a.value((env: e, beat: 1, freq: PC(\cs, 5).freq)),
      a.value((env: e, beat: 1, freq: PC(\gs, 4).freq)),
      a.value((env: e, beat: 1, freq: PC(\f, 4).freq))
    ]
  ),
  (events: [])
]);

~stop = ~scheduleMeasures.value(b);
~stop.value;

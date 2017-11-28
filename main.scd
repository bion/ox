"synth_def_support.scd".loadRelative;
"synth_defs.scd".loadRelative;

~quiet = -60.dbamp;
~resolveEnvs = "resolve_envs.scd".loadRelative[0];
~scheduleMeasures = "schedule_measures.scd".loadRelative[0];

a = (
  outBus: 0,
  amp: 0.2,
  pPos: 0,
  pSpread: 1,
  freq: 220,
  envBuf: ~synthDefSupport[\sin_buf_1].bufnum,
  run: {
    var args = [
      outBus: ~outBus,
      amp: ~amp,
      pPos: ~pPos,
      pSpread: ~pSpread,
      freq: ~freq,
      envBuf: ~envBuf,
      env: ~env
    ];

    args.postln;

    Synth(\ddsynth, args);
  }
);

b = ~resolveEnvs.value([
  (
    bpm: 100, bpb: 4, events: [
      a.merge((
        env: Env([~quiet, 1, ~quiet], [2, 2], \exp).asArray,
        beat: 1
      ))
    ]
  ),
  (events: [])
]);

~stop = ~scheduleMeasures.value(b);
~stop.value;
s.queryAllNodes

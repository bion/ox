var resolveEnvs = "resolve_envs.scd".loadRelative[0];
var scheduleMeasures = "schedule_measures.scd".loadRelative[0];

SynthDef(\ping, {
  Out.ar(
    [0, 1],
    SinOsc.ar.tanh * 0.2 * EnvGen.kr(
      Env([0, 1, 0], [0.01, 0.45], \sin),
      doneAction: 2
    )
  );
}).load(s);

SynthDef(\pong, {
  Out.ar(
    [0, 1],
    SinOsc.ar.tanh * 0.2 * EnvGen.kr(
      Control.names([\env]).kr(Env.newClear(64)),
      doneAction: 2
    )
  );
}).load(s);

~stop = scheduleMeasures.value(
  resolveEnvs.value([
    (bpm: 120, bpb: 4, events: [
      (name: \foo, run: {
        ~thing.postln;
        Synth(\pong, [\env, ~thing.asArray])
      }, envs: (thing: -24.dbamp), beat: 1),
      (run: { 1.postln; Synth(\ping) }, beat: 1),
      (run: { 2.postln; Synth(\ping) }, beat: 2),
      (run: { 3.postln; Synth(\ping) }, beat: 3),
      (name: \foo, env: \thing, curve: \exp, val: 1, beat: 3),
      (run: { 4.postln; Synth(\ping) }, beat: 4),
    ]),

    (events: [
      (run: { 5.postln; Synth(\ping) }, beat: 1),
      (run: { 6.postln; Synth(\ping) }, beat: 2),
      (run: { 7.postln; Synth(\ping) }, beat: 3),
      (name: \foo, env: \thing, curve: \exp, val: -24.dbamp, beat: 3),
      (run: { 8.postln; Synth(\ping) }, beat: 4),
    ])
  ]);
);

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

~stop = scheduleMeasures.value([
  (bpm: 120, bpb: 4, children: [
    (run: { Synth(\ping) }, beat: 1),
    (run: { Synth(\ping) }, beat: 2),
    (run: { Synth(\ping) }, beat: 3),
    (run: { Synth(\ping) }, beat: 4),
  ]),
  (children: [
    (run: { Synth(\ping) }, beat: 1),
    (run: { Synth(\ping) }, beat: 2),
    (run: { Synth(\ping) }, beat: 3),
    (run: { Synth(\ping) }, beat: 4),
  ])
]);

~stop.value;

var scheduleMeasures = "schedule_measures.scd".loadRelative[0],
stop,
testMeasures;

SynthDef(\ping, {
  Out.ar(
    [0, 1],
    SinOsc.ar.tanh * 0.2 * EnvGen.kr(
      Env([0, 1, 0], [0.01, 0.45], \sin),
      doneAction: 2
    )
  );
}).load(s);

testMeasures = [
  (bpm: 120, bpb: 4, children: [
    (run: { 1.postln; Synth(\ping) }, beat: 1),
    (run: { 2.postln; Synth(\ping) }, beat: 2),
    (run: { 3.postln; Synth(\ping) }, beat: 3),
    (run: { 4.postln; Synth(\ping) }, beat: 4),
  ]),
  (children: [
    (run: { 5.postln; Synth(\ping) }, beat: 1),
    (run: { 6.postln; Synth(\ping) }, beat: 2),
    (run: { 7.postln; Synth(\ping) }, beat: 3),
    (run: { 8.postln; Synth(\ping) }, beat: 4),
  ])
];

~stop = scheduleMeasures.value(testMeasures);
~stop.value;

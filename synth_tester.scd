"ox.scd".loadRelative;

~names = [\test_synth];
~channels = ~initChannels.value(~names);

~note = ~defaults.value(
  (
    outBus: 0,
    amp: 1,
    freq: 220,
    synthDef: ~synthDefs[\fank_mono],
    run: {
      var params, requiredNames, addedNames = [];

      requiredNames = ~synthDef.allControlNames.select { |controlName|
        controlName.defaultValue.isNil;
      };

      params = ~synthDef.allControlNames.inject([]) { |result, controlName|
        addedNames = addedNames.add(controlName.name);
        result = result.add(controlName.name);
        result = result.add(currentEnvironment.at(controlName.name));
      };

      addedNames.difference(requiredNames).do { |name|
        ("event " ++ ~name ++ " missing " ++ name).postln;
      };

      Synth(~synthDef.name, params);
    }
  )
);

~score = ~resolveEnvs.value([
  (
    bpm: 100, bpb: 4, events: [
      ~note.value((
        name: \test_synth,
        env: ~env,
        beat: 1,
        freq: PC(\f, 4).freq,
        envs: (env: ~quiet)
      ))
    ]
  ),
  (
    events: [
      (name: \test_synth, env: \env, curve: \exp, val: 0.dbamp),
    ]
  ),
  (
    events: [
      (name: \test_synth, env: \env, curve: \exp, val: ~quiet),
    ]
  ),
  (
    events: [
      ~free.value(\test_synth)
    ]
  )
]);

~stop = ~scheduleMeasures.value(~channels, ~score);
~stop.value;
~channels.do { |c| c.finish.value }

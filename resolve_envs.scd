var measureType, prepareEnvs;

measureType = { |event|
  var return;

  if (Set[\name, \curve, \val].isSubsetOf(event.keys)) {
    return = \curveNode;
  };

  if (Set[\run, \name, \envs].isSubsetOf(event.keys)) {
    return = \initial;
  };

  return;
};

prepareEnvs = { |event|
  var return = event.envs.collect { |val|
    (levels: List[val], times: List[], curves: List[]);
  };

  return.event = event;

  return;
};

{ |measures|
  var bpm = measures.first.bpm;
  var bpb = measures.first.bpb;
  var beatDur = 60 / bpm;
  var allEnvelopes = IdentityDictionary[];
  var currentMeasureStartTime = 0;

  measures.do { |measure|
    bpm = measure.bpm ? bpm;
    bpb = measure.bpb ? bpb;
    beatDur = 60 / bpm;

    measure.events.do { |event|
      switch(measureType.value(event),
        \initial, {
          allEnvelopes[event.name] = prepareEnvs.value(event);
        },
        \curveNode, {
          var eventEnvs, env;

          eventEnvs = allEnvelopes[event.name];
          eventEnvs ?? { Error("No initial event for: " + event.name).throw };
          env = eventEnvs[event.env];
          env ?? { Error("No initial value for env: " + event.env).throw };

          env.levels.add(event.val);
          env.times.add(beatDur * (event.beat - 1) + currentMeasureStartTime);
          env.curves.add(event.curve);
        };
      );
    };

    currentMeasureStartTime = currentMeasureStartTime + (beatDur * bpb);
  };

  allEnvelopes.values.do { |envs|
    var event = envs.event;

    envs.keysValuesDo { |k, env|
      if (k != \event) {
        event[k] = Env(env.levels, env.times, env.curves);
      };
    };
  };

  measures;
}

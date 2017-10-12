{ |measures|
  var clock = TempoClock.new;
  var firstMeasure = measures.first;
  var currentMeasureIndex = 0;
  var keepPlaying = true;
  var stopPlaying = { keepPlaying = false };

  if (firstMeasure.bpm.isNil) {
    Error("first measure must specify bpm").throw;
  };

  if (firstMeasure.bpb.isNil) {
    Error("first measure must specify bpb").throw;
  };

  clock.sched(0, {
    // must be set inside scheduling thread
    clock.beatsPerBar = firstMeasure.bpb;
    clock.tempo = firstMeasure.bpm / 60;

    // schedule each measure one beat before it begins
    clock.sched(1, {
      var measure = measures[currentMeasureIndex];
      var wakeUpIn;

      if (keepPlaying) {
        measure.events.do { |event|
          if (event[\run].notNil) {
            if (event.beat.isNil) {
              ("No beat specified for " + event).warn;
            } {
              s.makeBundle(event.beat * clock.beatDur, { event.use(event[\run]) });
            };
          };
        };

        if (currentMeasureIndex < measures.size) {
          wakeUpIn = measure.bpb;
        } {
          wakeUpIn = nil;
        };
      };

      currentMeasureIndex = currentMeasureIndex + 1;

      wakeUpIn;
    });
  });

  CmdPeriod.doOnce(stopPlaying);
  stopPlaying;
}

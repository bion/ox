{ |measures|
  var clock = TempoClock.new;
  var firstMeasure = measures.first;
  var currentMeasureIndex = 0;
  var keepPlaying = true;
  var stopPlaying = { keepPlaying = false };

  clock.sched(0, {
    // must be set inside scheduling thread
    clock.beatsPerBar = firstMeasure.bpm;
    clock.tempo = firstMeasure.bpm / 60;

    // schedule each measure one beat before it begins
    clock.sched(1, {
      var measure = measures[currentMeasureIndex];
      var wakeUpIn;

      if (keepPlaying) {
        measure.children.do { |child|
          s.makeBundle(child.beat * clock.beatDur, child[\run]);
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

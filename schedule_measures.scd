{ |channels, measures|
  var clock = TempoClock.new;
  var firstMeasure = measures.first;
  var currentMeasureIndex = 0;
  var keepPlaying = true;
  var stopPlaying;
  var cleanupDone = false;

  channels = channels ? IdentityDictionary[];

  stopPlaying = {
    CmdPeriod.run;

    channels.values.do { |channel| channel.finish.value };

    keepPlaying = false;
    cleanupDone = true;
  };

  if (firstMeasure.bpm.isNil) {
    Error("first measure must specify bpm").throw;
  };

  if (firstMeasure.bpb.isNil) {
    Error("first measure must specify bpb").throw;
  };

   channels.values.do { |channel|
     channel.start.value;
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
        measure.events.flatten.do { |event|
          if (event[\run].notNil) {
            if (event.beat.isNil) {
              ("No beat specified for " + event).warn;
            } {
              if (channels[event[\name]].notNil) {
                event.outBus = channels[event[\name]].bus;
              };

              s.makeBundle(event.beat * clock.beatDur, {
                event.use(event[\run]);
              });
            };
          };
        };

        if (currentMeasureIndex < measures.size) {
          wakeUpIn = measure.bpb;
        } {
          wakeUpIn = nil;
          stopPlaying.value;
        };
      };

      currentMeasureIndex = currentMeasureIndex + 1;

      wakeUpIn;
    });
  });

  CmdPeriod.doOnce(stopPlaying);
  stopPlaying;
}

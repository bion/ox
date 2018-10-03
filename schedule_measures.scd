var printCurrentMeaure = { |currentMeasureIndex, measures|
  [
    "scheduling measure ",
    (currentMeasureIndex + 1),
    " of ",
    measures.size
  ].join.postln;
};

var checkBpm = { |firstMeasure|
  if (firstMeasure.bpm.isNil) {
    Error("first measure must specify bpm").throw;
  };
};

var checkBpb = { |firstMeasure|
  if (firstMeasure.bpb.isNil) {
    Error("first measure must specify bpb").throw;
  };
};

var startChannels = { |channels|
  channels.values.do { |channel|
    channel.start.value;
  };
};

var sendSynthMessages = { |synths, event|
  if (event.synthMessage.notNil) {
    synths[event.name].do { |synth|
      synth.performMsg(event.synthMessage)
    };
  };
};

var checkEventHasBeat = { |event|
  if (event.beat.isNil) {
    ("No beat specified for " + event).warn;
  }
};

{ |channels, measures, printEventNames = false|
  var clock = TempoClock.new;
  var firstMeasure = measures.first;
  var currentMeasureIndex = 0;
  var keepPlaying = true;
  var stopPlaying;
  var wakeUpIn;
  var cleanupDone = false;
  var synths = IdentityDictionary[];

  channels = channels ? IdentityDictionary[];

  stopPlaying = {
    channels.values.do { |channel| channel.finish.value };

    wakeUpIn = nil;
    keepPlaying = false;
    cleanupDone = true;
    "end of score".postln;
  };

  checkBpm.value(firstMeasure);
  checkBpb.value(firstMeasure);
  startChannels.value(channels);

  clock.sched(0, {
    // must be set inside scheduling thread
    clock.beatsPerBar = firstMeasure.bpb;
    clock.tempo = firstMeasure.bpm / 60;

    // schedule each measure one beat before it begins
    clock.sched(1, {
      var measure = measures[currentMeasureIndex];

      if (keepPlaying) {
        printCurrentMeaure.value(currentMeasureIndex, measures);

        measure.events.flatten.do { |event|
          var eventName = event.name;
          var newSynths;

          if (printEventNames) {
            ("playing " + eventName).postln;
          };

          sendSynthMessages.value(synths, event);

          if (event[\run].notNil) {
            checkEventHasBeat.value(event);

            if (channels[eventName].notNil) {
              event.outBus = channels[event.name].bus;
            };

            s.makeBundle(event.beat * clock.beatDur, {
              newSynths = event.use(event[\run]);
            });

            switch(newSynths.class,
              Array, { synths[eventName] = newSynths },
              Synth, { synths[eventName] = [newSynths] },
              {
                [
                  "run function for event ",
                  eventName,
                  " returned a",
                  newSynths.class
                ].join(" ").warn;
              }
            );
          };
        };

        if ((currentMeasureIndex + 1) < measures.size) {
          wakeUpIn = measure.bpb ? wakeUpIn;
        } {
          clock.sched(wakeUpIn, stopPlaying);
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

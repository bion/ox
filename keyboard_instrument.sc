MIDIControlSpec {
  var <>controlName, <>inputEndPoint, <>messageNumber, <>mapFunction, <currentMIDIValue, <currentValue, <>paramIndex, outputDeviceMemo = nil;

  *new { |a, b, c, d|
    ^super.newCopyArgs(a, b, c, d);
  }

  update { |midiValue|
    currentMIDIValue = midiValue;
    currentValue = mapFunction.value(midiValue);

    ^currentValue;
  }

  outputDevice {
    if (outputDeviceMemo.isNil) {
      var index = MIDIClient.destinations.detectIndex { |endPoint|
        endPoint.device == inputEndPoint.device &&
        endPoint.name == inputEndPoint.name;
      };

      outputDeviceMemo = MIDIOut(index);
    };

    ^outputDeviceMemo;
  }

  updateCurrentValueOnEndPoint {
    this.outputDevice.control(
      chan: 0,
      ctlNum: messageNumber,
      val: currentMIDIValue
    );
  }

  printOn { |stream|
    stream << "MIDIControlSpec( " <<
    "controlName: " << controlName <<
    ", messageNumber: " << messageNumber <<
    ", currentValue: " << currentValue <<
    ", paramIndex: " << paramIndex <<
    " )";
  }
}

KeyboardInstrumentSettingsArchive {
  var <controlMap, <currentParams;

  *new { |...args|

    ^super.newCopyArgs(*args);
  }
}

NoteOnEvent {
  var <midiNoteNum, <velocity;

  *new { |midiNoteNumArg, velocityArg|

    ^super.newCopyArgs(midiNoteNumArg, velocityArg);
  }

  hash {
    ^midiNoteNum.hash;
  }

  printOn { |stream|
    stream << "NoteOnEvent( " <<
    "midiNoteNum: " << midiNoteNum <<
    ", velocity: " << velocity <<
    " )";
  }

  == { |other|
    ^(midiNoteNum == other.midiNoteNum);
  }
}

KeyboardInstrument {
  var <keyboardDevice, <options;
  var <>velocityToAmpFunc = { |velocity| velocity.linexp(0, 127, -60.dbamp, 0) };
  var <controlMap, <paramNameSet, <>keyboardNote, <keyboardSynths, <midiFuncs, <currentParams;
  var <glissControlEnabled = false, <newGlissNoteEvents, <>glissDur = 0.5, <notesDownAtGlissInit, <notesOffDuringGliss;
  var <transitionedSynths, <fadedInSynths, <fadedOutSynths, <normalSynths;

  *new { |keyboardDevice, options|
    if (keyboardDevice.isNil) {
      ("KeyboardInstrument initialized with nil keyboardDevice arg").warn;
    };

    if (keyboardDevice.uid.isNil) {
      ("KeyboardInstrument's keyboardDevice has nil uid").warn;
    };

    ^super.newCopyArgs(keyboardDevice, options).init;
  }

  init {
    midiFuncs = [];
    currentParams = [];
    newGlissNoteEvents = Set(12);
    notesDownAtGlissInit = Set(12);
    notesOffDuringGliss = Set(12);
    transitionedSynths = [];
    fadedInSynths = [];
    fadedOutSynths = [];
    normalSynths = [];

    keyboardSynths = Array.fill(128, { [] });
  }

  enable {
    midiFuncs = midiFuncs ++ [
      MIDIFunc.noteOn({ |...args|
        this.handleKeyboardNoteOn(*args);
      }, srcID: keyboardDevice.uid),

      MIDIFunc.noteOff({ |...args|
        this.handleKeyboardNoteOff(*args);
      }, srcID: keyboardDevice.uid),

      MIDIFunc.cc({ |...args|
        this.handleControlChange(*args);
      })
    ];
  }

  disable {
    midiFuncs.do(_.free);
    midiFuncs = [];
  }

  archiveSettings { |path|
    var archive = KeyboardInstrumentSettingsArchive(controlMap, currentParams);
    archive.writeArchive(path);
  }

  loadSettingsArchive { |path|
    var archive = Object.readArchive(path);

    if (archive.isNil) {
      Error("No archive found at path: " ++ path).throw;
    };

    controlMap = archive.controlMap;
    currentParams = archive.currentParams;

    controlMap.do { |specList|
      specList.do { |spec|
        spec.updateCurrentValueOnEndPoint;
      };
    };
  }

  checkParamsForSynth { |synthName|
    var synthDesc = SynthDescLib.at(synthName);

    if (synthDesc.isNil) {
      Error("Unable to find synth description for " ++ synthName).throw;
    };

    paramNameSet = synthDesc
    .controls
    .collect(_.name)
    .inject(Set(12), _.add(_))
  }

  handleKeyboardNoteOn { |velocity, midiNote|
    var noteOnEvent = NoteOnEvent(midiNote, velocity);

    if (glissControlEnabled) {
      if (notesDownAtGlissInit.includes(noteOnEvent).not) {
        newGlissNoteEvents.add(noteOnEvent);
      };

      notesOffDuringGliss.remove(noteOnEvent);
    } {
      this.playKeyboardNote(velocity, midiNote);
    };
  }

  playKeyboardNote { |velocity, midiNote|
    var synths = keyboardNote.value(velocityToAmpFunc.value(velocity), midiNote, currentParams);

    keyboardSynths[midiNote].do(_.set(\gate, 0));

    if (synths.isArray) {
      keyboardSynths[midiNote] = synths;
      normalSynths = normalSynths ++ synths;
    } {
      keyboardSynths[midiNote] = [synths];
      normalSynths = normalSynths.add(synths);
    };
  }

  handleKeyboardNoteOff { |velocity, midiNote|
    var noteOnEvent = NoteOnEvent(midiNote);

    if (glissControlEnabled) {
      newGlissNoteEvents.remove(noteOnEvent);
      notesOffDuringGliss.add(noteOnEvent);
    } {
      keyboardSynths[midiNote].do(_.set(\gate, 0));
      keyboardSynths[midiNote] = [];
    };
  }

  glissInit {
    "\n\n***********************************".postln;
    notesOffDuringGliss = Set(12);
    notesDownAtGlissInit = Set(12);

    keyboardSynths.do { |synths, noteNum|
      if (synths.size > 0) {
        notesDownAtGlissInit.add(NoteOnEvent(noteNum));
      };
    };
  }

  glissExec {
    var transitions = [];
    var claimedNewNoteNums = Set(12);
    var claimedOldNoteNotes = Set(12);
    var oldNoteNums = Set(12);
    var transitionsGroupedByOldNote = [];
    var orphanedNewNotes, orphanedOldNotes;
    var unchangedNotes = notesDownAtGlissInit.difference(notesOffDuringGliss);

    ("newGlissNoteEvents: " ++ newGlissNoteEvents).postln;
    // find all possible transitions between the currently playing notes and the gliss targets
    keyboardSynths.do { |synths, oldNoteNum|
      if (
        (synths.size > 0) &&
        unchangedNotes.includes(NoteOnEvent(oldNoteNum)).not
      ) {
        var thisNoteTransitions = newGlissNoteEvents.asArray.collect { |newNoteEvent /* NoteOnEvent */|
          (
            distance: (oldNoteNum - newNoteEvent.midiNoteNum).abs,
            oldNoteNum: oldNoteNum,
            newNoteNum: newNoteEvent.midiNoteNum,
            velocity: newNoteEvent.velocity
          );
        };

        oldNoteNums.add(oldNoteNum);

        transitionsGroupedByOldNote = transitionsGroupedByOldNote.add(
          thisNoteTransitions.sort { |a, b|
            a.distance < b.distance
          }
        );
      };
    };

    ("transitionsGroupedByOldNote: " ++ transitionsGroupedByOldNote).postln;
    // get the collection of distances that minimizes the overall distance traveled
    while {
      (transitionsGroupedByOldNote.size > 0) &&
      (claimedNewNoteNums.size < newGlissNoteEvents.size)
    } {
      var minimumDistance = 1000;
      var minimumTransition = nil;
      var minimumDistanceIndex = nil;

      transitionsGroupedByOldNote.do { |noteTransitionCollection, i|
        var candidateTransition = noteTransitionCollection[0];

        if (candidateTransition.distance < minimumDistance) {
          minimumDistance = candidateTransition.distance;
          minimumDistanceIndex = i;
          minimumTransition = candidateTransition;
        };
      };

      transitions = transitions.add(minimumTransition);
      transitionsGroupedByOldNote.removeAt(minimumDistanceIndex);
      claimedOldNoteNotes.add(minimumTransition.oldNoteNum);
      claimedNewNoteNums.add(minimumTransition.newNoteNum);
    };

    // update synths
    ("transitions: " ++ transitions).postln;
    transitions.do { |transition|
      var synths = keyboardSynths[transition.oldNoteNum];
      var firstSynth = synths[0];

      keyboardSynths[transition.newNoteNum].do(_.set(\gate, 0));
      keyboardSynths[transition.oldNoteNum] = [];
      keyboardSynths[transition.newNoteNum] = synths;

      synths.do { |synth|
        transitionedSynths = transitionedSynths.add(synth);
        synth.set(
          \freq, transition.newNoteNum.midicps,
          \gliss, 1,
          \amp, velocityToAmpFunc.value(transition.velocity)
        );
      };

      TempoClock.default.schedAbs(TempoClock.default.beats + glissDur, {
        var synthsToUpdate = keyboardSynths[transition.newNoteNum];

        if (synthsToUpdate.size > 0) {
          if (synthsToUpdate[0].nodeID == firstSynth.nodeID) {
            synthsToUpdate.do(_.set(\gliss, 0));
          };
        };
      });
    };

    // fade out orphaned old notes
    orphanedOldNotes = oldNoteNums.difference(transitions.collect(_.oldNoteNum));
    ("orphanedOldNotes: " ++ orphanedOldNotes).postln;
    orphanedOldNotes.do { |midiNote|
      var synths = keyboardSynths[midiNote];
      fadedOutSynths = fadedOutSynths ++ synths;

      synths.do(_.set(\fade, 0));
      keyboardSynths[midiNote] = [];

      TempoClock.default.schedAbs(TempoClock.default.beats + glissDur, {
        synths.do(_.set(\gate, 0));
      });
    };

    // fade in orphaned new notes
    orphanedNewNotes = newGlissNoteEvents.difference(
      transitions.collect({ |transition|
        NoteOnEvent(transition.newNoteNum)
      })
    );
    ("orphanedNewNotes: " ++ orphanedNewNotes).postln;
    orphanedNewNotes.do { |noteOnEvent|
      var midiNote = noteOnEvent.midiNoteNum;
      var synths = keyboardNote.value(
        velocityToAmpFunc.value(noteOnEvent.velocity),
        midiNote,
        currentParams ++ [fade: 0],
      );

      if (synths.isArray.not) {
        synths = [synths];
      };

      fadedInSynths = fadedInSynths ++ synths;

      // if fade is set immediately after synth instantiation, the synth
      // will get fade initialized to zero instead of set after starting
      TempoClock.default.schedAbs(TempoClock.default.beats + 0.01, {
        synths.do(_.set(\fade, 1));
      });

      keyboardSynths[midiNote].do(_.set(\gate, 0));
      keyboardSynths[midiNote] = synths;
    };

    newGlissNoteEvents = Set(12);
  }

  handleControlChange { |value, number, chan, srcID|
    var spec, src;

    if (keyboardDevice.uid == srcID) {
      // value == 127 when pedal goes down
      if (value == 127) {
        this.glissInit;
        glissControlEnabled = true;
        "gliss control enabled".postln;
        ^nil;
      };

      // value == 127 when pedal goes up
      if (value == 0) {
        "executing gliss".postln;
        this.glissExec;

        glissControlEnabled = false;
        "gliss control disabled".postln;
        ^nil;
      };

      ("Value not recognized for gliss event " ++ value).postln;
      ^nil;
    };

    src = controlMap[srcID];

    if (src.isNil) {
      ("No src recognized for ID " ++ srcID).postln;
      ^nil;
    };

    spec = src[number];

    if (spec.isNil) {
      ("Nothing mapped for CC number " ++ number).postln;
      ^nil;
    };

    spec.update(value);
    currentParams[spec.paramIndex * 2 + 1] = spec.currentValue;

    keyboardSynths.flatten.do(_.set(spec.controlName, spec.currentValue));

    if (spec.controlName != \amp) {
      (spec.controlName ++ ": " ++ spec.currentValue).postln;
    };

    ^true;
  }

  getSpecValueByName { |name|
    var index = currentParams.indexOf(name);

    if (index.isNil) {
      Error("KeyboardInstrument unable to find param value for: " ++ name).throw;
    };

    ^currentParams[index + 1];
  }

  buildControlMap { |...args|
    if (args.size % 4 != 0) {
      Error("MIDIControlSpecGroup#buildControlMap takes arguments in groups of 4").throw;
    };

    controlMap = IdentityDictionary();
    currentParams = [];

    args.clump(4).do { |tuple, i|
      var specName = tuple[0],
      specMIDIEndPoint = tuple[1],
      specMIDIMessageNumber = tuple[2],
      specMapFunction = tuple[3],
      spec = MIDIControlSpec(
        specName,
        specMIDIEndPoint,
        specMIDIMessageNumber,
        specMapFunction,
      );

      spec.update(0);

      if (paramNameSet.includes(spec.controlName).not) {
        Error(
          "MIDIControlGroup#buildControlMap called with missing param: " ++ spec.controlName
        ).throw;
      };

      if (controlMap[spec.inputEndPoint.uid].isNil) {
        controlMap[spec.inputEndPoint.uid] = IdentityDictionary[];
      };

      controlMap[spec.inputEndPoint.uid].add(spec.messageNumber -> spec);
      spec.paramIndex = i;

      currentParams = currentParams ++ [spec.controlName, spec.currentValue];
    };
  }
}

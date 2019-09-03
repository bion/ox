MIDIControlSpec {
  var <>controlName, <>channelNumber, <>mapFunction, <>currentValue, <>paramIndex;

  *new { |a, b, c, d|
    ^super.newCopyArgs(a, b, c, d);
  }

  update { |midiValue|
    currentValue = mapFunction.value(midiValue);

    ^currentValue;
  }
}

KeyboardInstrument {
  var <keyboardDevice, <controlDevice, <controlMap, <paramNameSet, <>keyboardNote, keyboardSynths, midiFuncs, currentParams;

  *new { |keyboardDevice, controlDevice|
    if (keyboardDevice.isNil) {
      ("KeyboardInstrument initialized with nil keyboardDevice arg").warn;
    };

    if (controlDevice.isNil) {
      ("KeyboardInstrument initialized with nil controlDevice arg").warn;
    };

    ^super.newCopyArgs(keyboardDevice, controlDevice).init;
  }

  init {
    midiFuncs = [];
    currentParams = [];

    keyboardSynths = Array.fill(128, { [] });
  }

  enable {
    midiFuncs = [
      MIDIFunc.noteOn({ |...args|
        var src = args[3];

        if (src === keyboardDevice.uid) {
          this.handleKeyboardNoteOn(*args);
        };
      }),

      MIDIFunc.noteOff({ |...args|
        var src = args[3];

        if (src === keyboardDevice.uid) {
          this.handleKeyboardNoteOff(*args);
        };
      }),

      MIDIFunc.cc({ |...args|
        var src = args[3];

        if (src === controlDevice.uid) {
          this.handleControlChange(*args);
        }
      })
    ];
  }

  disable {
    midiFuncs.do(_.free);
    midiFuncs = [];
  }

  checkParamsForSynth { |synthName|
    var synthDesc = SynthDescLib.at(synthName);

    if (synthDesc.isNil) {
      Error("Unable to find synth description for " ++ synthName).throw;
    };

    paramNameSet = synthDesc
    .controls
    .collect(_.name)
    .inject(Set(), _.add(_))
  }

  handleKeyboardNoteOn { |velocity, midiNote|
    var synths = keyboardNote.value(velocity, midiNote, currentParams);

    if (synths.isArray) {
      keyboardSynths[midiNote] = synths;
    } {
      keyboardSynths[midiNote] = [synths];
    };
  }

  handleKeyboardNoteOff { |velocity, midiNote|
    keyboardSynths[midiNote].do(_.set(\gate, 0));
    keyboardSynths[midiNote] = [];
  }

  handleControlChange { |value, number, chan, src|
    var spec = controlMap[number];

    if (spec.notNil) {
      spec.update(value);
      currentParams[spec.paramIndex * 2 + 1] = spec.currentValue;

      keyboardSynths.flatten.do(_.set(spec.controlName, spec.currentValue));

      (spec.controlName ++ ": " ++ spec.currentValue).postln;
    };
  }

  buildControlMap { |...args|
    if (args.size % 3 != 0) {
      Error("MIDIControlSpecGroup#buildControlMap takes arguments in groups of 3").throw;
    };

    controlMap = IdentityDictionary();

    args.clump(3).do { |tuple, i|
      var spec = MIDIControlSpec.performList(\new, tuple);

      spec.update(0);

      if (paramNameSet.includes(spec.controlName).not) {
        Error(
          "MIDIControlGroup#buildControlMap called with missing param: " ++ spec.controlName
        ).throw;
      };

      spec.paramIndex = i;

      controlMap.add(spec.channelNumber -> spec);
    };

    currentParams = controlMap.values.inject([], { |result, spec|
      result ++ [spec.controlName, spec.currentValue]
    });
  }
}

if (~midiInitialized.isNil) {
  ~midiInitialized = false;
};

~initKeyboard = {
  var on = MIDIFunc.noteOn({ |veloc, num, chan, src|
    ~keyboardSynths[num] = ~keyboardNoteOn.value(veloc, num, chan, src);
  }),

  off = MIDIFunc.noteOff({ |veloc, num, chan, src|
    ~keyboardSynths[num].release;
  });

  ~keyboardSynths = Array.newClear(128);
  ~cleanupMidi = { on.free; off.free; };
};

if (~midiInitialized.not) {
  MIDIClient.init;
  MIDIIn.connectAll;
  ~initKeyboard.value;
  ~midiInitialized = true;
};

~keyboardNoteOn = { |veloc, num|
  Synth(\default, [freq: num.midicps, amp: veloc * 0.00315]);
};

MIDIClient.myoutports

loadRelative("/synth_def_support.scd");
loadRelative("/synth_def_support.scd");
loadRelative("/keyboard_synth_defs.scd");

s.options.device = "JackRouter";

if (MIDIClient.initialized.not) {
  MIDIClient.init;
  MIDIIn.connectAll;
  // MIDIClient.restart;
  // MIDIClient.disposeClient;
  MIDIClient.sources.postln;
};

b = Bus.audio(numChannels: 2);

SynthDef(\verb, {
  arg inBus;
  var in = In.ar(inBus, 2);

  Out.ar(0, GVerb.ar(in, 20, revtime: 0.35).mean);
}).load(s);

if (v.isNil) {
  v = Synth(\verb, [inBus: b]);

  CmdPeriod.doOnce({
    v = nil;
  });
};

p = MIDIClient.sources.detect { |source|
  source.device == "Digital Piano";
};

g = KeyboardInstrument(p, (trigger_gliss: (chan: 64)));
MIDIClient.sources
c = MIDIClient.sources.select { |source|
  source.device == "BCR2000"
};

t = MIDIClient.sources.detect { |source|
  source.device == "Breath Controller";
};

g.keyboardNote = { |amp, midiNoteNum, params|
  Synth(\clean_cool, params ++ [
    outBus: 2,
    amp: amp,
    freq: midiNoteNum.midicps
  ]);
};

g.velocityToAmpFunc = { |velocity| velocity.linexp(0, 100, -60.dbamp, 0.5)};
g.checkParamsForSynth(\clean_cool);

g.buildControlMap(
  \glissDur, c, 81, { |controlValue| controlValue.linlin(0, 127, 0.1, 3) },
  \diss, c, 82, { |controlValue| controlValue.linlin(0, 127, 0.0, 2) }
  // \indexLFOlo, c, 81, { |controlValue| controlValue.linlin(0, 127, 0, 3.8) },
  // \indexLFOhi, c, 82, { |controlValue| controlValue.linlin(0, 127, 0, 4) },
  // \trigOverlap, c, 89, { |controlValue| controlValue.linlin(0, 127, 1, 12) },
  // \vibeWidth, c, 90, { |controlValue| controlValue.linlin(0, 127, 0.0, 0.1) },
  // \vibOnset, c, 91, { |controlValue| controlValue.linlin(0, 127, 0.01, 1) },
  // \pSpread, c, 97, { |controlValue| controlValue.linlin(0, 127, 0, 1) },
  // \gp, c, 98, { |controlValue| controlValue.linlin(0, 127, 0.01, 0.5) },
  // \diss, c, 99, { |controlValue| controlValue.linlin(0, 127, 0, 4) },
  // \amp, t, 2, { |controlValue|
  //   if (controlValue == 0) {
  //     0;
  //   } {
  //     controlValue.linexp(0, 80, -60.dbamp, 1);
  //   };
  // };
);

g.enable;
// thisProcess.nowExecutingPath
// g.archiveSettings("./sclang_archives/keyboard_instrument_settings.sca".resolveRelative);
//  g.loadSettingsArchive("sclang_archives/keyboard_instrument_settings.sca".resolveRelative);

/*
 * orphaned still playing synth:
*/
// g.normalSynths.collect(_.nodeID).includes(1086) true
// g.normalSynths.collect(_.nodeID).includes(1065) true

// g.transitionedSynths.collect(_.nodeID).includes(1086) true
// g.transitionedSynths.collect(_.nodeID).includes(1065) true

// g.fadedInSynths.collect(_.nodeID).includes(1086) false
// g.fadedInSynths.collect(_.nodeID).includes(1065) false

// g.fadedOutSynths.collect(_.nodeID).includes(1086) false
// g.fadedOutSynths.collect(_.nodeID).includes(1065) false

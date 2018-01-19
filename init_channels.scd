{ |names|
  var channels = IdentityDictionary[];

  names.do { |name|
    var channel;
    var bus = Bus.audio(s, 2);
    var recordBuf = Buffer.alloc(s, s.sampleRate.nextPowerOfTwo * 2, 2);
    var synth;

    recordBuf.write(
      ("~/dev/ox/sc-out/" ++ name ++ ".aiff").standardizePath,
      "aiff",
      "int16",
      0,
      0,
      true
    );

    channel = (
      name: name,
      bus: bus,
      start: {
        ("start recording " ++ name).postln;
        synth = Synth(\recordRoute, [
          inBus: bus,
          buf: recordBuf,
          outBus: 0
        ]);
      },
      finish: {
        ("stop recording " ++ name).postln;
        synth.free;
        recordBuf.close;
        recordBuf.free;
      }
    );

    channels[name] = channel;
  };

  channels;
}

var getPathForName = { |name|
  ("~/dev/ox/sc-out/" ++ name ++ ".aiff").standardizePath;
};

{ |names|
  var channels = IdentityDictionary[];

  names.do { |name|
    var channel;
    var bus = Bus.audio(s, 2);
    var recordBuf = Buffer.alloc(s, s.sampleRate.nextPowerOfTwo * 2, 2);
    var filePath = getPathForName.value(name);
    var synth;

    File.delete(filePath);

    recordBuf.write(
      filePath,
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
        bus.free;
        synth.free;
        recordBuf.close;
        recordBuf.free;
      }
    );

    channels[name] = channel;
  };

  channels;
}

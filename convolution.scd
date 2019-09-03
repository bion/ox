~loadBuf = { |path|
  var file, data, n, newData, outFile;

  if (File.exists(path).not) {
    Error("No file found at " ++ path).throw;
  };

  // 'protect' guarantees the file objects will be closed in case of error
  // Read original size of data
  file = SoundFile.openRead(path);
  data = Signal.newClear(file.numFrames);
  file.readData(data);

  // Convert to n = some power of 2 samples.
  n = data.size.nextPowerOfTwo;
  newData = data.resamp1(n);

  // Convert the resampled signal into a Wavetable.
  // resamp1 outputs an Array, so we have to reconvert to Signal
  newData = newData.as(Signal).asWavetable;
  ~buf = Buffer.loadCollection(s, newData);
};

~loadAll = { |inputPath|
  var paths = inputPath.pathMatch;

  if (paths.size == 0) {
    Error("No files found at " ++ inputPath).throw;
  };

  paths.collect { |path|
    var file, buf, data, nextPowerOfTwo;
    file = SoundFile.openRead(path);
    data = Signal.newClear(file.numFrames);
    file.readData(data);
    file.close;

    data = data.resamp1(data.size.nextPowerOfTwo);

    Buffer.loadCollection(s, data);
  };
};


play {
  var sig = Osc.ar(~good, PC(\c, 1).freq, mul: 0.1), chain;

  chain = FFT(LocalBuf(1024), sig, 0.25);
  chain = PV_MagAbove(chain, MouseX.kr(0, 10));
  sig = IFFT(chain);

  sig = EnvGen.kr(Env.perc, doneAction: 2) * sig;

  Out.ar(2, sig);
}

~bufs = ~loadAll.value("/Users/bion/MainDocuments/sound/sampled/AKWF/AKWF_piano/*.wav");
~bufs.size;
~bufs[8].plot
~bufs.indexOf(~good)

play {
  var sig, which, env;

  which = Select.kr(
    MouseX.kr(0, ~bufs.size - 2).round,
    ~bufs.collect(_.bufnum));

  which.poll;
  sig = LPF.ar(VOsc.ar(which, MouseY.kr(30, 1000, 1)), 15000);

  env = EnvGen.kr(Env.perc, Impulse.kr(2));
  sig = sig * env;

  sig ! 2;
}

//         // Load this into a buffer, or save to disk.
//         outFile = SoundFile(".... output path...")
//         .headerFormat_("WAV")
//         .sampleFormat_("float")
//         .numChannels_(1)
//         .sampleRate_(44100);
//         if(outFile.openWrite.notNil) {
//                 outFile.writeData(newData);
//         } {
//                 "Couldn't write output file".warn;
//         };
// } {
//         file.close;
//         if(outFile.notNil) { outFile.close };
// };
// )

b = Buffer.alloc(s, 2 ** 10, numChannels: 1)

e = Env([0, 0, 1, 0, 0], [20, 1, 1, 20])
g = e.asSignal(2**10)
b.sendCollection(g)
b.plot
Array.fill(100, {})

play { PlayBuf.ar(1, b, LFNoise2.kr(1).range(0.1, 0.8) * BufRateScale.kr(b), loop: 1) * 0.5  ! 2}

(
// interleave a multi-dimensional array
(
l = Signal.sineFill(16384, Array.fill(200, {0}).add(1));
r = Array.fill(16384, {1.0.rand2});
m = [Array.newFrom(l), r]; // a multi-dimensional array
m = m.lace(32768); // interleave the two collections
b = Buffer.alloc(s, 16384, 2);
)
(
b.loadCollection(m, 0, {|buf|
    x = { PlayBuf.ar(2, buf, BufRateScale.kr(buf), loop: 1) * 0.5 }.play;
});
)
b.plot;
x.free; b.free;



Signal.chebyFill(1000, [1]).plot;

// shifted to avoid DC offset when waveshaping a zero signal
Signal.chebyFill(1000, [0, 1], zeroOffset: true).plot;

// normalized sum of (unshifted) Chebyshev polynomials (the default)
Signal.chebyFill(1000, [0, 1, 0, 0, 0, 1], normalize: true, zeroOffset: false).plot;

Signal.chebyFill(1000, [0, 0, 1]).plot;
Signal.chebyFill(1000, [0.3, -0.8, 1.1]).plot;


// This waveshaping example uses two buffers, one with zero offset and
// the other not.
//
// 1. The offset version gives zero output (DC free) when waveshaping an
// input signal with amplitude of zero (e.g. DC.ar(0)).
//
// 2. The non-offset version makes better use of the full (-1 to 1) range
// when waveshaping a varying signal with amplitude near 1, but (if even
// Chebyshev polynomial degrees are used) will have a DC offset when
// waveshaping a signal with amplitude of zero.
//
// 3. Wrapping the non-offset Shaper in a LeakDC (the third signal in the
// example) cancels out any DC offsets (third version), while making full use
// of the -1 to 1 range.
(
s.waitForBoot({
    var amplitudes = [0, 1, 1, -2, 1];
    var sigs = [
        Signal.chebyFill(256+1, amplitudes, normalize: true, zeroOffset: true),
        Signal.chebyFill(256+1, amplitudes, normalize: true, zeroOffset: false)
    ];
    b = sigs.collect{ arg sig; Buffer.loadCollection(s, sig.asWavetableNoWrap) };
    s.sync;
    x = {
        var in = SinOsc.ar(100, 0, SinOsc.kr(0.1, 0, 0.5, 0.5));
        Shaper.ar(b, in) ++ LeakDC.ar(Shaper.ar(b[1], in))
    }.scope;
})
)
x.free; b.do(_.free); b = nil


(
// used to lag pitch
{
    SinOsc.ar(        // sine wave
        Lag3.kr(            // lag the modulator
            LFPulse.kr(4, 0, 0.5, 50, 400),    // frequency modulator
            Line.kr(0, 1, 15)                // modulate lag time
        ),
        0,    // phase
        0.3    // sine amplitude
    )
}.play
)
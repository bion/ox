a = {
  var tempo = MouseX.kr(50, 160);
  var trig = Impulse.kr(tempo / 60);
  var sig = SinOsc.ar(880, 0, Decay.kr(trig, 0.2));

  tempo.poll;

  Out.ar([0, 1], sig);
}.play
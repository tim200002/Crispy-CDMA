path = "c:\users\ephraim fuchs\desktop\";
so = Source(Sourcetype.Audiofile, path+"testAnalog1.mp3");
si = Sink();
sig1 = so.step();
[ups, downs] = rat(48000 / sig1.fs)
sam = Sampler(ups,downs);
%  sig1 = sig1.selectFromTo(1, sig1.length - 134);
sig2 = sam.step(sig1);

% player = si.playAudio(sig1);
player = si.playAudio(sig2);
player.pause

% si.saveToAudioFile(sig2, path+"saver.wav");


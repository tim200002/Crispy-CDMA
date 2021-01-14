% test JPEG compression for audio data
sou = Source('Audiofile', 'c:\users\ephraim fuchs\desktop\testMusic2_cut.mp3');
sig1 = sou.signalout;
sig2 = sig1.normByMax;
qua = Quantizer(8, -1);
sig3 = qua.step(sig2); % convert [-1, 1] to [0, 255]

[compressed, compRate] = JPEGCompress(sig3, 100);
disp(compRate);

% immediately decompress it
decomp = JPEGDecompress(compressed);
valuecont = qua.invPCM(decomp);
si = Sink();

player = si.playAudio(sig2); % original signal
%      player.pause
player = si.playAudio(valuecont); % compressed and decompressed signal
%      player.pause
%  si.saveToAudioFile('c:\users\ephraim fuchs\desktop\testAudioJpeg.wav');
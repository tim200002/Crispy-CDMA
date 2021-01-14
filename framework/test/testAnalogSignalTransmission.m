%%___________________________ PARAMETERS __________________________________
path = "c:\users\ephraim fuchs\desktop\";
carrierFreq = 8000;
% _________________________________________________________________________

sco = Scope();
%% SIGNAL GENERATION
dso = Source(Sourcetype.Audiofile, path + "testMusic1.mp3");
audiosignal = dso.step;

% Determine bandwidth and manually edit it!
figure; sco.yAxis = 'abs'; sco.plotFrequencyDomain(audiosignal);
figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(audiosignal);

bandWidth = 8000;
%% UP-MIXING
mixcomplex = Mixer(Mixertype.Cosine, carrierFreq);
mixedsig = mixcomplex.step(audiosignal);

figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(real(mixedsig));
%% AUDIO OUTPUT
dsi2 = Sink();
player = dsi2.playAudio(mixedsig);

player.pause;

dsi2.saveToAudioFile(mixedsig, path + "testAnalogMixed.wav");
%% AUDIO INPUT
dso2 = Source(Sourcetype.Audiofile, path + "testAnalogRec.wma");
recorded = dso2.step;

% Samplerate offset correction, manually:
recorded.fs = 44101;

figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(recorded);
%% OPTIONAL: BYPASS
recorded = real(mixedsig);

%% MIXING
mix2 = Mixer(Mixertype.Cosine, carrierFreq);
mixedrecsignal = mix2.step(recorded);

figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(mixedrecsignal);
%% LOW PASS FILTERING
lpf = RaisedCosineFilter(recorded.fs, 1024, 0.1, 50);
lpf.cutoffFreq = bandWidth;
demodrecsignal = lpf.step(mixedrecsignal);

figure;sco.yAxis = 'db'; sco.plotFrequencyDomain(lpf);

figure; sco.yAxis = 'real'; sco.plotTimeDomain(demodrecsignal);
figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(demodrecsignal, bandWidth + 200);
%% DC REMOVAL
demodrecsignal = demodrecsignal.removeDCOffset;
%% AUDIO OUTPUT
dsi3 = Sink();
player = dsi3.playAudio(demodrecsignal);

player.pause;

dsi3.saveToAudioFile(demodrecsignal, path + "testAnalogRecMixed.wav");
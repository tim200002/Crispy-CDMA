% test script for multiple analog signal transmission
%% =========================== PARAMETERS =================================
path = "c:\users\ephraim fuchs\desktop\";
audiofile1 = "testMusic1.mp3";
audiofile2 = "testMusic2.mp3";
audiofileRec = "testAnalogRec.wma";
audiofileDemod1 = "testAnalogRecDemod1.wav";
audiofileDemod2 = "testAnalogRecDemod2.wav";
bandWidth = 5000;
carrierFreq1 = 5000;
carrierFreq2 = 11000;
%% ====================== OBJECT GENERATION ===============================
sco = Scope();
dso1 = Source(Sourcetype.Audiofile, path + audiofile1);
dso2 = Source(Sourcetype.Audiofile, path + audiofile2);
lpf1 = RaisedCosineFilter(1, 1024, 0.1, 50); % fs=1, sps=50 is arbitrary and specified later
lpf2 = RaisedCosineFilter(1, 1024, 0.1, 50); % fs=1, sps=50 is arbitrary and specified later
mix1 = Mixer(Mixertype.Cosine, carrierFreq1);
mix2 = Mixer(Mixertype.Cosine, carrierFreq2);
dsi1 = Sink();
dsi2 = Sink();
dsi3 = Sink();
%% SIGNAL GENERATION
audiosignal1 = dso1.step;
audiosignal2 = dso2.step;

% figure; sco.yAxis = 'abs'; sco.plotFrequencyDomain(audiosignal1);
% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(audiosignal1);
%% LOW PASS FILTER
lpf1.fs = audiosignal1.fs;
lpf2.fs = audiosignal2.fs;
lpf1.cutoffFreq = bandWidth / 2;
lpf2.cutoffFreq = bandWidth / 2;
bandlimitedsignal1 = lpf1.step(audiosignal1);
bandlimitedsignal2 = lpf2.step(audiosignal2);

% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(bandlimitedsignal1);
%% UP-MIXING
mixedsig1 = mix1.step(bandlimitedsignal1);
mixedsig2 = mix2.step(bandlimitedsignal2);

% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(real(mixedsig1));
% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(real(mixedsig2));
%% ADDITION
outputsig = mixedsig1 + mixedsig2;

% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(real(outputsig));
%% AUDIO OUTPUT
player = dsi1.playAudio(outputsig);

player.pause;

dsi1.saveToAudioFile(outputsig, path + "testAnalogOutput.wav");
%% AUDIO INPUT
dso3 = Source(Sourcetype.Audiofile, path + audiofileRec);
recorded = dso3.step;

% Samplerate offset correction, manually:
recorded.fs = 44101;

% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(recorded);
%% OPTIONAL: BYPASS
recorded = real(outputsig);

%% MIXING
mixedrecsignal1 = mix1.step(recorded);
mixedrecsignal2 = mix2.step(recorded);

% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(mixedrecsignal1);
%% LOW PASS FILTERING
lpf1.cutoffFreq = bandWidth / 2;
lpf2.cutoffFreq = bandWidth / 2;
demodrecsignal1 = lpf1.step(mixedrecsignal1);
demodrecsignal2 = lpf2.step(mixedrecsignal2);

% figure;sco.yAxis = 'db'; sco.plotFrequencyDomain(lpf1);

% figure; sco.yAxis = 'real'; sco.plotTimeDomain(demodrecsignal1);
% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(demodrecsignal1, bandWidth * 1.2);
%% DC REMOVAL
demodrecsignal1 = demodrecsignal1.removeDCOffset;
%% AUDIO OUTPUT
player1 = dsi2.playAudio(demodrecsignal1);
player2 = dsi3.playAudio(demodrecsignal2);

player1.pause;
player2.pause;

dsi2.saveToAudioFile(demodrecsignal1, path + audiofileDemod1);
dsi3.saveToAudioFile(demodrecsignal2, path + audiofileDemod2);
% test script for multiple analog signal transmission
%% =========================== PARAMETERS =================================
path = "c:\users\ephraim fuchs\desktop\";
audiofile1 = "testMusic1.mp3";
audiofile2 = "testMusic2.mp3";
audiofile3 = "testMusic3.mp3";
audiofileRec = "testAnalogRec.wma";
bandWidth = 4000;
carrierFreq1 = 4000;
carrierFreq2 = 8000;
carrierFreq3 = 12000;
%% ====================== OBJECT GENERATION ===============================
sco = Scope();
dso1 = Source(Sourcetype.Audiofile, path + audiofile1);
dso2 = Source(Sourcetype.Audiofile, path + audiofile2);
dso3 = Source(Sourcetype.Audiofile, path + audiofile3);
lpf1 = RaisedCosineFilter(1, 1024, 0.1, 50); % fs=1, sps=50 is arbitrary and specified later
lpf2 = RaisedCosineFilter(1, 1024, 0.1, 50); % fs=1, sps=50 is arbitrary and specified later
lpf3 = RaisedCosineFilter(1, 1024, 0.1, 50); % fs=1, sps=50 is arbitrary and specified later
mix1 = Mixer(Mixertype.Cosine, carrierFreq1);
mix2 = Mixer(Mixertype.Cosine, carrierFreq2);
mix3 = Mixer(Mixertype.Cosine, carrierFreq3);
dsi0 = Sink();
dsi1 = Sink();
dsi2 = Sink();
dsi3 = Sink();
%% SIGNAL GENERATION
audiosignal1 = dso1.step;
audiosignal2 = dso2.step;
audiosignal3 = dso3.step;

% figure; sco.yAxis = 'abs'; sco.plotFrequencyDomain(audiosignal1);
% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(audiosignal1);
%% LOW PASS FILTER
lpf1.fs = audiosignal1.fs;
lpf2.fs = audiosignal2.fs;
lpf3.fs = audiosignal3.fs;
lpf1.cutoffFreq = bandWidth / 2;
lpf2.cutoffFreq = bandWidth / 2;
lpf3.cutoffFreq = bandWidth / 2;
bandlimitedsignal1 = lpf1.step(audiosignal1);
bandlimitedsignal2 = lpf2.step(audiosignal2);
bandlimitedsignal3 = lpf3.step(audiosignal3);

% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(bandlimitedsignal1);
%% UP-MIXING
mixedsig1 = mix1.step(bandlimitedsignal1);
mixedsig2 = mix2.step(bandlimitedsignal2);
mixedsig3 = mix3.step(bandlimitedsignal3);

% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(real(mixedsig1));
% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(real(mixedsig2));
%% ADDITION
outputsig = mixedsig1 + mixedsig2 + mixedsig3;

% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(real(outputsig));
%% AUDIO OUTPUT
player = dsi0.playAudio(outputsig);

player.pause;

dsi0.saveToAudioFile(outputsig, path + "testAnalogOutput.wav");
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
mixedrecsignal3 = mix3.step(recorded);

% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(mixedrecsignal1);
%% LOW PASS FILTERING
% Samplerate offset correction
lpf1.fs = recorded.fs;
lpf2.fs = recorded.fs;
lpf3.fs = recorded.fs;

lpf1.cutoffFreq = bandWidth / 2;
lpf2.cutoffFreq = bandWidth / 2;
lpf3.cutoffFreq = bandWidth / 2;
demodrecsignal1 = lpf1.step(mixedrecsignal1);
demodrecsignal2 = lpf2.step(mixedrecsignal2);
demodrecsignal3 = lpf3.step(mixedrecsignal3);

% figure;sco.yAxis = 'db'; sco.plotFrequencyDomain(lpf1);

% figure; sco.yAxis = 'real'; sco.plotTimeDomain(demodrecsignal1);
% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(demodrecsignal1, bandWidth * 1.2);
%% AUDIO OUTPUT
player1 = dsi1.playAudio(demodrecsignal1);
player2 = dsi2.playAudio(demodrecsignal2);
player3 = dsi3.playAudio(demodrecsignal3);

player1.pause;
player2.pause;
player3.pause;
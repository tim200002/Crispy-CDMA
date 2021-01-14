% test script for single side band amplitude modulation of 3 analog signals
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
ssbmod1 = SSBModulator(carrierFreq1, 'LSB');
ssbmod2 = SSBModulator(carrierFreq2, 'LSB');
ssbmod3 = SSBModulator(carrierFreq3, 'LSB');
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
%% LOW PASS FILTER; BAND LIMITATION
lpf = Filter.generateLowPass(audiosignal1.fs, 0.9 * bandWidth / 2, bandWidth / 2);
bandlimitedsignal1 = lpf.step(audiosignal1);
bandlimitedsignal2 = lpf.step(audiosignal2);
bandlimitedsignal3 = lpf.step(audiosignal3);

% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(bandlimitedsignal1);
%% SSB MODULATION
modulated1 = ssbmod1.step(bandlimitedsignal1);
modulated2 = ssbmod2.step(bandlimitedsignal2);
modulated3 = ssbmod3.step(bandlimitedsignal3);

% figure; sco.yAxis = 'abs'; sco.plotFrequencyDomain(modulated1);
% figure; sco.yAxis = 'abs'; sco.plotFrequencyDomain(modulated3);
%% ADDITION
outputsig = modulated1 + modulated2 + modulated3;

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

%% SSB DEMODULATION
ssbdemod1 = SSBDemodulator(carrierFreq1, 'LSB', recorded.fs, bandWidth / 2);
ssbdemod2 = SSBDemodulator(carrierFreq2, 'LSB', recorded.fs, bandWidth / 2);
ssbdemod3 = SSBDemodulator(carrierFreq3, 'LSB', recorded.fs, bandWidth / 2);
demodulated1 = ssbdemod1.step(recorded);
demodulated2 = ssbdemod2.step(recorded);
demodulated3 = ssbdemod3.step(recorded);

% figure; sco.yAxis = 'abs'; sco.plotFrequencyDomain(real(demodulated1));
%% AUDIO OUTPUT
player1 = dsi1.playAudio(demodulated1);
player2 = dsi2.playAudio(demodulated2);
player3 = dsi3.playAudio(demodulated3);

player1.pause;
player2.pause;
player3.pause;
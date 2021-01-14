% test script for single side band amplitude modulation of 3 analog signals
%% =========================== PARAMETERS =================================
path = "c:\users\ephraim fuchs\desktop\";
audiofile1 = "testMusic1.mp3";
audiofile2 = "testMusic2.mp3";
audiofile3 = "testMusic3.mp3";
audiofile4 = "testMusic4.mp3";
audiofile5 = "testMusic5.mp3";
audiofileOut = "testAnalog5Ch.wav";
audiofileRec = "testAnalogRec.wma";
bandWidth = 4000;
carrierFreq1 = 4000;
carrierFreq2 = 4000;
carrierFreq3 = 8000;
carrierFreq4 = 16000;
carrierFreq5 = 16000;
%% ====================== OBJECT GENERATION ===============================
sco = Scope();
dso1 = Source(Sourcetype.Audiofile, path + audiofile1);
dso2 = Source(Sourcetype.Audiofile, path + audiofile2);
dso3 = Source(Sourcetype.Audiofile, path + audiofile3);
dso4 = Source(Sourcetype.Audiofile, path + audiofile4);
dso5 = Source(Sourcetype.Audiofile, path + audiofile5);
mod1 = SSBModulator(carrierFreq1, 'LSB');
mod2 = SSBModulator(carrierFreq2, 'USB');
mod3 = DSBModulator(carrierFreq3);
mod4 = SSBModulator(carrierFreq4, 'LSB');
mod5 = SSBModulator(carrierFreq5, 'USB');
dsi0 = Sink();
dsi1 = Sink();
dsi2 = Sink();
dsi3 = Sink();
dsi4 = Sink();
dsi5 = Sink();
%% SIGNAL GENERATION
audiosignal1 = dso1.step;
audiosignal2 = dso2.step;
audiosignal3 = dso3.step;
audiosignal4 = dso4.step;
audiosignal5 = dso5.step;

% figure; sco.yAxis = 'abs'; sco.plotFrequencyDomain(audiosignal1);
% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(audiosignal1);
%% LOW PASS FILTER; BAND LIMITATION
lpf = Filter.generateLowPass(audiosignal1.fs, 0.9 * bandWidth / 2, bandWidth / 2);
bandlimitedsignal1 = lpf.step(audiosignal1);
bandlimitedsignal2 = lpf.step(audiosignal2);
bandlimitedsignal3 = lpf.step(audiosignal3);
bandlimitedsignal4 = lpf.step(audiosignal4);
bandlimitedsignal5 = lpf.step(audiosignal5);

% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(bandlimitedsignal1);
%% NORMALIZATION
normedsignal1 = bandlimitedsignal1.normByMax;
normedsignal2 = bandlimitedsignal2.normByMax;
normedsignal3 = bandlimitedsignal3.normByMax;
normedsignal4 = bandlimitedsignal4.normByMax;
normedsignal5 = bandlimitedsignal5.normByMax;

% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(normedsignal1);
% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(normedsignal2);
%% MODULATION
modulated1 = mod1.step(normedsignal1);
modulated2 = mod2.step(normedsignal2);
modulated3 = mod3.step(normedsignal3);
modulated4 = mod4.step(normedsignal4);
modulated5 = mod5.step(normedsignal5);

% figure; sco.yAxis = 'abs'; sco.plotFrequencyDomain(modulated1);
% figure; sco.yAxis = 'abs'; sco.plotFrequencyDomain(modulated3);
%% ADDITION
outputsig = modulated1 + modulated2 + modulated3 + modulated4 + modulated5;

% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(real(outputsig), [0, 48000/2]);
%% AUDIO OUTPUT
outputsig = outputsig.normByMax;

player = dsi0.playAudio(outputsig);

player.pause;

dsi0.saveToAudioFile(path + audiofileOut, outputsig);
%% AUDIO INPUT
dso3 = Source(Sourcetype.Audiofile, path + audiofileRec);
recorded = dso3.step;

% Samplerate offset correction, manually:
recorded.fs = 44101;

% figure; sco.yAxis = 'db'; sco.plotFrequencyDomain(recorded);
%% OPTIONAL: BYPASS
recorded = real(outputsig);

%% DEMODULATION
demod1 = SSBDemodulator(carrierFreq1, 'LSB', recorded.fs, bandWidth / 2);
demod2 = SSBDemodulator(carrierFreq2, 'USB', recorded.fs, bandWidth / 2);
demod3 = DSBDemodulator(carrierFreq3, recorded.fs, bandWidth / 2);
demod4 = SSBDemodulator(carrierFreq4, 'LSB', recorded.fs, bandWidth / 2);
demod5 = SSBDemodulator(carrierFreq5, 'USB', recorded.fs, bandWidth / 2);
demodulated1 = demod1.step(recorded);
demodulated2 = demod2.step(recorded);
demodulated3 = demod3.step(recorded);
demodulated4 = demod4.step(recorded);
demodulated5 = demod5.step(recorded);

% figure; sco.yAxis = 'abs'; sco.plotFrequencyDomain(real(demodulated1));
%% AUDIO OUTPUT
player1 = dsi1.playAudio(demodulated1);
player2 = dsi2.playAudio(demodulated2);
player3 = dsi3.playAudio(demodulated3);
player4 = dsi4.playAudio(demodulated4);
player5 = dsi5.playAudio(demodulated5);

player1.pause;
player2.pause;
player3.pause;
player4.pause;
player5.pause;
clear

codeLength =2;
cdmaEncoder = CDMAEncoder(codeLength);
signal_length = 1000;
testSignal1 = Signal( round(0.75*rand(1,signal_length)),1e3); %Wie muss die Abtastfrequenz gesetzt werden
disp('Original')
testSignal1.data(1:10)

cdmaSignal1 = cdmaEncoder.step(testSignal1,2);


testSignal2 = Signal( round(0.75*rand(1,signal_length)),1e3);
cdmaSignal2 = cdmaEncoder.step(testSignal2,1);



addedSignal =cdmaSignal1+cdmaSignal2;

pamMapper = PAMMapper(codeLength);
afterMapper = pamMapper.step(addedSignal);

%Pulse shaped
pulseShaper = Pulseshaper(Impulsetype.RaisedCosine, 16);
afterPulseShaper = pulseShaper.step(afterMapper);




%Modulate Signal
scope = Scope();
fc = 13e3;
mixer = Mixer(Mixertype.Cosine, fc);
afterMixer = mixer.step(afterPulseShaper);

%Insert Pilot
pilotInserter = PilotInserter(fc);
pilotedSignal = pilotInserter.step(afterMixer);





%Search for pilot
synchronizer = Synchronizer(fc);
pilotIndex = synchronizer.step(pilotedSignal);



removedPilot = Signal(pilotedSignal.data(pilotIndex:end), pilotedSignal.fs);

%Demodulate Signal
afterDemodulation = mixer.step(removedPilot);
%Filter Signal
load('untitled.mat');
filter = Filter(32e3, Num);
afterFilt = filter.step(afterDemodulation);
figure(1)
plot(afterFilt.data(1:1000)*2)
figure(2)
plot(afterPulseShaper.data(1:1000))

%Read Bits
bitIndex = [1: 16: afterFilt.length];
unformed = Signal(afterFilt.data(bitIndex)*2, afterDemodulation.fs/16);






% figure(2)
% plot(afterDemodulation.data(1:1000));





pamDemapper = PAMDemapper(codeLength);
demappedSignal = pamDemapper.step(unformed);

cdmaDecoder = CDMADecoder(codeLength);
resSignal = cdmaDecoder.step(demappedSignal,2);
disp('Result')
resSignal.data(1:10)

clear all
codeLength =4;

serializer = ImageSerializer('TestImages\tvTestScreen32x32.jpg');
bitStream=serializer.GenerateRGBBitStream();
cdmaEncoder = CDMAEncoder(codeLength);
signal_length = 1000;
bitSignal1=Signal(double(bitStream(1,:)),1e3);
bitSignal2=Signal(double(bitStream(2,:)),1e3);
bitSignal3=Signal(double(bitStream(3,:)),1e3);


cdmaSignal1 = cdmaEncoder.step(bitSignal1,1);
cdmaSignal2 = cdmaEncoder.step(bitSignal2,2);
cdmaSignal3 = cdmaEncoder.step(bitSignal3,3);


addedSignal =cdmaSignal1+cdmaSignal2+cdmaSignal3;

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
% figure(1)
% plot(afterFilt.data(1:1000)*2)
% figure(2)
% plot(afterPulseShaper.data(1:1000))

%Read Bits
bitIndex = [1: 16: afterFilt.length];
unformed = Signal(afterFilt.data(bitIndex)*2, afterDemodulation.fs/16);






% figure(2)
% plot(afterDemodulation.data(1:1000));





pamDemapper = PAMDemapper(codeLength);
demappedSignal = pamDemapper.step(unformed);

cdmaDecoder = CDMADecoder(codeLength);
res1 = cdmaDecoder.step(demappedSignal,1);
res2 = cdmaDecoder.step(demappedSignal,2);
res3 = cdmaDecoder.step(demappedSignal,3);

bistream(1,:)=res1.data';
bistream(2,:)=res2.data';
bistream(3,:)=res3.data';

deserializer = ImageDeserializer();
img=deserializer.GetImageFromBitVector(bitStream);
clear all
profile on
codeLength =4;
headerLength = 16;
fc = 13e3;


delay = 10;



%Must result in fs = 48e3
samplesPerSymbol=15;
symbolRate = 0.8e3;

audioDeviceId=6;


amplitudeScope = Scope(ScopeYAxis.Magnitude);
dbScope = Scope(ScopeYAxis.dB);
scope = Scope();

done = false;

 %% Serialize Image
serializer = AdvancedImageSerializer('TestImages/tvTestScreen32x32.jpg', 4);

while 1
tic;
disp('new one')



[signal, done]=serializer.getNextSignal();
if done
    break;
end
cdmaEncoder = CDMAEncoder(codeLength);
signal_length = 1000;
bitSignal1=Signal(double(signal(1,:)),symbolRate);
bitSignal2=Signal(double(signal(2,:)),symbolRate);
bitSignal3=Signal(double(signal(3,:)),symbolRate);

%% CDMA Encode Signal
cdmaSignal1 = cdmaEncoder.step(bitSignal1,1);
cdmaSignal2 = cdmaEncoder.step(bitSignal2,2);
cdmaSignal3 = cdmaEncoder.step(bitSignal3,3);


addedSignal =cdmaSignal1+cdmaSignal2+cdmaSignal3;

pamMapper = PAMMapper(codeLength);
afterMapper = pamMapper.step(addedSignal);

%% Add Header
header = Header(headerLength);

headerSignal = header.addHeader(afterMapper);

%% Modulation
 pilotInserter = PilotInserter(fc);
 mixer = Mixer(Mixertype.Cosine, fc);
 pulseShaper = Pulseshaper(Impulsetype.RaisedCosine, samplesPerSymbol);
 
 pulseShapedSignal = pulseShaper.step(headerSignal);
 mixedSignal = mixer.step(pulseShapedSignal);
 pilotedSignal = pilotInserter.step(mixedSignal);
 modulatedSignal = Signal(pilotedSignal.data, pilotedSignal.fs);

 %% Transmit Signal
 sink = Sink(audioDeviceId, 48e3, '16-bit integer');
 sink.step(modulatedSignal);
 
 while toc<delay 

    pause(0.001);
 end
end
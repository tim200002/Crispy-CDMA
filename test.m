clear all
codeLength =4;
 fc = 13e3;
 samplesPerSymbol=16;

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


modulator = Modulator(fc,samplesPerSymbol);
modulatedSignal = modulator.step(afterMapper);



demodulator = Demodulator(fc, samplesPerSymbol);
demodulatedSignal = demodulator.step(modulatedSignal);



pamDemapper = PAMDemapper(codeLength);
demappedSignal = pamDemapper.step(demodulatedSignal);

cdmaDecoder = CDMADecoder(codeLength);
res1 = cdmaDecoder.step(demappedSignal,1);
res2 = cdmaDecoder.step(demappedSignal,2);
res3 = cdmaDecoder.step(demappedSignal,3);

bistream(1,:)=res1.data';
bistream(2,:)=res2.data';
bistream(3,:)=res3.data';

deserializer = ImageDeserializer();
img=deserializer.GetImageFromBitVector(bitStream);
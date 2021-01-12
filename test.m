codeLength =16;
cdmaEncoder = CDMAEncoder(codeLength);
testSignal1 = Signal([1,0,1,1,0,0,0,0],10);
cdmaSignal1 = cdmaEncoder.step(testSignal1,2);

testSignal2 = Signal([0,0,1,1,0,0,0,0],10);
cdmaSignal2 = cdmaEncoder.step(testSignal2,1);

testSignal3 = Signal([0,0,1,1,1,0,1,0],10);
cdmaSignal3 = cdmaEncoder.step(testSignal3,5);


addedSignal =cdmaSignal1+cdmaSignal2+cdmaSignal3;



pamMapper = PAMMapper(codeLength);
channelSignal = pamMapper.step(addedSignal);

ch = Channel('AWGN',10);
afterChannel=ch.step(channelSignal)

pamDemapper = PAMDemapper(codeLength);
demappedSignal = pamDemapper.step(afterChannel);

cdmaDecoder = CDMADecoder(codeLength);
cdmaDecoder.step(demappedSignal,2)

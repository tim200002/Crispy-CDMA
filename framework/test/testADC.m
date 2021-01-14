bitdepth = 8;
sampleRate= 96000;
symm = 0;
mu = 7;
path = "c:\users\ephraim fuchs\desktop\";
so = Source(Sourcetype.Audiofile, path+"testAnalog1.mp3");
si = Sink();
sig1 = so.step();
sig2 = sig1.normByMax;


adc = ADConverter(sampleRate,bitdepth, symm, mu);
sig3 = adc.step(sig2);
if bitdepth > 8
    toWrite = int16(sig3.divideInBitBlocks(bitdepth, 'int', 1)) - 2^(bitdepth-1) + 1;
else
    toWrite = sig3.data;
end
audiowrite(char(path+"testADC.wav"), toWrite, sig3.fs / bitdepth);

dac = DAConverter(sampleRate, bitdepth, symm, mu);
sig4 = dac.step(sig3);
audiowrite(char(path+"testDAC.wav"), sig4.data, sig4.fs);
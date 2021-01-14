so = Source(Sourcetype.Audiodevice);
si = Sink(1, 48000, '16-bit integer');

so.releaseDevice;
si.releaseDevice;

while(1)
    sig = so.step();
    si.step(sig);
end
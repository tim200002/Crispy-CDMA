sampleRate = 96000;
syncLength = 8; % in s
tests= 50;

signal2 = aud;
signal2 = signal2 - mean(signal2);
signal2 = signal2 / max(signal2);

sig = Signal(ones(sampleRate*syncLength, 1), sampleRate, 'v');


for md = 1:tests
    disp(md);
    freq = sampleRate / syncLength + (md - 1 - tests/2) / tests;
    mix = Mixer('Sine', freq);
    sinsig = mix.step(sig);
    signal1 = sinsig.data;
    signal1 = signal1 - mean(signal1);
    signal1 = signal1 / max(signal1);
    correl  = xcorr(signal1, signal2);
    %figure; plot(real(correl))
    [maxval, maxindx] = max(correl);
    res(md, 1) = freq;
    res(md, 2) = maxval;
    res(md, 3) = maxindx;
    
end

figure;plot(res(:, 1)/1000, res(:, 2))

[~,bestmd ] = max(res(:, 2));
bestfreq = res(bestmd, 1);
num2str(bestfreq) % no e+04 output

(sampleRate / syncLength - bestfreq) * syncLength
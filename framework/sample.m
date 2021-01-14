function sampledsignal = sample(signal, sampleRate, offset)
% SAMPLE downsamples the Signal object to a Signal object with smaller sampleRate
% 0 <= offset < 1 determines, how many of the first samples shall be ignored 

    ratio = floor(signal.fs / sampleRate);
    selectedIndices = 1 + round(offset * ratio) : ratio : signal.length;
    selection = signal.data(selectedIndices);
    sampledsignal = Signal(selection, sampleRate, signal.signaltype, signal.details);
end
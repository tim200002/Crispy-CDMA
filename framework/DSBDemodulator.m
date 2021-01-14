classdef DSBDemodulator < handle
% DSBDEMODULATOR can demodulate double side band amplitude 
% modulated signals.
% It is a coherent demodulator, so be aware of correct phase.

    properties
        mix Mixer
        lpf Filter
    end
    
    methods
        function obj = DSBDemodulator(carrierFreq, sampleRate, cutoffFreq)
            obj.mix = Mixer(Mixertype.Cosine, carrierFreq, true);
            obj.lpf = Filter.generateLowPass(sampleRate, cutoffFreq, 1.1 * cutoffFreq); % 1.1 hard coded value
            obj.lpf.setPersistentMemory(true);
        end
        
        function signalout = step(obj, signalin)
        % STEP performs the DSB amplitude demodulation of the Signal object
        % "signalin" and outputs it as Signal object "signalout".      
            signalout = obj.mix.step(signalin);
            signalout = obj.lpf.step(signalout);
        end
    end
end
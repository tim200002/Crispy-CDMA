classdef SSBDemodulator < handle
% SSBDEMODULATOR can demodulate single side band amplitude 
% modulated signals.

    properties
        mix Mixer
        hil HilbertFilter
        lpf Filter
        sidebandfactor
    end
    methods
        function obj = SSBDemodulator(carrierFreq, sideband, sampleRate, cutoffFreq)
            obj.mix = Mixer(Mixertype.ComplexConjugate, carrierFreq, true);
            obj.hil = HilbertFilter;
            obj.lpf = Filter.generateLowPass(sampleRate, cutoffFreq, 1.1 * cutoffFreq); % 1.1 hard coded value
            obj.lpf.setPersistentMemory(true);
            obj.chooseSideband(sideband);
        end
        
        function signalout = step(obj, signalin)
        % STEP performs the SSB amplitude demodulation of the Signal object
        % "signalin" and outputs it as Signal object "signalout".
            if signalin.signaltype ~= Signaltype.Valuecontinuous
                error("SSBDemodulator.step: signal not valuecontinuous");
            end
            mixedsig = obj.mix.step(signalin);
            hilbertFiltered = obj.hil.step(mixedsig.imag);
            signalout = mixedsig.real + obj.sidebandfactor * hilbertFiltered;
            signalout = obj.lpf.step(signalout);
        end
        
        function chooseSideband(obj, sideband)
        % CHOOSESIDEBAND sets the sideband which shall be demodulated.
        % 'LSB' or 'USB'
            if strcmpi(sideband, 'LSB') % choose this to demodulate a signal, which has been SSB modulated using the LSB
                obj.sidebandfactor = 1;
            elseif strcmpi(sideband, 'USB')% choose this to demodulate a signal, which has been SSB modulated using the USB
                obj.sidebandfactor = -1;
            else
                error("SSBDemodulator.chooseSideband: choose either 'LSB' or 'USB' as sideband");
            end
        end
    end
end
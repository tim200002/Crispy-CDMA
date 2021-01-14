classdef SSBModulator < handle
% SSBMODULATOR can modulate single side band amplitude modulated signals.

    properties
        mix Mixer
        hil HilbertFilter
        sidebandfactor
    end
    methods
        function obj = SSBModulator(carrierFreq, sideband)
            obj.mix = Mixer(Mixertype.Complex, carrierFreq, true);
            obj.hil = HilbertFilter;
            obj.chooseSideband(sideband);
        end
        
        function signalout = step(obj, signalin)
        % STEP calculates and returns the SSB modulated signal.
        % Note: only real part of signalin is processed.
            if signalin.signaltype ~= Signaltype.Valuecontinuous
                error("SSBModulator.step: signal not valuecontinuous");
            end
            hilbertFiltered = obj.hil.step(signalin.real);
            analyticSignal = signalin.real + obj.sidebandfactor * 1j * hilbertFiltered;
            signalout = obj.mix.step(analyticSignal).real;
        end
        
        function chooseSideband(obj, sideband)
        % CHOOSESIDEBAND sets the sideband which shall be used.
        % 'LSB' or 'USB'
            if strcmpi(sideband, 'LSB') % lower side band
                obj.sidebandfactor = -1;
            elseif strcmpi(sideband, 'USB') % upper side band
                obj.sidebandfactor = 1;
            else
                error("SSBModulator.chooseSideband: choose either 'LSB' or 'USB' as sideband");
            end
        end
    end
end
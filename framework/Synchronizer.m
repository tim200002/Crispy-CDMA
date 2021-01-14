classdef Synchronizer < handle
% SYNCHRONIZER is module to find pilot sequences in signals and
% synchronize to that pilots accordingly

    properties
        pilotSequence Signal                % pilot sequence to search for, no binary signal, but symbol signal
        threshold = 10                      % optional; factor, which the covariance should exceed the average covariance
        fc = 8e3                            % carrier frequency of pilot
        PilotMixer Mixer                    % Mixer for Pilot
        PilotBandwidth = 2e3
        PilotFilter RootRaisedCosineFilter
        PilotPulseshaper Pulseshaper
    end
    
    methods
        function obj = Synchronizer(fc,pilotSequence)
            if nargin >1
                obj.pilotSequence = pilotSequence;
            else
                obj.pilotSequence = Signal(genZadoffChuSequence,obj.PilotBandwidth);
            end
            obj.PilotMixer = Mixer(Mixertype.ComplexConjugate,fc);
        end
        
        function [startIndex, significant] = step(obj, signal)
        % STEP returns index (startIndex) in the signal data, where the
        % pilot sequence begins and whether it is a significant result
        
            SamplesPerSymbol = round(signal.fs./obj.PilotBandwidth);
            obj.PilotFilter = RootRaisedCosineFilter(signal.fs, 10*SamplesPerSymbol, 0.1, SamplesPerSymbol);
            obj.PilotPulseshaper = Pulseshaper(Impulsetype.RaisedCosine,SamplesPerSymbol);
            
            SignalBaseBand = obj.PilotMixer.step(signal);
            SignalFiltered = obj.PilotFilter.step(SignalBaseBand);
            
            PilotPulseshaped = obj.PilotPulseshaper.step(obj.pilotSequence);

            [correl,lags] = xcorr(SignalFiltered.data,PilotPulseshaped.data);
            % figure(2);plot(lags,abs(correl))
            [maxvalue, maxindx] = max(abs(correl));                
            startIndex = lags(maxindx) + PilotPulseshaped.length + 1;
            if maxvalue >= obj.threshold * mean(abs(correl)) % if the maximum value of the covariance exceeds the average by a factor
                significant = true;
            else
                significant = false;
            end            
        end
    end
end
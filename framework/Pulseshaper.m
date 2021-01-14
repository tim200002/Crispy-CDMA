classdef Pulseshaper < handle
% PULSESHAPER is a class to perform pulseshaping on Signal objects

    properties
        impulsetype Impulsetype             % element of enumeration Impulsetype
        fil Filter                          % instance of class Filter
        sam Sampler                         % instance of class Sampler
        samplesPerSymbol {mustBePositive}   % equals the number of samples (regarding fs) within a symbol period time
    end
    
    properties (Constant) % default values for (root) raised cosine filter generation
        raisedCosineFilterLength = 10       % (optional) filter length (not in samples, in multiples of samplesPerSymbol!) for (root) raised cosine pulse shaping
        raisedCosineRolloff = 0.1           % (optional) rolloff factor for (root) raised cosine pulse shaping
    end
    
    methods
        function obj = Pulseshaper(impulseType, samplesPerSymbol, varargin)
        % arguments:
        % (1) impulseType: element of enumeration Impulsetype, e.g.
        % 'Rectangular'
        % (2) samplesPerSymbol: number of samples between two symbols
        % (3) (optional) Filter object for customized pulse shaping
        % filter
        
            obj.impulsetype = impulseType;
            obj.samplesPerSymbol = round(samplesPerSymbol); % must be integer
            obj.sam = Sampler(obj.samplesPerSymbol, 1);
            if nargin == 3
                obj.fil = varargin{1}; % use given filter
            else
                obj.generateFilter();
            end
        end
        
        function shaped = step(obj, signal)
        % STEP applies pulseshaping to Signal object "signal"
            
            obj.fil.fs = signal.fs * obj.samplesPerSymbol; % adapt filter sample rate to new sample rate; not really neccessary
            upsampledSignal = obj.sam.upsampleZeroPadding(signal);
            shaped = obj.fil.step(upsampledSignal);
            shaped = shaped.selectFromTo(1, shaped.length - obj.samplesPerSymbol + 1); % remove last obj.samplesPerSymbol - 1 samples
        end
        
        function shaped = stepAndPlot(obj, signal, varargin)
        % STEPANDPLOT performs pulseshaping and visualizes the result.
        % (3) (optional): how many symbols and their impulses shall be
        % plotted
        % Only real part is plotted.
        % ATTENTION: this might be slow; consider plotting not all
        % symbols
            
            if nargin == 2
                numberOfSymbols = signal.length; % default: plot all symbols
            elseif nargin == 3
                numberOfSymbols = min(signal.length, varargin{1});
            end
            
            shaped = obj.step(signal);
            
            plot([zeros(round(obj.fil.length / 2), 1); real(shaped.data)], 'blue', 'LineWidth', 2);
            hold on;
            
            for actualSymbol = 1:numberOfSymbols
                XValues = ((actualSymbol - 1)  * obj.samplesPerSymbol : (actualSymbol - 1)  * obj.samplesPerSymbol + obj.fil.length - 1) + 1;
                plot(XValues, real(signal.data(actualSymbol)) * obj.fil.data);
            end
            
            plot([zeros(round(obj.fil.length / 2), 1); real(shaped.data)], 'blue', 'LineWidth', 2);
            xlabel('Time [samples]')
            ylabel('Amplitude')
            title("Pulseshaping Visualization with " + string(obj.impulsetype) + " Impulses");
            legend("resulting signal (real)");
        end
    end
    
    methods (Access = private)
        % private method
        function generateFilter(obj)
            fs = 1;
            switch obj.impulsetype
                case Impulsetype.RaisedCosine % only generates filters with default values (constants) for filterLength and Rolloff
                    obj.fil = RaisedCosineFilter(fs, obj.raisedCosineFilterLength * obj.samplesPerSymbol, obj.raisedCosineRolloff, obj.samplesPerSymbol);
                case Impulsetype.RootRaisedCosine % only generates filters with default values (constants) for filterLength and Rolloff
                    obj.fil = RootRaisedCosineFilter(fs, obj.raisedCosineFilterLength * obj.samplesPerSymbol, obj.raisedCosineRolloff, obj.samplesPerSymbol);
%                   obj.fil = Filter(rcosdesign(obj.raisedCosineRolloff,obj.raisedCosineFilterLength,obj.samplesPerSymbol,'sqrt'), fs);
                case Impulsetype.Rectangular
                    obj.fil = Filter(fs, ones(obj.samplesPerSymbol, 1));
                case Impulsetype.Triangular
                    obj.fil = Filter(fs, [0:obj.samplesPerSymbol (obj.samplesPerSymbol-1):-1:1]);
            end
        end
    end
end
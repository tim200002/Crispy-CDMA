classdef Channel
% CHANNEL is a class to model a communication channel.
% Currently only an AWGN channel supported.
    
    properties
        type % 'awgn'
        params % struct; parameters for channel given in type
                % for type == 'awgn':
                    % params.snr: signal to noise ratio in dB
    end
    methods
        function obj = Channel(channelType, SNR)
            obj.type = lower(channelType);
            obj.params.snr = SNR;
        end
        
        function noisySignal = step(obj, signal)
        % STEP applies the channel to Signal object "signal" and outputs it
        % as Signal object "noisySignal"
        
            if signal.signaltype == Signaltype.Valuecontinuous % do not operate on bitsignals / bytesignals
                SNRlinear = db2pow(obj.params.snr);
                switch(obj.type) % to have the ability to extent the channel's type
                    case 'awgn'
                        if signal.isReal
                            sigma = sqrt(signal.signalenergy / SNRlinear /2); %TODO: /2 here too?
                            noise = sigma * randn(length(signal.data), 1); % normally distributed random numbers
                            addednoise = signal.data + noise;
                        else
                            sigma = sqrt(signal.signalenergy / SNRlinear / 2); % / 2 because of complex noise
                            realnoise = sigma * randn(signal.length, 1);
                            imagnoise = 1j * sigma * randn(signal.length, 1); % normally distributed random numbers
                            addednoise = signal.data + realnoise + imagnoise;
                        end
                        noisySignal = Signal(addednoise, signal.fs, signal.signaltype, signal.details);
                end
            end
        end
    end
end
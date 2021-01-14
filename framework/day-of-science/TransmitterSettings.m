classdef TransmitterSettings < handle
    % combines all GUI inputs
    properties
        sampleRate
        samplesPerFrame
        nChannels % number of channels
        bandwidth % array
        carrierFrequencies % array, for each channel
        modulationsList = ["double side band"; "lower side band"; "upper side band"];
        modulationIndices  % indices of selected modulations in modulationsList for each channel
        outputDevicesList  % string array of all available output devices shown in pop up menu
        outputDeviceIndex  % index of selected device in outputDevicesList
        inputsList         % cell array (of strings) of all available input devices and files shown in pop up menu
        inputsIndices      % the chosen inputs (device or file) as indices in inputsList for each channel
    end
    
    properties (Constant) % default settings
        SAMPLERATE = 48000;
        SAMPLESPERFRAME = 16384;
        NCHANNELS = 4;
        BANDWIDTH = 4000;
    end
    
    methods
        function obj = TransmitterSettings(varargin)
            if nargin == 1
                nChannels = varargin{1};
            else
                nChannels = obj.NCHANNELS;
            end
            obj.sampleRate = obj.SAMPLERATE; % default
            obj.samplesPerFrame = obj.SAMPLESPERFRAME; % default
            obj.nChannels = nChannels;
            obj.bandwidth = obj.BANDWIDTH * ones(nChannels, 1); % default values
            obj.carrierFrequencies = (1 : nChannels) * ((20000 + obj.bandwidth(1))/ nChannels) - obj.bandwidth(1); % default values
            obj.modulationIndices = ones(nChannels, 1); % default values
            obj.outputDeviceIndex = 1; % default value
            obj.inputsIndices = ones(nChannels, 1); % default values
            obj.getOutputDevices();
            obj.getInputDevices();
        end
        
        function setNChannels(obj, nChannels)
            % fill with default values:
            obj.bandwidth(obj.nChannels + 1 : nChannels) = obj.BANDWIDTH;
            obj.carrierFrequencies(obj.nChannels + 1 : nChannels) = (obj.nChannels + 1 : nChannels) * ((20000 + obj.bandwidth(1))/ nChannels) - obj.bandwidth(1); % default values
            obj.modulationIndices(obj.nChannels + 1 : nChannels) = ones(nChannels - obj.nChannels, 1);
            obj.inputsIndices(obj.nChannels + 1 : nChannels) = ones(nChannels - obj.nChannels, 1);
            obj.nChannels = nChannels;
        end
        
        function stringArray = getOutputDevices(obj)
            deviceWriter = audioDeviceWriter(); % get System object
            stringArray = string(deviceWriter.getAudioDevices())';
            helper = stringArray(1);
            stringArray(1) = "No Output"; % append option 'no output' to list
            stringArray(end + 1) = helper;
            deviceWriter.release();
            obj.outputDevicesList = stringArray;
        end
        
        function stringCells = getInputDevices(obj)
            deviceReader = audioDeviceReader; % get System object
            stringCells = deviceReader.getAudioDevices()';
            stringCells = [{'No Input'}; stringCells]; % append option 'no input' to list
            stringCells = [stringCells; 'piano.mp3'; 'pop.mp3'; 'jazz.mp3'; 'acoustic.mp3'; 'male.wav'; 'female.wav']; % append option to transmit an audio file to list
            deviceReader.release();
            obj.inputsList = stringCells;
        end
        
        function configStringCells = getConfigurationAsStringCells(obj)
            if obj.nChannels == 0
                configStringCells = {""};
            else
                configStringArray = string((1:obj.nChannels)')+" | "+...
                                    string(obj.carrierFrequencies(1:obj.nChannels)')+" | "+...
                                    string(obj.bandwidth(1:obj.nChannels))+" | "+...
                                    obj.inputsList(obj.inputsIndices(1:obj.nChannels))+" | "+...
                                    obj.modulationsList(obj.modulationIndices(1:obj.nChannels));
                                
                configStringCells = num2cell(configStringArray);
            end
        end
        
    end
end
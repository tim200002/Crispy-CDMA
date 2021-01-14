classdef ReceiverSettings < handle
    % combines all GUI inputs
    properties
        sampleRate
        samplesPerFrame
        nChannels % number of channels
        bandwidth % array
        carrierFrequencies % array
        modulationsList = ["double side band"; "lower side band"; "upper side band"];
        modulationIndices % indices of selected modulations in modulationsList
        inputDevicesList % cell array of all available input devices shown in pop up menu
        inputDeviceIndex % index of selected device in inputDevicesList
        outputDevicesList % cell array of all available output devices shown in pop up menu
        outputDevicesIndices % indices of selected devices in outputDevicesList
        channelList = ["R"; "L"; "LR"];
        channelIndices % indices of selected channels in channelList % 1='R', 2='L', 3='LR'
    end
    
    properties (Constant) % default settings
        SAMPLERATE = 48000;
        SAMPLESPERFRAME = 16384;
        NCHANNELS = 4;
        BANDWIDTH = 4000;
    end
    
    methods
        
        function obj = ReceiverSettings(varargin)
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
            obj.inputDeviceIndex = 1; % default value
            obj.outputDevicesIndices = ones(nChannels, 1); % default values
            obj.channelIndices = ones(nChannels, 1); % default values
            obj.getOutputDevices();
            obj.getInputDevices();
        end
        
        function setNChannels(obj, nChannels)
            % fill - if necessary (nChannels > obj.nChannels) - with default values:
            obj.bandwidth(obj.nChannels + 1 : nChannels) = obj.BANDWIDTH;
            obj.carrierFrequencies(obj.nChannels + 1 : nChannels) = (obj.nChannels + 1 : nChannels) * ((20000 + obj.bandwidth(1))/ nChannels) - obj.bandwidth(1); % default values
            obj.modulationIndices(obj.nChannels + 1 : nChannels) = ones(nChannels - obj.nChannels, 1);
            obj.outputDevicesIndices(obj.nChannels + 1 : nChannels) = ones(nChannels - obj.nChannels, 1);
            obj.channelIndices(obj.nChannels + 1 : nChannels) = ones(nChannels - obj.nChannels, 1); % default values
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
        
        function stringArray = getInputDevices(obj)
            deviceReader = audioDeviceReader; % get System object
            stringArray = string(deviceReader.getAudioDevices())';
            helper = stringArray(1);
            stringArray(1) = "No Input"; % append option 'no input' to list
            stringArray(end + 1) = helper;
            deviceReader.release();
            obj.inputDevicesList = stringArray;
        end
        
        function configStringCells = getConfigurationAsStringCells(obj)
            if obj.nChannels == 0
                configStringCells = {""};
            else % MATLAB version has to be > 2016 for this:
                configStringArray = string((1:obj.nChannels)')+" | "+...
                                    string(obj.carrierFrequencies(1:obj.nChannels)')+" | "+...
                                    string(obj.bandwidth(1:obj.nChannels))+" | "+...
                                    obj.outputDevicesList(obj.outputDevicesIndices(1:obj.nChannels))+" | "+...
                                    obj.channelList(obj.channelIndices(1:obj.nChannels))+" | "+...
                                    obj.modulationsList(obj.modulationIndices(1:obj.nChannels));
                                
                configStringCells = num2cell(configStringArray);
            end
        end
        
    end
end
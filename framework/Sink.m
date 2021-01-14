classdef Sink < handle
% SINK can 
% - save data to a file
% - save audio to a file
% - output audio over an audio device
% - compare binary data to random numbers with the same seed, if binary data contain random numbers

    properties
        signalin(1, 1) Signal               % Signal object of accumulated data
        outputDevice                        % optional: system object of AudioDeviceWriter; requires Audio System Toolbox
        outputGaindB = 0;                   % optional: gain / attenuation of output signal for audio output
    end
    methods
        function obj = Sink(varargin)
        % arguments:
        % nothing
        % OR
        % (1) index of device in Sink.getAudioOutputDevices() array
        % (2) sample rate of audio device
        % (3) bit depth as string, e.g. '16-bit integer'
        % e.g. Sink(1, 48000, '16-bit integer')
            if nargin == 3 % if signals shall be output from an audio device
                obj.outputDevice = audioDeviceWriter(varargin{2}, 'BitDepth', varargin{3});
                devicesList = Sink.getAudioOutputDevices();
                obj.outputDevice.Device = devicesList(varargin{1});
                obj.outputDevice.SupportVariableSizeInput = true;
            end
        end
        
        function step(obj, signal)
        % STEP accumulates the given Signal object to the internally stored
        % obj.signalin
        % OR
        % if an audio device is set, outputs the given Signal object 
        % (recommended for block-wise audio output)
        % arguments:
        % (1) Sink object
        % (2) Signal object
        
            if isempty(obj.outputDevice) % no audio output; store signal in obj.signalin
                if signal.signaltype == Signaltype.Valuecontinuous || signal.signaltype == Signaltype.Bits || signal.signaltype == Signaltype.Bytes
                    obj.signalin = [obj.signalin; signal]; % concat function of Signal objects
                else
                    warning("Sink.step: expected either valuecontinuous, bit-signal or byte-signal"); % do nothing with other domain signals
                end
            else % audio device output; no storage in obj.signalin
                obj.outputDevice.step(signal.data * db2mag(obj.outputGaindB)); % or step(signal.norm.data)
            end
        end
        
        function saveBytesToFile(obj, varargin)
        % SAVEBYTESTOFILE truncates last bits, that might not fit into a 
        % byte and saves to a file with given filename.
        % arguments:
        % (1) Sink object
        % (2) path and filename
        
            if nargin == 1 % use filename of signal object
                fileID = fopen(obj.signalin.details.filename, 'w');
            elseif nargin == 2 % filename is given in a param
                fileID = fopen(varargin{1}, 'w');
            end
            bitRemains = mod(obj.signalin.lengthInBits, 8);
            if bitRemains == 0
                fwrite(fileID, obj.signalin.data);
                fclose(fileID);
            else
                % to convert to bytes:
                fwrite(fileID, obj.signalin.selectFromBitToBit(1, obj.signalin.lengthInBits - bitRemains).data);
                fclose(fileID);
            end
        end
        
        function saveToAudioFile(obj, pathFile, varargin)
        % SAVETOAUDIOFILE saves valuecontinuous (double, range [-1,1])
        % or PCM (uint8, range {0,...,255}) signals to a playable audio
        % file. The saved signal can be the stored signal in obj.signalin
        % or the signal passed as third argument.
        % arguments:
        % (1) sink object
        % (2) path and filename of written file
        % (3) (optional) signal to save
            
            if nargin == 3
                audiodata = varargin{1}.real.data * db2mag(obj.outputGaindB);
                obj.step(varargin{1}); % concat passed signal
            else
                audiodata = obj.signalin.real.data * db2mag(obj.outputGaindB); % saves real part
            end
            audiowrite(char(pathFile), audiodata, obj.signalin.fs); % char() because pathFile is possibly a string
        end
        
        function player = playAudio(obj, varargin)
        % PLAYAUDIO plays audio data stored in obj.signalin OR given as argument
        % on the default audio output device (not obj.outputDevice).
        % Use player.pause() to pause it.
        % Recommended for non-block-wise output.
        % Use step() and specify obj.outputDevice to blockwise output
        % audio data.
        % arguments:
        % (1) Sink object
        % (2) (optional) signal object to play
        
            if nargin == 2 && isa(varargin{1}, 'Signal')
                obj.signalin = varargin{1};
            end
%            if obj.signalin.signaltype == Signaltype.Valuecontinuous
               audiodata = obj.signalin.real.data * db2mag(obj.outputGaindB); % obj.signalin.real.data; % clip protection
               player = audioplayer(audiodata, obj.signalin.fs);
               player.play;
%            end
       end
       
       function result = compareToOriginalRandomData(obj)
       % COMPARETOORIGINALRANDOMDATA generates random bits according to the
       % seed of the incoming obj.signalin and returns the number of 
       % biterrors between the generated data and obj.signalin.
       
           if obj.signalin.details.sourcetype ~= Sourcetype.Random
               error("not a random generated signal");
           end
           if isfield(obj.signalin.details, 'seed')
               rng(obj.signalin.details.seed); % set seed specified in details
           else
               rng(42); % set default seed
           end
           comparedata = uint8(randi([0,1], obj.signalin.lengthInBits, 1)); % generate random data
           binArr = obj.signalin.selectFromBitToBitAsBitvector(1, obj.signalin.length);
           result = countBiterrors(binArr, comparedata);
       end
        
        function releaseDevice(obj)
        % RELEASEDEVICE releases the output device, if specified.
            if ~isempty(obj.outputDevice) 
                obj.outputDevice.release();
            end
        end
    end
    
    methods (Static)
        function stringArray = getAudioOutputDevices()
        % GETAUDIOOUTPUTDEVICES returns a vector of strings with all
        % available audio output devices.
        
            deviceWriter = audioDeviceWriter; % get System object
            stringArray = string(deviceWriter.getAudioDevices())';
            deviceWriter.release();
        end
    end
end
classdef Source < handle
% SOURCE is an universal Signal object generation module and can
% - generate random binary data
% - read binary data from file
% - read signals from audio files
% - read image files
% - read audio signals from an audio input device
% - generate sine waves
% - generate noisy signals
    
    properties
        signalout Signal                % holds a Signal object
        counter {mustBeNonnegative}     % variable to store how many bits or samples have been output yet
        inputDevice                     % optional; holds system object of AudioDeviceReader, if Sourcetype.Audiodevice
        sineGeneratorProperties         % optional; holds configuration of sine wave generator as 2xNfreq matrix
        noiseType                       % optional; 'uniformly' or 'gaussian'; distribution of random samples
    end
    
    properties (Dependent = true)
        sourceType % for convenience; sourceType is actually stored in signalout.details.sourcetype
    end
    
    methods
        function obj = Source(sourceType, varargin)
        % arguments depend on sourceType:
        % Sourcetype.Random arguments:
        % (1) Sourcetype.Random
        % (2) optional: number of bits
        % (3) optional: seed
        
        % Sourcetype.File arguments:
        % (1) Sourcetype.File
        % (2) path and filename
        
        % Sourcetype.Audiofile arguments:
        % (1) Sourcetype.Audiofile
        % (2) path and filename
        
        % Sourcetype.Audiodevice arguments: 
        % (1) Sourcetype.Audiodevice
        % (2) index of device in getAudioInputDevices() array
        % (3) sample rate of audio device
        % (4) bit depth as string, e.g. '16-bit integer'
        % (5) samples per frame (how many samples are delivered in one step() call)
        % e.g. Source(Sourcetype.Audiodevice, 1, 48000, '16-bit integer', 4096)
        
        % Sourcetype.Imagefile
        % sets obj.signalout to an uint8 array (not matrix!) with RGB values
        % of each pixel one after another: R1 G1 B1 R2 G2 B2 R3
        % attention: dimensions get lost
        % arguments:
        % (1) Sourcetype.Imagefile
        % (2) path and filename
        
        % Sourcetype.Sinusgenerator
        % to generate multiple sinus waves with given amplitudes and frequencies
        % arguments:
        % (1) Sourcetype.Sinusgenerator
        % (2) sample rate
        % (3) vector containing frequencies in Hertz
        % (4) vector containing amplitudes; same dimension as 3rd argument
        
        % Sourcetype.Noisegenerator
        % to generate noisy value-continuous signals
        % arguments:
        % (1) Sourcetype.Sinusgenerator
        % (2) sample rate
        % (3) noise type; 'uniformly' or 'gaussian'
        
            if ~isenum(sourceType) % check if sourceType has to be converted to a enumeration
                details.sourcetype = Sourcetype(sourceType); % new struct; convert possible string to enumeration
            else
                details.sourcetype = sourceType; % new struct
            end
            switch details.sourcetype
                case Sourcetype.Random
                    if nargin == 1 % neither length of random number nor seed specified, default case
                        rng(42); % set random number generation seed to produce the same numbers on every computer
                        lengthBits = 8; % generate 8 random bits
                        details.seed = 42;
                    elseif nargin == 2 % number of bits specified
                        rng(42);
                        lengthBits = abs(round(varargin{1})); % error prevention
                        details.seed = 42;
                    elseif nargin == 3 % both length of random number and seed specified
                        lengthBits = abs(round(varargin{1})); % error prevention
                        rng(abs(round(varargin{2})));
                        details.seed = abs(round(varargin{2}));
                    end
                    data = uint8(randi([0,1], lengthBits, 1));
                    obj.signalout = Signal(data, 1, Signaltype.Bits, details); % bitRate = 1
                case Sourcetype.File
                    if nargin == 2 && (ischar(varargin{1}) || isstring(varargin{1}))
                        fileID = fopen(varargin{1});
                        data = uint8(fread(fileID));
                        fclose(fileID);
                        details.filename = varargin{1};
                        obj.signalout = Signal(data, 1, Signaltype.Bytes, details); % bitRate = 1
                    else
                        error("Source constructor: no path with filename identified");
                    end
                case Sourcetype.Audiofile
                    if nargin == 2 && (ischar(varargin{1}) || isstring(varargin{1}))
                        [imagedata, fs_rec] = audioread(varargin{1});
                        imagedata = imagedata(:, 1); % only mono
                        details.filename = varargin{1};
                        obj.signalout = Signal(imagedata, fs_rec, Signaltype.Valuecontinuous, details);
                    else
                        error("Source constructor: no path with filename identified");
                    end
                case Sourcetype.Audiodevice
                    if nargin == 5
                        obj.inputDevice = audioDeviceReader(varargin{2}, 'BitDepth',varargin{3}, 'SamplesPerFrame',varargin{4});
                        devicesList = obj.getAudioInputDevices;
                        obj.inputDevice.Device = devicesList(varargin{1});
                    else
                        warning("expected arguments: (1) Sourcetype\n(2) index of device in getAudioInputDevices() array\n(3) sample rate\n(4) bit depth as string\n(5) samples fer frame");
                        warning("now using default values: first device listed, sampleRate=48000; bitdepth='16-bit integer'; samplesperframe=4096");
                        obj.inputDevice = audioDeviceReader(48000, 'BitDepth', '16-bit integer', 'SamplesPerFrame', 4096);
                        devicesList = obj.getAudioInputDevices;
                        obj.inputDevice.Device = devicesList(1);
                    end
                    details.sourcetype = Sourcetype.Audiodevice;
                    obj.signalout = Signal([], obj.inputDevice.SampleRate, Signaltype.Valuecontinuous, details);
                case Sourcetype.Imagefile
                    if nargin == 2 && (ischar(varargin{1}) || isstring(varargin{1}))
                        imagedata = imread(char(varargin{1}));
                        imagedata = permute(imagedata, [3 1 2]);
                        imagedata = imagedata(:);
                        details.filename = varargin{1};
                        obj.signalout = Signal(imagedata, 1, Signaltype.Bytes, details);
                    else
                        error("argument error");
                    end
                case Sourcetype.Sinusgenerator                
                    sineFrequencies = varargin{2};
                    sineAmplitudes = varargin{3};
                    if length(sineFrequencies) ~= length(sineAmplitudes)
                        error("length of frequency vector does not match to length of amplitudes vector");
                    end
                    details.sourcetype = Sourcetype.Sinusgenerator;
                    obj.sineGeneratorProperties = [sineFrequencies(:).'; sineAmplitudes(:).'];
                    obj.signalout = Signal([], varargin{1}, Signaltype.Valuecontinuous, details);
                case Sourcetype.Noisegenerator
                    if strcmpi(varargin{2}, 'uniformly') || strcmpi(varargin{2}, 'gaussian')
                        obj.noiseType = varargin{2};
                    end
                    details.sourcetype = Sourcetype.Noisegenerator;
                    obj.signalout = Signal([], varargin{1}, Signaltype.Valuecontinuous, details);
            end
            obj.counter = 0;
        end
        
        function signal = step(obj, varargin)
        % STEP returns (consecutively) parts of signals
        % arguments depend on obj.sourceType:
        % Sourcetype.Audiodevice
        % (1) Source object
        % (2) (optional) number of samples to capture
        
        % Sourcetype.Audiofile
        % (1) Source object
        % (2) (optional) number of samples to output
        
        % Sourcetype.File        note: bitrate is set to 1 bit/s
        % (1) Source object
        % (2) (optional) number of bytes to output; if not specified: entire signal is output
        
        % Sourcetype.Random      note: bitrate is set to 1 bit/s
        % (1) Source object
        % (2) (optional) number of bits to output; if not specified: entire signal is output
        
        % Sourcetype.Imagefile     note: bitrate is set to 1 bit/s
        % (1) Source object
        % (2) (optional) number of bytes to output; if not specified: entire signal is output
        
        % Sourcetype.Sinusgenerator
        % (1) Source object
        % (2) number of samples
        
        % Sourcetype.Noisegenerator
        % (1) Source object
        % (2) number of samples
        
            switch obj.sourceType
                case Sourcetype.Audiodevice
                    if nargin==2
                        numberOfFrames = ceil(varargin{1}/obj.inputDevice.SamplesPerFrame);
                        diff = numberOfFrames * obj.inputDevice.SamplesPerFrame - varargin{1};
                        recordedFrames = 0;
                        allSamplesReceived = [];
                        while recordedFrames < numberOfFrames
                            [SamplesReceived, overrun] = obj.inputDevice.step();
                            obj.signalout.data = SamplesReceived;
                            allSamplesReceived = [allSamplesReceived(:)' SamplesReceived(:)'];
                            recordedFrames = recordedFrames + 1;
                        end
                        obj.signalout.data = allSamplesReceived(1:end-diff);
                        signal = obj.signalout;
                    else
                        [SamplesReceived, overrun] = obj.inputDevice.step();
                        obj.signalout.data = SamplesReceived;
                        signal = obj.signalout;
                    end
                    if overrun > 0
                        warning("Source.step: overrun of audio device in samples: "+overrun);
                    end
                    
                    
                case Sourcetype.Audiofile
                    if nargin == 2 && varargin{1} > 0
                        nSamples = varargin{1};
                        signalLength = obj.signalout.length;
                        if nSamples <= signalLength - obj.counter % if nSamples new samples can be delivered
                            signal = obj.signalout.selectFromTo(obj.counter + 1, obj.counter + nSamples);
                            obj.counter = obj.counter + nSamples;
                        else % if more samples required than available, begin to output at the begin of the file                                                        
                            signal = obj.signalout.selectFromTo(obj.counter + 1, signalLength);
                            remainingSamples = nSamples - (signalLength - obj.counter);
                            while(remainingSamples >= signalLength) % for the case, that the signal is requested multiple times
                                signal = [signal; obj.signalout];
                                remainingSamples = remainingSamples - signalLength;
                            end
                            signal = [signal; obj.signalout.selectFromTo(1, remainingSamples)];
                            obj.counter = remainingSamples;
                        end
                    else
                        signal = obj.signalout; % no number of requested samples specified; entire signal is output
                    end
                case {Sourcetype.File, Sourcetype.Imagefile}
                    if nargin == 2
                        nBytesToOutput = varargin{1};
                        lengthDataInBytes = obj.signalout.length;
                        if nBytesToOutput <= lengthDataInBytes - obj.counter % if nBytesToOutput new bytes can be delivered
                            signal = obj.signalout.selectFromTo(obj.counter + 1, obj.counter + nBytesToOutput);
                            obj.counter = obj.counter + nBytesToOutput;
                        else % if more bytes requested than available, begin to output at the begin of the file
                            signal = obj.signalout.selectFromTo(obj.counter + 1, lengthDataInBytes);
                            remainingBytes = nBytesToOutput - (lengthDataInBytes - obj.counter);
                            while(remainingBytes >= lengthDataInBytes)
                                signal = [signal; obj.signalout];
                                remainingBytes = remainingBytes - lengthDataInBytes;
                            end
                            signal = [signal; obj.signalout.selectFromTo(1, remainingBytes)];
                            obj.counter = remainingBytes;
                        end
                    else % no arguments or too much
                        signal = obj.signalout;
                    end
                case Sourcetype.Random
                    if nargin == 2 % varargin{1} interpreted as number of bits to output                        
                        nBits = varargin{1};
                        lengthDataInBits = obj.signalout.lengthInBits;
                        if nBits <= lengthDataInBits - obj.counter % if nBits new bits can be delivered
                            signal = obj.signalout.selectFromBitToBit(obj.counter + 1, obj.counter + nBits);
                            obj.counter = obj.counter + nBits;
                        else % nBits exceeds the length of unreturned bits
                            % generate new random bits
                            numberOfnewRandomBits = nBits - (lengthDataInBits - obj.counter);
                            % not setting seed with rng() to continue with
                            % existing seed
                            newData = uint8(randi([0,1], numberOfnewRandomBits, 1));
                            newSignal = Signal(newData, obj.signalout.fs, Signaltype.Bits, obj.signalout.details);
                            % append new random bits to old data
                            obj.signalout = [obj.signalout; newSignal];
                            % select correct bits:
                            signal = obj.signalout.selectFromBitToBit(obj.counter+1, obj.counter + nBits);
                            obj.counter = obj.counter + nBits;
                        end
                    else % no arguments or too much
                        signal = obj.signalout;
                    end
                case Sourcetype.Sinusgenerator
                    % varargin{1} interpreted as number of samples to
                    % output
                    nSamples = varargin{1};
                    obj.counter = obj.counter + nSamples;
                    t = (0 : nSamples-1) / obj.signalout.fs;
                    arguments = 2 * pi * t' * obj.sineGeneratorProperties(1, :);
                    sinwaves = sin(arguments);
                    scaledsinwaves = sinwaves .* obj.sineGeneratorProperties(2, :);
                    superposedwaves = sum(scaledsinwaves, 2);
                    details.sourcetype = Sourcetype.Sinusgenerator;
                    signal = Signal(superposedwaves, obj.signalout.fs, Signaltype.Valuecontinuous, details);
                    obj.signalout.data = superposedwaves;
                case Sourcetype.Noisegenerator
                    % varargin{1} interpreted as number of samples to
                    % output
                    nSamples = varargin{1};
                    obj.counter = obj.counter + nSamples;
                    if strcmpi(obj.noiseType, 'uniformly')
                        noisysig = 2 * (rand(nSamples, 1) - 0.5); % random double numbers between -1 and 1
                    else
                        noisysig = randn(nSamples, 1); % random double numbers between -Inf to Inf
                    end
                    obj.signalout.data = noisysig;
                    details.sourcetype = Sourcetype.Noisegenerator;
                    signal = Signal(noisysig, obj.signalout.fs, Signaltype.Valuecontinuous, details);
            end
        end
        
        function releaseDevice(obj)
        % RELEASEDEVICE releases the input device, if specified.
            if ~isempty(obj.inputDevice)
                obj.inputDevice.release();
            end
        end
        
        function sourTy = get.sourceType(obj)
        % SOURCETYPE returns the current source type as Sourcetype enum.
            sourTy = obj.signalout.details.sourcetype;
        end
        
        function resetCounter(obj)
        % RESETCOUNTER sets the counter to zero.
            obj.counter = 0;
        end
    end
    
    methods (Static)
        function stringArray = getAudioInputDevices()
        % GETAUDIOINPUTDEVICES returns a vector of strings with all
        % available audio input devices.
        
            deviceReader = audioDeviceReader; % get System object
            stringArray = string(deviceReader.getAudioDevices())';
            deviceReader.release();
        end
    end
end
classdef ErrorratioSimulator < handle
% ERRORRATIOSIMULATOR is a class for simulation of symbol error rates and
% bit error rates over AWGN channel with various modulation schemes

    properties
        nBits           % number of bits used for simulation
        dBProbes        % vector of values for Es/N0 or Eb/N0 (interpretation depends on choice at simulateAndPlot) in dB, which should be simulated, e.g. 0:12
        errorratios     % results
        sou Source
        map Mapper
        demap Demapper
        ch Channel
        codCh           % channel encoder
        decodCh         % channel decoder
    end
    
    methods
        function obj = ErrorratioSimulator(nBitsSimulation, mapper, varargin)
        % arguments:
        % (1) nBitsSimulation: number of bits used for simulation
        % (2) mapper: Mapper object
        % (3) (optional) ChannelEncoder object
            obj.nBits = nBitsSimulation;
            obj.sou = Source(Sourcetype.Random);
            obj.dBProbes = 0:14; % hard coded default case
            obj.map = mapper;
            obj.demap = obj.map.getDemapper;
            obj.ch = Channel('AWGN', 0);
            if nargin == 3
                obj.codCh = varargin{1};
                obj.decodCh = obj.codCh.getDecoder;
            end
        end
        
        function simulate(obj, type)
        % SIMULATE performs the simulation of the type "type" (either 
        % 'BER' or 'SER').
        % The simulated errorratios are in obj.errorratios based on
        % obj.dBProbes
        
            progressbar = waitbar(0, 'simulating...');
            obj.demap = obj.map.getDemapper;
            % RANDOM SIGNAL GENERATION 
            bitsig = obj.sou.step(obj.nBits);
            obj.errorratios = [];
            if strcmpi(type, 'BER')
                % CHANNELCODING (optional)
                if isempty(obj.codCh)
                    channelcoded = bitsig;
                else
                    channelcoded = obj.codCh.step(bitsig);
                end
                % MAPPING
                mappedsig = obj.map.step(channelcoded);
                for actualSNR = 1:length(obj.dBProbes)
                    obj.ch.params.snr = obj.dBProbes(actualSNR); % set new SNR
                    % AWGN CHANNEL APPLICATION
                    noisysig = obj.ch.step(mappedsig);
                    % DEMAPPING
                    demappedsig = obj.demap.step(noisysig);
                    % CHANNEL DECODING (optional) 
                    if isempty(obj.decodCh)
                        channeldecoded = demappedsig;
                    else
                        channeldecoded = obj.decodCh.step(demappedsig);
                    end
                    % CALC BER
                    newErrorrate = countBiterrors(bitsig, channeldecoded) / obj.nBits;
                    % CONCATENATE TO ARRAY
                    obj.errorratios = [obj.errorratios, newErrorrate];
                    waitbar(actualSNR / length(obj.dBProbes), progressbar);
                end
            elseif strcmpi(type, 'SER')
                mappedsig = obj.map.step(bitsig);
                for actualSNR = 1:length(obj.dBProbes)
                    obj.ch.params.snr = obj.dBProbes(actualSNR); % set new SNR
                    noisysig = obj.ch.step(mappedsig);
                    demappedsig = obj.demap.getEstimatedSymbols(noisysig);
                    numberSymbolerrors = sum(mappedsig.data ~= demappedsig.data); % comparison of double values allowed
                    obj.errorratios = [obj.errorratios, numberSymbolerrors / demappedsig.length];
                    waitbar(actualSNR / length(obj.dBProbes), progressbar);
                end
            end
            progressbar.delete();
        end
        
        function simulateAndPlot(obj, type, varargin)
        % SIMULATEANDPLOT performs the error ratio simulation and plots the
        % results.
        % arguments:
        % (1) obj: ErrorrateSimulator object
        % (2) type: 'BER' or 'SER'
        % (3) (optional): 'EsN0' or 'EbN0': to plot over Eb/N0 or Es/N0
        % Hint: optionally specify obj.dBProbes before calling this function
        
            if strcmpi(type, 'BER')
                if nargin == 2 % no 'EsN0' or 'EbN0' specified
                    PlotOverEsN0 = false; % default: 'EbN0'
                elseif nargin == 3
                    if strcmpi(varargin{1}, 'EsN0')
                        PlotOverEsN0 = true;
                    elseif strcmpi(varargin{1}, 'EbN0')
                        PlotOverEsN0 = false;
                    else
                        warning("choose either 'EsN0' or 'EbN0'");
                    end
                else
                    error("argument error");
                end
                if PlotOverEsN0
                    obj.simulate(type);
                    semilogy(obj.dBProbes, obj.errorratios); % plot semi logarithmic
                    xlabel("Es/N0 in dB");
                else
                    bitpersymbol = log2(obj.map.nsymbols);
                    EbN0Range = obj.dBProbes; % save Eb/N0
                    if isempty(obj.codCh)
                        obj.dBProbes = EbN0Range + pow2db(bitpersymbol); % convert Eb/N0 to Es/N0
                    else
                        obj.dBProbes = EbN0Range + pow2db(bitpersymbol) + pow2db(obj.codCh.getCoderate); % convert Eb/N0 to Es/N0
                    end
                    obj.simulate(type);
                    obj.dBProbes = EbN0Range; % restore Eb/N0 in obj.dBProbes property
                    semilogy(EbN0Range, obj.errorratios); % plot semi logarithmic
                    xlabel("Eb/N0 in dB"); % Eb/N0 ist signal energy per INFORMATION bit per noise power
                end
                ylabel("Bit Error Ratio");
                
                titleString{1} = "Bit Error Ratio of ";
                titleString{1} = titleString{1} + obj.map.nsymbols + "-" + upper(string(obj.map.type)) + ...
                    ", "+string(obj.map.labeling)+" labeling, simulation with "+obj.nBits+" bits, ";
                if isempty(obj.codCh)
                    titleString{2} = "no channel coding";
                else
                    titleString{2} = "channel-coded with " + class(obj.codCh) + ", Coderate R_C = " + obj.codCh.getCoderate;
                end
                title(titleString);
            else % 'SER'
                obj.simulate(type);
                semilogy(obj.dBProbes, obj.errorratios); % plot semi logarithmic
                xlabel("Es/N0 in dB");
                title("Symbol Error Ratio of "+obj.map.nsymbols+"-"+upper(string(obj.map.type))+" ,simulation with "+obj.nBits+" random bits");
                ylabel("Symbol Error Ratio");
            end
            grid on;
        end
    end
end
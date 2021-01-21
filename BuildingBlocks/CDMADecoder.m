classdef CDMADecoder
    properties
        walshMatrix %matrix of wals code
        codeLength
    end
    methods
         function obj = CDMADecoder(codeLength)
             obj.codeLength = codeLength;
             obj.walshMatrix = hadamard(codeLength);
         end
         
         function retSignal = step(obj, signalToBeDecoded, walshIndex)
             walshSequence = obj.walshMatrix(:,walshIndex); %This is the Code for the current index
             signalValues = signalToBeDecoded.data;
             
             %fast Implementation
             trueSignalLength = length(signalValues)/length(walshSequence');
             testStream = ones(1, trueSignalLength);
             testStream = kron(testStream,walshSequence');
             ds = testStream.*signalValues';
             rds=reshape(ds,obj.codeLength,trueSignalLength);
             rds = sum(rds);
             rds(rds<=0) = 0;
             rds(rds>0) = 1;
             
             %Slow Implementation
             %bitStream = [];
             %Every interation codeLength number of values gets extracted from signal Values and decoded in bitStream 
             %while ~isempty(signalValues)
             %    currentSequence = signalValues(1:obj.codeLength);
             %    bitStream = obj.addBitToBitStream(bitStream, currentSequence,walshSequence);
             %    signalValues = signalValues(obj.codeLength+1:end);
             %end
             

             retSignal = Signal(rds,signalToBeDecoded.fs/obj.codeLength);
             retSignal.signaltype = Signaltype.Valuecontinuous;
             
             
         end
         
         %gets an bitsream as input adds a 1 or zero to it depending of
         %decoding. If no Signal has been sent nothing gets added
         function bitStream = addBitToBitStream(obj,inputStream,signalArray, walshSequence)
             skalar = dot(signalArray, walshSequence);
             if skalar>0
                 bitStream = [inputStream, 1];
             elseif skalar<=0  %ToDo change should get zero
                 bitStream = [inputStream, 0];
             else 
                 bitStream=inputStream;
             end
         end
         
         function matrix = getWalshMatrix(obj)
             matrix=obj.walshMatrix;
         end
    end

end
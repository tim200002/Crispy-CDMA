classdef AdvancedImageDeserializer < handle
    %ADVANCEDIMAGEDESERIALIZER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        show_live
        colorResolution
        img
        c_marker
    end
    
    methods
        function obj = AdvancedImageDeserializer(colorResolutionInBits,show_live_deserializtion)
            %ADVANCEDIMAGEDESERIALIZER Construct an instance of this class
            %   Detailed explanation goes here
            obj.colorResolution = colorResolutionInBits;
            obj.show_live = show_live_deserializtion;
            obj.c_marker = 1;
        end
        
        function obj = AddIncomingSignal(obj,incomingSignal)
            if isnan(incomingSignal) == 0
            for n = 1:3
                BitMatrix=reshape(incomingSignal(n,:),[],obj.colorResolution);
                DecMatrix = bi2de(BitMatrix);
                if obj.colorResolution == 4
                 obj.img(:,obj.c_marker,n) = obj.upscaleImageTo8Bits(DecMatrix(:,:));
                else
                 obj.img(:,obj.c_marker,n) = DecMatrix(:,:);
                end
            end
            obj.c_marker = obj.c_marker +1;
            if obj.show_live == true
                imshow(uint8(obj.img));
            end
            end
        end
        

                

    end
    methods(Static)
        function  upscaledArray = upscaleImageTo8Bits(array)
            upscaledArray = array * 17;
        end
    end
end


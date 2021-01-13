classdef ImageSerializer
    %IMAGESERIALIZER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        img
        x
        rgb
    end
    
    methods
        function obj = ImageSerializer(pathToImage)
            %IMAGESERIALIZER Construct an instance of this class
            %   Detailed explanation goes here
            [obj.x,obj.img] = imread(pathToImage);
            if isempty(obj.img)
               %image is already rgb
               obj.rgb = obj.x;
            else
               obj.rgb = ind2rgb(obj.x,obj.img);
            end
        end
        
        function ByteStream = GenerateRGBByteStream(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            [sizex, sizey] = size(obj.rgb);
            for n = 1:3
                colorMat = obj.rgb(:,:,n);
                colorVector = reshape(colorMat,1,[]);
                ByteStream(n,:) = colorVector(1,:);
            end
        end
        
        function BitStream = GenerateRGBBitStream(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            ByteStream = obj.GenerateRGBByteStream();
            [sizex, sizey] = size(obj.rgb);
             for n = 1:3
                BitSignal = de2bi(ByteStream(n,:),8);
                BitSignalVector = reshape(BitSignal,1,[]);
                BitSignalVectorWithLength = [BitSignalVector,de2bi(sizex,32)];
                BitStream(n,:) = BitSignalVectorWithLength(1,:);
            end            
        end
    end
end


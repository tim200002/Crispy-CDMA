function [compressed, compressRate] = JPEGCompressImage(path, compFactor)
% JPEGCOMPRESSIMAGE returns a Signal object containing an uint8 array of
% the compressed JPEG file (incl. header, as it is saved on disk) of the
% image found at path.
% arguments:
% (1) path: to image file, which shall be compressed
% (2) compFactor: JPEG compression factor should be between 0 and 100

uncomp = imread(char(path));
tmpFile = ['temp' date '.jpg'];
imwrite(uncomp, tmpFile, 'jpg', 'Quality', compFactor, 'Mode', 'lossy');
sou = Source(Sourcetype.File, tmpFile);
compressed = sou.step();
compressed.fs = 1; % bitrate set to 1 bit/s
details.sourcetype = Sourcetype.Imagefile; % new struct
details.filename = path;
compressed.details = details;
if nargout == 2
    info1 = imfinfo(char(path));
    info2 = imfinfo(char(tmpFile));
    compressRate =  info2.FileSize / info1.FileSize ;
end
delete(tmpFile);

end
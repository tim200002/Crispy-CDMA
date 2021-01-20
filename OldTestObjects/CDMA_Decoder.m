%% Code Division Multiple Access Decoder (Symetric)
% This encoder uses  vector codes based one Hadamard Matrice
% signal = encoded Signal
% code = Code Numer -> Zeilenummer Hadamard Matrix
% h_l = Hadamard Matrix Größe

function[signalout] = CDMA_Decode(signal, code, h_l, sig_l)

if code>h_l
    errordlg('The input code number must be equal or less than the Hadamard length','File Error');
end

H=hadamard(h_l);

%Get Code from code Number
H_Code = H(code,:);

scused=ones(1,sig_l);

bds=kron(scused,H_Code);

ds=bds.*signal;



rds=reshape(ds,h_l,length(signal)/h_l);

ou=sum(rds);
t=length(ou);
en=[];
for a=1:t
    if ou(a)>1
        en(a)=1;
    else
        en(a)=-1;
    end
end
signalout = en;
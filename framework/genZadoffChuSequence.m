function seq = genZadoffChuSequence(N,u)
% GENZADOFFCHUSEQUENCE returns a Zadoff-Chu sequence "seq" with length "N"
% and parameter "u".

    if nargin <2
        u=7;
        N=127;
    end
    n=1:N;
    c = mod(N,2);
    q=0;
    seq = exp(-1i*pi*u*n.*(n+c+2*q)/N);
end
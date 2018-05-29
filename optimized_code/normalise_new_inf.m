function M = normalise_new_inf(A)
% NORMALISE Make the entries of a (multidimensional) array sum to 1
% [M, c] = normalise(A)
% c is the normalizing constant
%
% [M, c] = normalise(A, dim)
% If dim is specified, we normalise the specified dimension only,
% otherwise we normalise the whole array.


z = sum(A);
% Set any zeros to one before dividing
% This is valid, since c=0 => all i. A(i)=0 => the answer should be 0/1=0
s = z + (z==0);
M = A / s;




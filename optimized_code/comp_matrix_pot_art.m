
function Vpq = comp_matrix_pot_art(D, lab_p, lab_q, gap, relPos)
nr_q = length(lab_q);
nr_p = length(lab_p);

[indp, indq] = overlap_region(relPos, gap);
    
Vpq = calculatepotentialhelper(size(D,1), size(D,2), D, nr_p, lab_p, nr_q, lab_q, indp, indq, gap);
Vpq = reshape(Vpq,[nr_p nr_q]);
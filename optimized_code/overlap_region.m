function [mp, mq] = overlap_region(rel_pos, gap)
mp = zeros(2*gap+1, 2*gap+1);
mq = zeros(2*gap+1, 2*gap+1);
switch rel_pos
    case 'up'
        mp(1:gap+1, 1:2*gap+1) = 1;
        mq(gap+1:2*gap+1, 1:2*gap+1) = 1;
    case 'down'
        mp(gap+1:2*gap+1, 1:2*gap+1) = 1;
        mq(1:gap+1, 1:2*gap+1) = 1;
    case 'right'
        mp(1:2*gap+1, gap+1:2*gap+1) = 1;
        mq(1:2*gap+1, 1:gap+1) = 1;
    case 'left'
        mp(1:2*gap+1, 1:gap+1) = 1;
        mq(1:2*gap+1, gap+1:2*gap+1) = 1;
end
        

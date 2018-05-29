function p = find_first(priority,com)

pUncommitted = priority(~com);
maxValue = max(pUncommitted);
p = find(priority == maxValue & ~com, 1, 'first');
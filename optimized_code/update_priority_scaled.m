function priority = update_priority_scaled(diff, Tuncertain)

% ADDME: assign priority to label for label pruning 

simLabels = (diff-min(diff)) < Tuncertain;
uncertainty = nnz(simLabels);
priority = numel(diff)/uncertainty;
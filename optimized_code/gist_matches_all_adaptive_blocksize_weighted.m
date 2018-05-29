function [gmatches,nbrs,gerrors] = gist_matches_all_adaptive_blocksize_weighted(g, sourceRegion, blocks, nGistMatches, Tb)

% ADDME: context-aware patch selection
% Fiding positions of the blocks that are contextually similar. Block is
% considerd to be similar to it self only if the block is reliable.
% Reliable block is block with more than half known pixels. If the block is
% unreliable similar blocks will be found based on the neighbouring blocks 
% of the unreliable block.

nBlocks = size(blocks,2);
gmatches = cell(1,nBlocks);
gerrors = cell(1,nBlocks);
nbrs = cell(1,nBlocks);
for i = 1:nBlocks
    xstart = blocks(1,i);
    bsx = blocks(3,i);
    ystart = blocks(2,i);
    bsy = blocks(4,i);
    %calculate gist matches only for blocks that intersect the target region
    if (nnz(sourceRegion(xstart:xstart+bsx-1,ystart:ystart+bsy-1)) > bsx*bsy/2) 
        %Check the reliability of the current block. Block is reliable if there are more than half valid pixels
        gp = g(i, :);
        Dr = chiTestTexton(gp,g);
        [B,IX] = sort(Dr,'ascend');
        nGistMatchesNew = find(B<Tb,1,'last');
        nGistMatchesNew = min(nGistMatchesNew,nGistMatches);
        if (isempty(nGistMatchesNew))
            nGistMatchesNew = 2;
        end
        gmatches{i} = IX(1:nGistMatchesNew);
        gerrors{i} = B(1:nGistMatchesNew);
    end
end
for i = 1:nBlocks
    if (isempty(gmatches{i}))
        [l,r,u,d] = find_neighbors_adaptive(blocks,i,size(sourceRegion,1),size(sourceRegion,2));
        allNbrs = cat(2,l,r,u,d);
        for k = 1:length(allNbrs)
            if (allNbrs(k))
                nbrs{i} = cat(2,nbrs{i},allNbrs(k));
            end
        end
        for q = 1 : length(nbrs{i})
            xstart = blocks(1,nbrs{i}(q));
            bsx = blocks(3,nbrs{i}(q));
            ystart = blocks(2,nbrs{i}(q));
            bsy = blocks(4,nbrs{i}(q));
            if (nnz(sourceRegion(xstart:xstart+bsx-1,ystart:ystart+bsy-1)) > bsx*bsy/2)
                for k = 1:length(gmatches{nbrs{i}(q)})
                    if (~any(gmatches{i}==gmatches{nbrs{i}(q)}(k)))
                        gmatches{i} = cat(2,gmatches{i},gmatches{nbrs{i}(q)}(k));
                        % second solution for block matching error of
                        % unreliable blocks: find block matches of its reliable
                        % neighbours and compute the matching error between
                        % them and the unreliable block itself
                        Dr = chiTestTexton(g(gmatches{nbrs{i}(q)}(k),:),g(i,:));
                        gerrors{i} = cat(2,gerrors{i},Dr);
                    end
                end
            elseif (~any(gmatches{i}==nbrs{i}(q)))
                %include just the neighbour in the search space, and not
                %his matches, if he is unreliable
                gmatches{i} = cat(2,gmatches{i},nbrs{i}(q));
                Dr = chiTestTexton(g(nbrs{i}(q),:),g(i,:));
                gerrors{i} = cat(2,gerrors{i},Dr);
            end
        end
        %include the block itself in the search space
        if (~any(gmatches{i}==i))
            gmatches{i} = cat(2,gmatches{i},i);
            gerrors{i} = cat(2,gerrors{i},0);
        end
    end
end
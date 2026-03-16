function updateWaitbar(hWait, N)
    persistent count;
    if isempty(count)
        count = 0;
    end
    count = count + 1;
    waitbar(count/N, hWait, sprintf('Generating stochastic parameters... %d/%d', count, N));
    if count >= N
        count = 0;
    end
end

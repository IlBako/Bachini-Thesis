classdef PoolWaitbar < handle
% Example:
% n = 20
% pw = PoolWaitbar(n, 'Example');
% parfor ii = 1:20
%     increment(pw)
% end
% Copyright © 2021, Skyward Experimental Rocketry, AFD department
% All rights reserved
% 
% SPDX-License-Identifier: GPL-3.0-or-later

    properties (SetAccess = immutable, GetAccess = private)
        Queue
        n
    end

    properties (Access = private, Transient)
        ClientHandle = []
        Count = 0
    end

    properties (SetAccess = immutable, GetAccess = private, Transient)
        Listener = []
    end

    methods (Access = private)
        function localIncrement(obj)
            obj.Count = 1 + obj.Count;
            waitbar(obj.Count / obj.n, obj.ClientHandle);
        end
    end
    
    methods
        function obj = PoolWaitbar(N, message)
            if nargin < 2
                message = 'PoolWaitbar';
            end
            obj.n = N;
            obj.ClientHandle = waitbar(0, message);
            obj.Queue = parallel.pool.DataQueue;
            obj.Listener = afterEach(obj.Queue, @(~) localIncrement(obj));
        end

        function increment(obj)
            send(obj.Queue, true);
        end

        function delete(obj)
            delete(obj.ClientHandle);
            delete(obj.Queue);
        end
    end
end
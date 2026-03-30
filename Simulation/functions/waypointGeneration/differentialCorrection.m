function [x0Out, TOut, converged, residualHistory] = differentialCorrection(...
        init, TGuess, model, tolPos, tolVel, maxIter)

    % Uses single shooting with a phase constraint (Scheeres 2012, Ch. 10).
    % The system F(x0,T) = x(T;x0) - x0 = 0 has 6 equations in 7 unknowns.
    % A phase constraint pins one component of x0, making it 7x7 and well-posed.

    x0Guess = [init.scPosition init.scVelocity];

    [~, phaseIdx] = max(abs(x0Guess));
    phaseVal      = x0Guess(phaseIdx);

    x0 = reshape(x0Guess, [6 1]);
    TSim = TGuess;
    residualHistory = zeros(maxIter, 2);
    converged = false;

    for iter = 1:maxIter

        % Update init variable
        init.scPosition = x0(1:3);
        init.scVelocity = x0(4:6);

        % Step 1: propagate augmented state [r, v, STM]
        [x_F, Phi_F, f_F] = STMPropagationRunner(model, init, TSim);

        % Step 2: periodicity residual err = x(Tf) - x(0)
        err = reshape(x_F, [6 1]) - x0;

        posErr = norm(err(1:3));
        velErr = norm(err(4:6));

        residualHistory(iter,:) = [posErr, velErr];

        % Step 3: Check convergence
        if posErr < tolPos && velErr < tolVel
            converged = true;
            break;
        end

        % Step 4: Jacobian
        dFdx0 = Phi_F - eye(6);
        dFdT = f_F;

        phaseRow = zeros(1,7);
        phaseRow(phaseIdx) = 1;

        J = [dFdx0, dFdT;
            phaseRow];

        phaseRes = x0(phaseIdx) - phaseVal;
        rhs = [-err; -phaseRes];

        % Step 5: Solve for Newton's method update
        if rcond(J) < 1e-12
            warning('Jacobian near-singular (rcond = %.2e) at iter %d. Using pinv.', ...
                rcond(J), iter);
            delta = pinv(J) * rhs;
        else
            delta = J \ rhs;
        end

        deltaX0 = delta(1:6);
        deltaT = delta(7);

        % Step 6: Update solution
        x0 = reshape(x0, [6 1]) + reshape(deltaX0, [6 1]);
        TSim = TSim + deltaT;

        % TSim must remain physically reasonable
        TSim = max(TSim, TGuess * 0.2);
        TSim = min(TSim, TGuess * 5.0);
    end

    residualHistory = residualHistory(1:iter, :);

    if ~converged
        warning(['Differential correction did not converge in %d iterations.\n' ...
            'Final: pos_err=%.4e m, vel_err=%.4e m/s'], ...
            maxIter, posErr, velErr);
    end

    x0Out = x0;
    TOut = TSim;
end
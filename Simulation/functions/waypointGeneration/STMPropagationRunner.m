function [x_F,Phi_F, f_F] = STMPropagationRunner(model, init, TSim)

    init.scPosition = reshape(init.scPosition, [1 3]);
    init.scVelocity = reshape(init.scVelocity, [1 3]);

    model = model.setVariable('init', init);
    model = model.setVariable('TSim', TSim);
    simOut = sim(model);

    x_F = simOut.SCStateFinal(1:6)';
    Phi_F = reshape(simOut.SCStateFinal(7:42), [6 6]);
    f_F = simOut.dYFinal(:);
end
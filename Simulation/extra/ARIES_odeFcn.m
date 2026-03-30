function dY = ARIES_odeFcn(t, y, gravAccInterp, params)

    %% Extract variables
    r_S = y(1:3);   % S/C position in F_B
    v_S = y(4:6);   % S/C velocity in F_B
    q = y(7:10);    % S/C scalar-first quaternions F_S -> F_B
    w_S = y(11:13); % S/C ang. vel in F_S
    r_B = y(14:16); % Asteroid position in F_S
    v_B = y(17:19); % Asteroid velocity in F_S
    
    % Normalize quaternions
    q = q/norm(q);

    %% Extract parameters
    wb = params.wb; % Asteroid ang.vel in F_B
    I = params.I_sc; % S/C Inertia matrix
    I_inv = params.I_inv; % S/C Inertia matrix
    m_sc = params.m_sc; % S/C mass
    R_A = params.R_A; % Equivalent radius of asteroid 
    mu_sun = params.mu_sun; % Gravitational parameter of the sun

    %% Define rotation matrices
    C_SB = [q(1)^2+q(2)^2-q(3)^2-q(4)^2     2*(q(2)*q(3)+q(1)*q(4))      2*(q(2)*q(4)-q(1)*q(3));
            2*(q(2)*q(3)-q(1)*q(4))         q(1)^2-q(2)^2+q(3)^2-q(4)^2  2*(q(3)*q(4)+q(1)*q(2));
            2*(q(2)*q(4)+q(1)*q(3))         2*(q(3)*q(4)-q(1)*q(2))      q(1)^2-q(2)^2-q(3)^2+q(4)^2];

    theta_A = wb(end)*t;
    C_IB = [cos(theta_A) sin(theta_A) 0;
           -sin(theta_A) cos(theta_A) 0;
            0            0            1];

    %% Accelerations
    [R, polar, azimuth] = cart2Sphere(r_S);
    acc_g = squeeze(gravAccInterp(R, polar, azimuth));
    coriolis = -2*cross(wb, v_S);
    centrifugal = -cross(wb, cross(wb, r_S));

    %% Perturbations
    AU = 149598000*1e3; % Astronomical unit

    r_B_body = -C_IB*r_B;
    r_sun_SC_body = r_B_body - r_S;
    s_B = r_sun_SC_body/norm(r_sun_SC_body);
    s_S = C_SB'*s_B;

    d = norm(cross(r_B_body, s_B))/norm(s_B);
    
    if (dot(r_B_body/norm(r_B_body),s_B) > 0 && d < R_A)
        eta = 0;
    else
        eta = 1;
    end

    P_sun = 1361/299792458 * (AU/norm(r_sun_SC_body))^2;

    n_mat = [1  0  0;
             0  1  0;
            -1  0  0;
             0 -1  0;
             0  0  1;
             0  0 -1;
             1  0  0;
            -1  0  0;
             0  1  0;
             0 -1  0];

    A_mat = [6*ones(4,1);
             4*ones(2,1);
             12*ones(4,1)];
    c_spec = [0.5*ones(6,1);
              0.1*ones(4,1)];
    c_diff = 0.1;
    r_p_mat = [10   0   0;
                0  10   0;
              -10   0   0;
               10   0   0;
                0   0  15;
                0   0 -15;
                0   0  45;
                0   0  45;
                0   0 -45;
                0   0 -45];

    F_SRP = 0;
    tau_SRP = 0;
    for ii = 1:6
        cthi = dot(s_S, n_mat(ii,:));
        if cthi <= 0
            continue
        end
        F_SRP_pane = -P_sun*A_mat(ii)*cthi*((1-c_spec(ii))*s_S+(2/3*c_diff+2*c_spec(ii)*cthi)*n_mat(ii,:)');
        F_SRP = F_SRP + F_SRP_pane;
        tau_SRP = cross(r_p_mat(ii, :)', F_SRP_pane);
    end
    F_SRP_B = C_SB*F_SRP*eta;
    a_SRP = F_SRP_B/m_sc;

    a_3BP = 0;

    acc_pert = a_SRP + a_3BP;
    tau_pert = tau_SRP;

    %% Control
    a_u = 0;

    acc_sc = acc_g + coriolis + centrifugal + acc_pert + a_u;

    %% Attitude kinematics and dynamics 
    OM = [0     -w_S(1) -w_S(2) -w_S(3);
          w_S(1)  0      w_S(3) -w_S(2);
          w_S(2) -w_S(3)  0      w_S(1);
          w_S(3)  w_S(2) -w_S(1)  0    ];
    q_dot = 1/2*OM*q;

    ws_dot = I_inv*(cross(w_S, I*w_S) - tau_pert);

    %% Assemble final derivative
    dY = zeros(19, 1);
    dY(1:3) = v_S;
    dY(4:6) = acc_sc;
    dY(7:10) = q_dot;
    dY(11:13) = ws_dot;
    % dY(14:16) = v_B;
    % dY(17:19) = -mu_sun*r_B/norm(r_B)^3;

end
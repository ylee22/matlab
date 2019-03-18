function [ diff_mean, diff_std, occupancy, posterior_tp_mean, posterior_tp_std, model_fit ] = specific_model_param( runinput, model_size )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%% Parse input

% if an existing file, generate options structure
if(isstr(runinput) && exist(runinput)==2)
    runinputfile = runinput;
    opt=VB3_getOptions(runinputfile);
    disp(['Read runinput file ' runinputfile])
    % if an option struct, read in the runinputfilename
elseif(isstruct(runinput))
    opt=runinput;
    runinputfile=opt.runinputfile;
    disp(['Read options structure based on runinput file ' runinputfile ])
else
    error(['Not a valid input, aborting']);
end

%% load the vbSPT model

try
    res=load(opt.outputfile);
catch me
    if(~exist(opt.outputfile)) % if there is no vbSPT run for this movie
        diff_mean = [];
        diff_std = [];
        occupancy = [];
        posterior_tp_mean = [];
        posterior_tp_std = [];
        model_fit = [];
        return 
    end
end


%% get diff coeff, occupancy, transition matrix
diff_mean = res.WbestN{model_size}.est.DdtMean/opt.timestep;
diff_std = res.WbestN{model_size}.est.Ddtstd/opt.timestep;
occupancy = res.WbestN{model_size}.est.Ptot;
posterior_tp_mean = res.WbestN{model_size}.est.Amean;
posterior_tp_std = res.WbestN{model_size}.est.Astd;
model_fit = res.dF;

end


function write_model_parameters(lfdir, varargin)
% function lfadsi_run_posterior_mean_sample(lfdir, varargin)
%  calls the python script to sample the posterior and generate parameter estimates
%  arguments
%    lfdir: path to the trained network
%
%    varargin: overloads the parameters used to fit the model, e.g.
%     (..., 'checkpoint_pb_load_name', 'checkpoint_lve',
%     'batch_size', 512, 'device', NDEVICE)
%
%   checkpoint_pb_load_name selects which file to use for
%   checkpoints
%
%   batch_size selects how many samples to use for computing
%   posterior average
%
%   device specifies which gpu to run this on

params = LFADS.Interface.read_parameters(lfdir);

% need to remove "dataset_names" and "dataset_dims"
fields2remove = {'dataset_names', 'dataset_dims'};
for nf = 1:numel(fields2remove)
    if isfield(params, fields2remove{nf})
        params = rmfield(params, fields2remove{nf});
    end
end

use_controller = boolean(params.ci_enc_dim);

tmp = lfads_path();
if ~use_controller
    lfpath = fullfile(tmp.path, tmp.lfnc);
else
    lfpath = fullfile(tmp.path, tmp.lf);
end

if ~exist('varargin','var'), varargin ={}; end

execstr = ' python';

% take the arguments passed in via varargin, add new params, or overwrite existing ones
for nn = 1:2:numel(varargin)
    % have to specially handle CUDA_VISIBLE_DEVICES as an environment ...
    %   variable rather than a command line param
    if strcmpi(varargin{nn},'device')
        execstr = strcat(sprintf('CUDA_VISIBLE_DEVICES=%i', varargin{nn+1}),  ...
                         execstr);
    else
        params.(varargin{nn}) = varargin{nn+1};
    end
end

f = fields(params);
optstr = '';
for nf = 1:numel(f)
    fval = params.(f{nf});
    %convert any numbers to strings
    if isnumeric(fval), fval = num2str(fval); end
    optstr = strcat(optstr, sprintf(' --%s=%s',f{nf}, fval));
end


optstr = strcat(optstr, sprintf(' --kind=write_model_params',f{nf}, fval));

% put the command together
cmd = sprintf('%s %s %s', execstr, lfpath, optstr);

cmdSave = '/tmp/lfadspmcmd';
fid = fopen(cmdSave,'w');
fprintf(fid,'%s\n', cmd);
fclose(fid);
disp(cmd);
disp(' ');
disp(sprintf('command written to %s', cmdSave));

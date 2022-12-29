function export_spikes(outfile, ytrain, ytest, varargin)
%% function lfads_export_spikes(outfile, ytrain, ytest, varargin)
%
% exports spikes to an hdf5 file that can be easily read by python
%
% inputs: 
%
%     outfile: filename to output data to. it's reasonable to use the extension ".h5"
%
%     ytrain: millisecond-binned spiketrains to train model. in Matlab, it should be a 3-D array, [nTrials x
%   nTimesteps x nNeurons]
%
%     ytest: millisecond-binned spiketrains to validate model. in Matlab, it should be a 3-D array, [nTrials x nTimesteps x nNeurons]
%
%   varargin: 'name' - value pairs
%         other variables you may want to pass into the python code
%

    if exist(outfile,'file')
%         warning(sprintf('warning -  file %s! any key to continue, ctrl-c to cancel', outfile));
%         pause
        delete(outfile);
    end
    
    sWarn = warning('off', 'MATLAB:imagesci:hdf5dataset:datatypeOutOfRange');

    %% permute to deal with matlab v python (column-major v row-major)
    ndim = numel(size(ytrain));
    ytrain = permute(ytrain, ndim:-1:1);

    ndim = numel(size(ytest));
    ytest = permute(ytest, ndim:-1:1);
    
    outfile = LFADS.Utils.GetFullPath(outfile);

    %% create an hdf5 file and add the variables
    fileID = H5F.create(outfile, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', 'H5P_DEFAULT');
    dtypeID = H5T.copy('H5T_NATIVE_INT');
    dspID1 = H5S.create_simple(numel(size(ytrain)), fliplr(size(ytrain)), []);
    dspID2 = H5S.create_simple(numel(size(ytest)), fliplr(size(ytest)), []);
    dsetname1 = 'train_data';   dsetname2 = 'valid_data';
    dset1ID = H5D.create(fileID, dsetname1, dtypeID, dspID1, 'H5P_DEFAULT');
    dset2ID = H5D.create(fileID, dsetname2, dtypeID, dspID2, 'H5P_DEFAULT');

    H5D.write(dset1ID, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', ...
        'H5P_DEFAULT', ytrain);
    H5D.write(dset2ID, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', ...
        'H5P_DEFAULT', ytest);

%     h5create(outfile, '/train_data', size(ytrain), 'Datatype','int64');
%     h5write(outfile, '/train_data', ytrain);
%     h5create(outfile, '/valid_data', size(ytest),'Datatype','int64');
%     h5write(outfile, '/valid_data', ytest);

    if exist('varargin','var') && ~isempty(varargin)
        %% assign the rest of the variables
        if mod(numel(varargin),2) ~= 0
            error('varargin should be name-value pairs')
        end

        nv = 1;
        while nv < numel(varargin)
            if ~ischar(varargin{nv})
                error('varargin should be name-value pairs');
            end

            data = varargin{nv+1};
            
            if isvector(data)
                data = LFADS.Utils.makecol(squeeze(data));
                sz = size(data, 1);
            else
              %% permute to deal with matlab v python (column-major v row-major)
                ndim = numel(size(data));
                data = permute(data, ndim:-1:1);
                sz = size(data);
            end
            % h5create(outfile, sprintf('/%s', varargin{nv}), sz);
            if islogical(data)
                data = uint8(data); % boolean not supported by Matlab
            end

            % dspID3 = H5S.create_simple(1, sz, []);
            dspID3 = H5S.create_simple(numel(sz), sz, []);
            dset3ID = H5D.create(fileID, varargin{nv}, dtypeID, dspID3, 'H5P_DEFAULT');
            H5D.write(dset3ID, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', ...
                'H5P_DEFAULT', data);
            % h5write(outfile, sprintf('/%s', varargin{nv}), data);
            nv = nv+2;
        end
        H5D.close(dset1ID);H5D.close(dset2ID);H5D.close(dset3ID);
        H5S.close(dspID1);H5S.close(dspID2);H5S.close(dspID3);
        H5T.close(dtypeID);
        H5F.close(fileID);
    end 
        
    warning(sWarn);

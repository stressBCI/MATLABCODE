folderPath = '/Users/aarooshbalakrishnan/Documents/Normal';  %change depeneding on folder i want
addpath("/Users/aarooshbalakrishnan/Downloads/matlab_package (2)/brainflow/inc");
addpath("/Users/aarooshbalakrishnan/Downloads/matlab_package (2)/brainflow/lib")
addpath("/Users/aarooshbalakrishnan/Downloads/matlab_package (2)/brainflow");


fileList = dir(fullfile(folderPath, '**', '*.txt')); 

for i = 1:length(fileList)
   
    if ~fileList(i).isdir     %gets file name
       
        fileName = fileList(i).name;
        fullPath = fullfile(fileList(i).folder, fileName);
        % Reads table
        dataTable = readtable(fullPath, 'Delimiter', ',', 'ReadVariableNames', false);
           
       % Takes the 2nd to 5th columns
        datas = dataTable(:, 2:5);
        datas = table2array(datas);
        datas = DataFilter.perform_lowpass(datas, 200, 50.0, 3, int32(FilterTypes.BUTTERWORTH), 0.0);
        save('datas.mat', 'datas');
       
       
        dataStruct = load('/Users/aarooshbalakrishnan/Documents/datas.mat'); % Adjust the file path as needed

        
        fieldNames = fields(dataStruct);
        EEG_data = dataStruct.(fieldNames{1}); 
        
        


%Applies feature extraction code to get matrixes

        Fs = 250;    %frequency
        
        % Define frequency bands
        delta_band = [1, 3];
        theta_band = [4, 7];
        alpha_band = [8, 12];
        beta_band = [13, 30];
        

        num_channels = size(EEG_data, 2);

        feature_matrix = zeros(num_channels, 6);
        
        for chanIdx = 1:num_channels
            % Extract channel data
            data = EEG_data(:, chanIdx);
            
            % Finding PSD using Welch method
            [psd, freq] = pwelch(data, hamming(256), 128, 256, Fs);
            
            
            bands = {delta_band, theta_band, alpha_band, beta_band};
            RER = zeros(1, 4);
            %calculating RER
            for b = 1:length(bands)
                band = bands{b};
                band_idx = freq >= band(1) & freq <= band(2);
                RER(b) = sum(psd(band_idx)) / sum(psd);
            end
            
            % Calculating Spectral Centroid
            SC = sum(freq .* psd) / sum(psd);
            
            % Calculating Shannon Entropy
            psd_norm = psd / sum(psd); % Normalize PSD
            SE = -sum(psd_norm .* log2(psd_norm + eps)); 
            
            % Append features for this channel to the feature matrix
            feature_matrix(chanIdx, :) = [RER, SC, SE];
            
        end
        feature_matrix = [feature_matrix, zeros(size(feature_matrix, 1), 1)];  %change to 1s for stress data
        
            %final setting up steps
            newFileName = strcat('/Users/aarooshbalakrishnan/Documents/Features_', erase(fileName, '.txt'), '.mat');
            save(newFileName, 'feature_matrix');
            
            
            
        
        disp(feature_matrix)

    end
end

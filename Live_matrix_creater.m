% % Set the log file for BrainFlow's logging messages
addpath("/Users/aarooshbalakrishnan/Downloads/matlab_package (2)/brainflow/inc");
addpath("/Users/aarooshbalakrishnan/Downloads/matlab_package (2)/brainflow/lib")
addpath("/Users/aarooshbalakrishnan/Downloads/matlab_package (2)/brainflow");

% starts logging
BoardShim.set_log_file('brainflow.log');
BoardShim.enable_dev_board_logger();


%reading from board
params = BrainFlowInputParams();
params.serial_port = "/dev/cu.usbmodem11";
board_shim = BoardShim(BoardIds.GANGLION_BOARD, params);
preset = int32(BrainFlowPresets.DEFAULT_PRESET);
board_shim.prepare_session();
board_shim.add_streamer('file://data_default.csv:w', preset);
board_shim.start_stream(45000, '');
pause(5);
board_shim.stop_stream();
data = board_shim.get_current_board_data(10000, preset);  %can change to alter how much you read live
board_shim.release_session



%changing data format
data=data';
data=data(:,2:5);

%filtering
sampling_rate = BoardShim.get_sampling_rate(int32(BoardIds.GANGLION_BOARD), preset);
filtered_data = DataFilter.perform_lowpass(data, 200, 50.0, 3, int32(FilterTypes.BUTTERWORTH), 0.0);


% % for graphing:
% 
% numColumns = size(filtered_data, 2);
% 
% 
% for i = 1:numColumns
%     figure; % Create a new figure for each plot
%     plot(filtered_data(:, i));
%     title(['Plot of Column ', num2str(i+1)]);
%     xlabel('Index'); % Assuming the x-axis represents some index
%     ylabel('Value'); % Replace with your actual quantity if needed
% end
save('new.mat', 'filtered_data');




% Load the EEG data from a .mat file
dataStruct = load('/Users/aarooshbalakrishnan/Documents/new.mat'); % Adjust the file path as needed

% Assuming the EEG data is directly at the top level or has a specific variable name.
% This script assumes there's a single variable containing the EEG data matrix.
fieldNames = fields(dataStruct);
EEG_data = dataStruct.(fieldNames{1}); % Adjust to access the correct field if necessary

% Determine if EEG_data is structured by channels (columns) or if further adaptation is needed

% Sampling frequency (adjust according to your data specifics)
Fs = 250;

% Define frequency bands
delta_band = [1, 3];
theta_band = [4, 7];
alpha_band = [8, 12];
beta_band = [13, 30];

% Number of channels (assumed to be the second dimension of EEG_data)
num_channels = size(EEG_data, 2);

% Initialize the feature matrix: assuming 6 features per channel based on earlier description
% RER for delta, theta, alpha, beta bands, Spectral Centroid (SC), Shannon Entropy (SE)
feature_matrix = zeros(num_channels, 6);

for chanIdx = 1:num_channels
    % Extract channel data
    data = EEG_data(:, chanIdx);
    
    % Compute PSD using Welch's method
    [psd, freq] = pwelch(data, hamming(256), 128, 256, Fs);
    
    % Initialize variables for RER calculation
    bands = {delta_band, theta_band, alpha_band, beta_band};
    RER = zeros(1, 4);
    
    for b = 1:length(bands)
        band = bands{b};
        band_idx = freq >= band(1) & freq <= band(2);
        RER(b) = sum(psd(band_idx)) / sum(psd);
    end
    
    % Calculate Spectral Centroid
    SC = sum(freq .* psd) / sum(psd);
    
    % Calculate Shannon Entropy
    psd_norm = psd / sum(psd); % Normalize PSD
    SE = -sum(psd_norm .* log2(psd_norm + eps)); % Use eps to avoid log of 0
    
    % Append features for this channel to the feature matrix
    feature_matrix(chanIdx, :) = [RER, SC, SE];
end

disp(feature_matrix);
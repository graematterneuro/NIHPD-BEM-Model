%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BEMModelCreator.m
%
% This script is designed to create custom BEM volume conduction head
% models from the NIHPD atlases in FieldTrip and partially fulfills the
% requirements for the author's Doctor of Philosophy program at the
% University of Sydney, Australia.
% This script was coded without the use of generative AI.
%
% Author: Grace Harvie, WIMR/USyd, 2026
% Other contributions noted in comments where appropriate.
%
% Copyright (C) 2026 Grace Harvie, Westmead Institute for Medical Research
% and The University of Sydney, grace.harvie@sydney.edu.au
%
% License: PolyForm Noncommercial License 1.0.0
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%                        OPEN FIELDTRIP                           %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if pwd ~= "C:\Users\Grae\OneDrive - Westmead Institute for Medical Research\Documents\FieldTrip_MyFiles"
    cd("C:\Users\Grae\OneDrive - Westmead Institute for Medical Research\Documents\FieldTrip_MyFiles");
end

if ~exist('filePaths')
    % Create a variable for FilePaths.env
    filePaths = dotenv();
end

addpath(filePaths.env.fieldtrip);
ft_defaults;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%                            VARIABLES                            %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Create a string array of the age ranges used in the file ranges for
% piping into our for loop
ageRangeFile = ["4-5to8-5"; ...
    "7to11"; ...
    "10to14"; ...
    "13to18-5"];

% Get the number of rows in PID table so that the for loop will iterate
NoRows = height(ageRangeFile);

% Create a string array of age ranges which will allow us to label fields
% dynamically
ageRangeVar = ["four_seven"; ...
    "seven_ten"; ...
    "ten_thirteen"; ...
    "thirteen_eighteen"];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%                         BEGIN FOR LOOP                          %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for row = 1:1

    % Change directory to the location of the NIFTI files
    cd(filePaths.env.nifti);

    % Get the file name of the current MRI to be model
    currMRI = append("nihpd_asym_",ageRangeFile(row),"_t2w.nii");

    % Get the current age range for piping into the scalar struct where the
    % data will be stored.
    currAgeRange = ageRangeVar(row);

    % Read the current MRI and store it in the struct
    t1.(currAgeRange).import = ft_read_mri(currMRI);

    % Correct the anatomical labels for the axes
    t1.(currAgeRange).import = ft_determine_coordsys(t1.(currAgeRange).import);

    % Save the struct
    save("t1.mat", "-struct", "t1")

    % Get the fiducial points and realigned the volume
    cfg = [];
    cfg.method = 'ortho';
    fprintf("Use the source plot to determine the coordinates of the nasion, left and right preauricular points.")
    ft_sourceplot(cfg, t1.(currAgeRange).import);

    nasion = input(append("In square brackets, specify the coordinates of the nasion:", newline));
    % 4-7      [0 79 -45]
    % 7-10 
    % 10-13    [0 83 -48]
    % 13-18.5  [0 85 -49]
    lpa = input(append("In square brackets, specify the coordinates of the LPA:", newline));
    % 4-7      [-71 -12 -64]
    % 7-10
    % 10-13    [-79 -14 -63]
    % 13-18.5  [-81 -8 -64]
    rpa = input(append("In square brackets, specify the coordinates of the RPA:", newline));
    % 4-7      [72 -12 -64]
    % 7-10 
    % 10-13    [79 -14 -63]
    % 13-18.5  [81 -8 -65]

    cfg = [];
    cfg.method = 'fiducial';
    cfg.fiducial.nas = nasion;
    cfg.fiducial.lpa = lpa;
    cfg.fiducial.rpa = rpa;
    cfg.coordsys = 'ctf';

    t1.(currAgeRange).realigned = ft_volumerealign(cfg, t1.(currAgeRange).import);

    % Save the struct
    save("t1.mat", "-struct", "t1")

    % Reslice the volume
    cfg = [];
    cfg.method = 'linear';
    t1.(currAgeRange).resliced = ft_volumereslice(cfg, t1.(currAgeRange).realigned);

    % Segment the volume
    cfg = [];
    cfg.output = {'brain', 'skull', 'scalp'};
    t1.(currAgeRange).segmented = ft_volumesegment(cfg, t1.(currAgeRange).resliced);

    % Save the struct
    save("t1.mat", "-struct", "t1")

    disp(t1.(currAgeRange).segmented)

end
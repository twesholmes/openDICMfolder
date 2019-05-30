%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reading in a DICOM image stack from either an input path or from a user
% selected folder and removing the personal information
%
% Wesley Holmes
% twesholmes@gmail.com
% 5/30/2019
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [IM, INFO] = openDICMfolder(InFolder)

% This allows either the input of the file location or the user to
% dynamically select it
if exist('InFolder','var') % Used if the image folder lation is an input
    selpath = InFolder;
    
else % Used if no location is included
    selpath = uigetdir(pwd);
       
end

% Making sure that a location was selected
if selpath == 0
    disp('No folder selected.')
    
    % Returning NaN's for the output
    IM = NaN;
    INFO = NaN;
    return
end


% Adding a wait bar to show progress
f = waitbar(0,'Please wait...');
set(f, 'pointer', 'watch') % This makes it wait over the progress bar


% Checking the contents of the selected folder
a=dir(fullfile(selpath,'*.dcm'));
if isempty(a)
    a=dir(fullfile(selpath,'*.IMA'));    
    if isempty(a)        
        a=dir(fullfile(selpath,'0*'));
        if isempty(a)        
            
            % Closing the wait bar
            close(f)
            
            % Displaying an error log
            errordlg('No image files found.','modal')            
            
            % Returning NaN's for the output
            IM = NaN;
            INFO = NaN;
            return
        end
    end
end


% Counting the number of approperate files in the selected folder
n = numel(a);


% Calling the fuction to read the image stack
[IM, INFO_Read] = dicomVOLread_v1(selpath,1,n);

%% Working on removing the personal information
% Checking tomake sure that only a single info is returned
if iscell(INFO_Read)
    INFO = INFO_Read{1};
else
    INFO = INFO_Read;
end

% Randomly chosen values to randomize with
DateShift = floor(rand()*1e13);
TimeShift = floor(rand()*1e6);
% Now we can remove the values and make it annonamized
INFO.Filename = [];
INFO.FileModDate = [];
if isfield(INFO,'InstanceCreationDate')
    INFO.InstanceCreationDate = sprintf('%i',(str2double(INFO.InstanceCreationDate) + TimeShift));
    INFO.InstanceCreationTime = sprintf('%6.3f',(str2double(INFO.InstanceCreationDate) + TimeShift));
end
% info.SOPClassUID = [' '];
% info.SOPInstanceUID = [' '];
INFO.StudyDate = [];
INFO.SeriesDate = [];

if isfield(INFO,'AcquisitionDate')
    INFO.AcquisitionDate = [];
end

if isfield(INFO,'AcquisitionDateTime')
    INFO.AcquisitionDateTime = sprintf('%f',(str2double(INFO.AcquisitionDateTime) + DateShift + TimeShift));
end
    
INFO.StudyTime = sprintf('%f',(str2double(INFO.StudyTime) + + TimeShift));
INFO.SeriesTime = sprintf('%f',(str2double(INFO.SeriesTime) + + TimeShift));

if isfield(INFO,'AcquisitionTime')
    INFO.AcquisitionTime = sprintf('%f',(str2double(INFO.AcquisitionTime) + + TimeShift));
end

INFO.ContentTime = sprintf('%f',(str2double(INFO.ContentTime) + + TimeShift));
INFO.ContentDate = [];
INFO.AccessionNumber = [];
INFO.InstitutionAddress = [];
INFO.InstitutionName = [];
INFO.InstitutionalDepartmentName = [];
INFO.StationName = [];
INFO.ReferringPhysicianName = [];
INFO.PhysicianOfRecord = [];
INFO.PerformingPhysicianName = [];
INFO.OperatorName = [];
INFO.DeviceSerialNumber = [];
INFO.StudyInstanceUID = [];
INFO.SeriesInstanceUID = [];
INFO.PatientName = sprintf('Patient_%05d',PatientID);
INFO.PatientID = sprintf('%05d',PatientID);
INFO.PatientSex = [];
INFO.PatientAge = [];
INFO.PatientBirthDate = [];
INFO.PatientAddress = [];
INFO.EthnicGroup = [];
INFO.IssuerOfPatientID = [];
INFO.RequestingPhysician = [];
INFO.SpecialNeeds = [];



% Updating the waitbar
WaitText = sprintf('Finished');
waitbar(100,f,WaitText);


% Resetting the cursor to the regular state and closing
set(f, 'pointer', 'arrow')
close(f)

    %% Nested Function to deal with the full DICOM stack
    function [IM, INFO] = dicomVOLread_v1(foldername,start,finish)
        
        % Reading in the the first file to check on its size for allocation
        tmp = dicomread(fullfile(foldername,a(1).name));
        % Allocating space for the output image to fill
        IM = zeros(size(tmp,1),size(tmp,2),finish-start+1,'single');
        % Simple counter if the start and finish are different
        
        % Only reading the first image and using its information
        % This speeds up the process
        INFO = dicominfo(fullfile(foldername,a(1).name));
        
        % Simple counter
        cnt = 1;
        
        % Moving through each of the image files
        for II = start:finish
            
            % Clearing out the previous data
            clear tmp
            
            % Finding the next file name
            fname = (fullfile(foldername,a(II).name));
            
            % Reading in the image data
            tmp = dicomread(fname);
            % Re-Scaling the data to translate into the propper HU values
            IM(:,:,cnt) = single(tmp).*INFO.RescaleSlope + INFO.RescaleIntercept;    
            
            % Progressing the counter
            cnt = cnt+1;
            
            % Updating the waitbar
            WaitText = sprintf('Reading the files...');
            waitbar((cnt/finish-start+1),f,WaitText);            
        end
        
    end
    %% End Nesed Function

end

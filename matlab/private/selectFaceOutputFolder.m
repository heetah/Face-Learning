function folder = selectFaceOutputFolder()
% Choose and confirm the parent location for a new private package.
folder = uigetdir(pwd, 'Select a private output folder outside the GitHub repository');
if isequal(folder, 0)
    return;
end
choice = questdlg('This folder must be private and outside the GitHub repository.', ...
    'Private output folder', 'Continue', 'Cancel', 'Cancel');
if ~strcmp(choice, 'Continue')
    folder = 0;
end
end

function path = resolveProjectFile(fileName)
if exist(fileName, 'file') == 2
    path = which(fileName);
    if isempty(path)
        path = fileName;
    end
    return
end

matches = dir(fullfile(projectRoot(), '**', fileName));
if isempty(matches)
    error('Project file not found: %s', fileName);
end
path = fullfile(matches(1).folder, matches(1).name);
end

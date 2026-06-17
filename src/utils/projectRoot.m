function root = projectRoot()
utilsDir = fileparts(mfilename('fullpath'));
srcDir = fileparts(utilsDir);
root = fileparts(srcDir);
end

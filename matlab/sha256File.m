function hashValue = sha256File(filePath)
%SHA256FILE Return a lowercase SHA-256 digest without recording local paths.

filePath = char(string(filePath));
fid = fopen(filePath, 'rb');
if fid < 0
    error('FaceLab:FileOpenFailed', 'Could not open the requested data package.');
end
closeFile = onCleanup(@() fclose(fid));
bytes = fread(fid, Inf, '*uint8');

digest = java.security.MessageDigest.getInstance('SHA-256');
digest.update(bytes);
digestBytes = typecast(digest.digest(), 'uint8');
hashValue = lower(reshape(dec2hex(digestBytes, 2).', 1, []));
end

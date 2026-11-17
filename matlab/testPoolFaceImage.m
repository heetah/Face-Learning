% Synthetic check for the fixed RGB pooling and row-major feature order.
blockCodes = reshape(mod(0:1023, 251), [32, 32]);
imageValues = kron(blockCodes, ones(20, 20));
syntheticImage = repmat(uint8(imageValues), 1, 1, 3);

actual = poolFaceImage(syntheticImage);
expected = reshape(double(blockCodes).' / 255, 1, 1024);
assert(isequal(size(actual), [1, 1024]));
assert(max(abs(actual - expected)) < 1e-12);
fprintf('Synthetic pooling check passed: shape and row-major order are correct.\n');

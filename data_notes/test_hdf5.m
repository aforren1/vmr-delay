startloc = struct('dat',[1,1,1,3], 'lab', [1,1,1,4], 'bar', struct('a', 3, 'b', "fuhh"));
save("-hdf5", "train.h5", "-struct", "startloc");

save("-mat7-binary", "train.mat", "-struct", "startloc");
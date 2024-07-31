pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";

template CheckRoot(n) {
    signal input leaves[2**n];
    signal output root;

    var N = 2**n; // how many hashes we will do, x + x/2 + x/4 ... where x = 2**n

    component components[N];
    
    for(var i = 0; i < 2**n; i+=2) {
            // apply hash to leaves
            components[i/2] = Poseidon(2);
            components[i/2].ins[0] <== leaves[i];
            components[i/2].ins[1] <== leaves[i + 1];
    }

	var j=0;
	for(var i = n+1; i < N; i++) {
            // apply hash to leaves
            components[i] = Poseidon(2);
            components[i].ins[0] <== components[j].outs[0]; 
            components[i].ins[1] <== components[j+1].outs[0]; 
	    j+=2;
    }
      root <== components[N-1].outs[0];
}


template MerkleTreeInclusionProof(n) {
   signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    component hashers[n];
    component mux[n];

    signal levelHashes[n + 1];
    levelHashes[0] <== leaf;

    for (var i = 0; i < n; i++) {
        // Should be 0 or 1
        path_index[i] * (1 - path_index[i]) === 0;

        hashers[i] = Poseidon(2);
        mux[i] = MultiMux1(2);

        mux[i].c[0][0] <== levelHashes[i];
        mux[i].c[0][1] <== path_elements[i];

        mux[i].c[1][0] <== path_elements[i];
        mux[i].c[1][1] <== levelHashes[i];

        mux[i].s <== path_index[i];
        hashers[i].inputs[0] <== mux[i].out[0];
        hashers[i].inputs[1] <== mux[i].out[1];

        levelHashes[i + 1] <== hashers[i].out;
    }

    root <== levelHashes[n];
}
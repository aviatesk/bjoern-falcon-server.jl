using Pkg, Conda


pypkgs = ["bjoern", "falcon"]

@info "installing Python packages ...: $(join(pypkgs, ' '))"
Conda.add(pypkgs; channel = "conda-forge")

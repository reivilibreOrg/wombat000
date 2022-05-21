{
  description = "Example";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.poetry2nix.url = "github:nix-community/poetry2nix";

  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    {
      # Nixpkgs overlay providing the application
      overlay = nixpkgs.lib.composeManyExtensions [
        poetry2nix.overlay
        (final: prev: {
          # The application
          wombat000 = prev.poetry2nix.mkPoetryApplication {

            projectDir = ./.;
            overrides = prev.poetry2nix.overrides.withDefaults (self: super: {

              cattrs =
                let
                  drv = super.cattrs;
                in
                if drv.version == "22.1.0" then
                  drv.overridePythonAttrs
                    (old: {
                      # 1.10.0 (and 22.1.0) contains a pyproject.toml that requires a pre-release Poetry
                      # We can avoid using Poetry and use the generated setup.py
                      preConfigure = old.preConfigure or "" + ''
                        rm pyproject.toml
                      '';
                    })
                else drv;

#                 exceptiongroup = super.exceptiongroup.overridePythonAttrs (old: {
#                   # 'No module named flit_scm' for sdist
#                   # workaround https://github.com/nix-community/poetry2nix/issues/568
#                   buildInputs = old.buildInputs or [ ] ++ [ self.python.pkgs.flit-scm ];
#                 });

            });

          };
        })
      ];
    } // (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        };
      in
      {
        apps = {
          wombat000 = pkgs.wombat000;
        };

        defaultApp = pkgs.wombat000;
      }));
}

{
  inputs = {};

  outputs = _: rec {
    flakeModule = ./flake-module;
    flakeModules = {
      yanc = flakeModule;
      default = flakeModule;
    };
  };
}

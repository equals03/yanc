args: {
  options = {
  };
  config = {
    _module.args = {
      yanc-lib = import ../lib args;
    };
  };

  imports = [
    ./builders
    ./channels
    ./homes
    ./hosts
    ./targets

    ./realised.nix
    ./fluent.nix
  ];
}

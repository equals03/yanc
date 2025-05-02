## YANC
Yet. Another. Nixos. Configurator.  
[(☝️ Seemed like a ~~good~~ name at the time.)](https://martinfowler.com/bliki/TwoHardThings.html)

YANC is a personal project designed to streamline Nix configurations while deepening my understanding of the Nix language.

Built as a module for the excellent [flake-parts](https://github.com/hercules-ci/flake-parts) framework, YANC provides a structured approach to managing NixOS and other Nix-based configurations. It’s a work in progress, driven by a desire to simplify and organize my own setups.


> [!NOTE]  
> This project is under active development. Documentation and examples are incomplete, and some features may be experimental. If you're exploring YANC, proceed with caution and expect some rough edges. Feedback and contributions are welcome!

### Top-Level Options

The module defines options under the `yanc` namespace, which is used to configure targets and hosts, along with their settings.

#### `yanc.targets`

- **Description**: Defines a set of targets, where each target represents a logical grouping of hosts or systems. A target can specify shared modules, system-specific configurations, and special arguments that apply to its hosts. This option is useful for organizing hosts into categories (e.g., "production", "staging") and applying common configurations.
- **Type**: `attrsOf target-type` (an attribute set where each value is a `target-type` submodule).
- **Default**: `{}`
- **Example**:
  ```nix
  yanc.targets = {
    production = {
      name = "production";
      modules = [ ./modules/common.nix ];
      specialArgs = { environment = "prod"; };
      perSystem = {
        x86_64-linux = {
          modules = [ ./modules/prod-x86.nix ];
          specialArgs = { arch = "x86"; };
        };
      };
      hosts = {
        server1 = {
          system = "x86_64-linux";
          modules = [ ./hosts/server1.nix ];
        };
      };
    };
  };
  ```
  In this example, a `production` target is defined with common modules, system-specific configurations for `x86_64-linux`, and a host named `server1`.

#### `yanc.settings.targets.path`

- **Description**: Specifies the filesystem path where target-specific configuration files are stored. The module looks for files like `<path>/<target-name>.nix` or directories like `<path>/<target-name>/` to automatically include as modules for each target. This allows for externalized configuration files.
- **Type**: `path`
- **Default**: `${self}/targets` (where `self` is the root of the flake or project directory).
- **Example**:
  ```nix
  yanc.settings.targets.path = /etc/nix-config/targets;
  ```
  This sets the target configuration directory to `/etc/nix-config/targets`. If a target named `staging` is defined, the module will look for `/etc/nix-config/targets/staging.nix` or `/etc/nix-config/targets/staging/`.

#### `yanc.settings.hosts.path`

- **Description**: Specifies the filesystem path where host-specific configuration files are stored. The module searches for files like `<path>/<host-name>.nix`, `<path>/<system>/<host-name>.nix`, or directories like `<path>/<host-name>/` or `<path>/<system>/<host-name>/`. This allows for host configurations to be organized by name or system architecture.
- **Type**: `path`
- **Default**: `${self}/hosts`
- **Example**:
  ```nix
  yanc.settings.hosts.path = ./configs/hosts;
  ```
  This sets the host configuration directory to `./configs/hosts`. For a host named `server1` with system `x86_64-linux`, the module might include `./configs/hosts/x86_64-linux/server1.nix`.

---

### `target-type` Submodule Options

The `target-type` submodule defines the structure for each target under `yanc.targets`. It includes options for configuring modules, system-specific settings, special arguments, and hosts.

#### `yanc.targets.<name>.name`

- **Description**: Specifies the name of the target. This is an internal, read-only option that defaults to the attribute name of the target in the `yanc.targets` attribute set. It is used internally to reference the target.
- **Type**: `str`
- **Default**: The attribute name of the target (e.g., `production` for `yanc.targets.production`).
- **Internal**: `true`
- **ReadOnly**: `true`
- **Example**:
  ```nix
  yanc.targets.staging.name = "staging"; # Automatically set, cannot be overridden
  ```

#### `yanc.targets.<name>.modules`

- **Description**: A list of Nix modules to be included for the target. These modules are applied to all hosts within the target, providing shared configuration (e.g., common packages, services). Modules can be paths, attribute sets, or other valid Nix module definitions.
- **Type**: `uniqueListOf module` (a list of unique Nix modules).
- **Default**: `[]`
- **Example**:
  ```nix
  yanc.targets.dev.modules = [
    ./modules/common.nix
    { environment.systemPackages = [ pkgs.vim ]; }
  ];
  ```
  This includes a module from `./modules/common.nix` and an inline module that adds `vim` to the system packages for the `dev` target.

#### `yanc.targets.<name>.perSystem`

- **Description**: Allows system-specific configurations for the target. This is an attribute set where each key is a system (e.g., `x86_64-linux`) and each value is a submodule with `modules` and `specialArgs`. It enables tailoring configurations to specific architectures or platforms.
- **Type**: `lazyAttrsOf (submodule { modules, specialArgs })`
- **Default**: An attribute set with empty configurations for each system in `cfg.systems`.
- **Example**:
  ```nix
  yanc.targets.prod.perSystem = {
    x86_64-linux = {
      modules = [ ./modules/prod-x86.nix ];
      specialArgs = { kernel = "linux-5.15"; };
    };
    aarch64-linux = {
      modules = [ ./modules/prod-arm.nix ];
    };
  };
  ```
  This defines system-specific modules and arguments for `x86_64-linux` and `aarch64-linux` in the `prod` target.

#### `yanc.targets.<name>.perSystem.<system>.modules`

- **Description**: A list of modules specific to the given system within the target. These modules are applied only to hosts running the specified system, allowing for architecture-specific configurations.
- **Type**: `uniqueListOf module`
- **Default**: `[]`
- **Example**:
  ```nix
  yanc.targets.test.perSystem.x86_64-linux.modules = [
    ./modules/test-x86.nix
  ];
  ```
  This includes a module for the `x86_64-linux` system in the `test` target.

#### `yanc.targets.<name>.perSystem.<system>.specialArgs`

- **Description**: Extra arguments passed to the modules for the given system. These arguments can be used to customize module behavior based on system-specific requirements.
- **Type**: `deepMergedAttrsOf raw` (an attribute set that is deeply merged).
- **Default**: `{}`
- **Example**:
  ```nix
  yanc.targets.test.perSystem.x86_64-linux.specialArgs = {
    arch = "x86";
    debug = true;
  };
  ```
  This passes `arch` and `debug` as arguments to modules for `x86_64-linux` in the `test` target.

#### `yanc.targets.<name>.specialArgs`

- **Description**: Extra arguments passed to all modules of the target, regardless of system. These are useful for defining target-wide parameters (e.g., environment variables, flags).
- **Type**: `deepMergedAttrsOf raw`
- **Default**: `{}`
- **Example**:
  ```nix
  yanc.targets.staging.specialArgs = {
    env = "staging";
    logLevel = "debug";
  };
  ```
  This passes `env` and `logLevel` to all modules in the `staging` target.

#### `yanc.targets.<name>.hosts`

- **Description**: Defines the hosts that belong to the target. Each host is a `host-type` submodule, allowing for host-specific configurations such as system type, modules, and metadata.
- **Type**: `lazyAttrsOf host-type`
- **Default**: `{}`
- **Example**:
  ```nix
  yanc.targets.prod.hosts = {
    web1 = {
      system = "x86_64-linux";
      modules = [ ./hosts/web1.nix ];
      meta = { role = "web"; };
    };
    db1 = {
      system = "x86_64-linux";
      modules = [ ./hosts/db1.nix ];
    };
  };
  ```
  This defines two hosts, `web1` and `db1`, in the `prod` target with their respective configurations.

---

### `host-type` Submodule Options

The `host-type` submodule defines the structure for each host under `yanc.targets.<name>.hosts`.

#### `yanc.targets.<name>.hosts.<host>.name`

- **Description**: Specifies the name of the host. This defaults to the attribute name of the host in the `hosts` attribute set and is used to reference the host in configurations.
- **Type**: `str`
- **Default**: The attribute name of the host (e.g., `web1` for `yanc.targets.prod.hosts.web1`).
- **Example**:
  ```nix
  yanc.targets.prod.hosts.web1.name = "web1"; # Automatically set
  ```

#### `yanc.targets.<name>.hosts.<host>.system`

- **Description**: Specifies the system architecture or platform for the host (e.g., `x86_64-linux`, `aarch64-linux`). This determines which system-specific configurations and modules are applied.
- **Type**: `str`
- **Default**: `"x86_64-linux"`
- **Example**:
  ```nix
  yanc.targets.prod.hosts.web1.system = "aarch64-linux";
  ```
  This sets the system for `web1` to `aarch64-linux`.

#### `yanc.targets.<name>.hosts.<host>.modules`

- **Description**: A list of Nix modules specific to the host. These modules define host-specific configurations, such as services, packages, or settings.
- **Type**: `uniqueListOf module`
- **Default**: `[]`
- **Example**:
  ```nix
  yanc.targets.prod.hosts.web1.modules = [
    ./hosts/web1.nix
    { services.nginx.enable = true; }
  ];
  ```
  This includes a module from `./hosts/web1.nix` and an inline module enabling Nginx for `web1`.

#### `yanc.targets.<name>.hosts.<host>.specialArgs`

- **Description**: Extra arguments passed to the host’s modules. These can be used to customize module behavior for the specific host.
- **Type**: `deepMergedAttrsOf raw`
- **Default**: `{}`
- **Example**:
  ```nix
  yanc.targets.prod.hosts.web1.specialArgs = {
    domain = "example.com";
    port = 8080;
  };
  ```
  This passes `domain` and `port` as arguments to the modules for `web1`.

#### `yanc.targets.<name>.hosts.<host>.meta`

- **Description**: An attribute set for storing metadata about the host. This can include arbitrary information such as roles, tags, or other descriptive data used for documentation or external tools.
- **Type**: `deepMergedAttrsOf raw`
- **Default**: `{}`
- **Example**:
  ```nix
  yanc.targets.prod.hosts.web1.meta = {
    role = "web";
    location = "us-east";
    priority = 1;
  };
  ```
  This attaches metadata to `web1`, indicating its role, location, and priority.

---

### Notes on Usage

- **Automatic Module Inclusion**: The module automatically includes configuration files from the paths specified in `yanc.settings.targets.path` and `yanc.settings.hosts.path`. For example, for a target named `staging`, it looks for `${yanc.settings.targets.path}/staging.nix` or `${yanc.settings.targets.path}/staging/`. Similarly, for a host named `server1` with system `x86_64-linux`, it checks paths like `${yanc.settings.hosts.path}/x86_64-linux/server1.nix`.
- **Module Composition**: The `modules` options at the target, per-system, and host levels allow for flexible composition of configurations. Modules are combined and applied in a way that respects Nix’s module system, enabling modular and reusable configurations.
- **Special Arguments**: The `specialArgs` options provide a way to pass custom parameters to modules, which is useful for parameterizing configurations without hardcoding values.
- **Deep Merging**: The `deepMergedAttrsOf raw` type ensures that attribute sets in `specialArgs` and `meta` are merged recursively, allowing for incremental configuration updates.


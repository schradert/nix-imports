{
  description = "Import utilities";
  inputs.lib.url = github:nix-community/nixpkgs.lib;
  outputs = {lib, ...}: {
    lib = with lib.lib; rec {
      imports = {
        # List absolute path of files in <root> that satisfy <f>
        filter = f: root:
          trivial.pipe root [
            builtins.readDir
            (attrsets.filterAttrs f)
            builtins.attrNames
            (builtins.map (file: root + "/${file}"))
          ];
        # List directories in <root>
        dirs = imports.filter (_: type: type == "directory");
        # List .nix files in <root>
        files = imports.filter (name: type: type == "regular" && builtins.match ".+\.nix$" name != null);
        # Recursively list all .nix files in <_dirs>
        everything = let
          filesAndDirs = root: [
            (imports.files root)
            (builtins.map imports.everything (imports.dirs root))
          ];
        in
          _dirs: trivial.pipe _dirs [lists.toList (builtins.map filesAndDirs) lists.flatten];
        # Filter out <exclude> paths from "everything" in <roots>
        everythingBut = roots: exclude: builtins.filter (_path: builtins.all (prefix: ! path.hasPrefix prefix _path) exclude) (imports.everything roots);
      };
    };
  };
}

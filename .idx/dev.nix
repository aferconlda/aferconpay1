{ pkgs, ... }: {
  channel = "stable-23.11";

  packages = [
    pkgs.flutter
    pkgs.dart
    (pkgs.android-compose {
      sdk-version = "33";
      build-tools-version = "33.0.2";
      cmdline-tools-version = "11.0";
      platform-tools-version = "34.0.5";
    })
  ];

  env = {
    WEBDEV_SERVE_ARGS = "--tls-cert-chain /ide/host/certs/devenv.cert.pem --tls-cert-key /ide/host/certs/devenv.key.pem";
    ANDROID_HOME = "${pkgs.android-compose}/share/android-sdk";
    ANDROID_SDK_ROOT = "${pkgs.android-compose}/share/android-sdk";
  };

  idx = {
    extensions = [
      "dart-code.flutter"
      "dart-code.dart-code"
    ];

    previews = {
      enable = true;
      previews = {
        web = {
          manager = "flutter";
        };
        android = {
          manager = "flutter";
        };
      };
    };

    workspace = {
      onStart = {
        accept-licenses = "yes | ${pkgs.android-compose}/bin/sdkmanager --licenses";
      };
    };
  };
}

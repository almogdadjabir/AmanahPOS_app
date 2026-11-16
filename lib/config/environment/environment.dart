enum Flavor { dev, prod }

const String devBaseURL = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://192.168.1.168:8000/',
);

/// Debug-only HTTP proxy (Proxyman listens on 9090). Pass
/// `--dart-define=PROXY=` to turn it off.
const String debugProxy = String.fromEnvironment(
  'PROXY',
  defaultValue: '192.168.1.168:9090',
);
const String prodBaseURL = 'https://api.amanapos.com/';

const double mobileHeight = 932.0;
const double mobileWidth = 430.0;
const double tabletHeight = 1366.0;
const double tabletWidth = 1024.0;

Flavor? selectedEnv;

void setEnv(Flavor? env) => selectedEnv = env;

Flavor? get env => selectedEnv;

String get baseUrl {
  switch (selectedEnv) {
    case Flavor.prod:
      return devBaseURL;
    case Flavor.dev:
      return devBaseURL;
    default:
      return devBaseURL;
  }
}
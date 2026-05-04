enum Flavor { dev, prod }

const String devBaseURL = 'http://172.16.10.51:8080/';
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
      return prodBaseURL;
    case Flavor.dev:
      return devBaseURL;
    default:
      return devBaseURL;
  }
}

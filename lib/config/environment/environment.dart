enum Flavor { dev, staging, prod }

const String stageBaseURL = 'https://baraka-app-api-staging.uz-pay-dev.ox.one/';
const String devBaseURL = 'http://192.168.1.150:8080/';
const String prodBaseURL = 'https://baraka-app-api-production.uz-pay-prod.ox.one/';

const String redmineURL =
    'https://oxigen.oxinus.holdings/issues.json';
const String redmineAPIKey =
    '32c569f317dc69fd142320b56c4367f4cdb98ab3';

const double mobileHeight = 932.0;
const double mobileWidth = 430.0;
const double tabletHeight = 1366.0;
const double tabletWidth = 1024.0;

Flavor? selectedEnv;

void setEnv(Flavor? env) => selectedEnv = env;

Flavor? get env => selectedEnv;

String get baseUrl {
  switch (selectedEnv) {
    case Flavor.staging:
      return stageBaseURL;
    case Flavor.prod:
      return prodBaseURL;
    case Flavor.dev:
      return devBaseURL;
    default:
      return devBaseURL;
  }
}

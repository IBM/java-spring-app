const zapProxyAddress = process.env.ZAP_PROXY || 'http://localhost:8080' ;
const seleniumAddress = process.env.SELENIUM_ADDRESS || 'http://localhost:4444/wd/hub' ;

exports.config = {
  getPageTimeout: 120000,
  seleniumAddress: seleniumAddress,
  specs: ['../loginAndBrowsePages.js'],
  capabilities: {
    'browserName': 'chrome',
    'pageLoadStrategy' :'none',
    'chromeOptions': {
      'args': ['--headless','--no-sandbox', '--disable-gpu', '--disable-extensions', '--disable-dev-shm-usage',`--proxy-server=${zapProxyAddress}`]
    },
    'acceptInsecureCerts': true,
  }
}
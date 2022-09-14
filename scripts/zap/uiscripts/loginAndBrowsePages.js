
const username = process.env.TEST_USER
const testEnvironmentUrl = process.env.TEST_ENV || "https://test.cloud.ibm.com"

const driver = browser.driver
const EC = protractor.ExpectedConditions;
browser.ignoreSynchronization = true;

const WAIT_ONE_MINUTE = 60 * 1000

afterAll(function () {
    driver.quit();
});


describe('Browse Security Advisor pages to create sites list for zap', function () {

    //browse catalog page without login
    it('Browse page to homepage', function () {
        const Url = `${process.env.APP_URL}/`
        driver.get(Url);
        driver.sleep(10*1000); //wait 10 sec
    }, WAIT_ONE_MINUTE)

    it('Browse page to flightbooking page', function () {
        const Url = `${process.env.APP_URL}/flightbooking`
        driver.get(Url);
        driver.sleep(10*1000); //wait 10 sec
    }, WAIT_ONE_MINUTE)


}, WAIT_ONE_MINUTE)




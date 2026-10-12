@isTest
private class NetSuiteProductWrapperTest {

    @isTest
    static void testFieldsCanBeSetAndRead() {
        NetSuiteProductWrapper w = new NetSuiteProductWrapper();

        w.id = '123';
        w.itemid = 'SKU-123';
        w.displayname = 'Test Sunglasses';
        w.description = 'A test product';
        w.isinactive = 'F';
        w.unitprice = '19.99';
        w.globalSku = 'T';
        w.sellgoodrComSku = 'T';
        w.sellgoodrCaSku = 'F';
        w.productStage = 'Active';
        w.collection = 'Summer';
        w.replen = 'T';
        w.merchandiseDepartment = 'Eyewear';
        w.merchandiseClass = 'Sunglasses';
        w.frameColor = 'Black';
        w.frameColorLightness = 'Dark';
        w.lensFinishColor = 'Smoke';
        w.lensColorFinishLightness = 'Medium';
        w.b2bLaunchDate = '01/15/2024';
        w.launchDate = '02/01/2024';
        w.launchYear = '2024';
        w.ipWeight = '1.5';
        w.ipLength = '10.2';
        w.ipWidth = '5.1';
        w.ipHeight = '3.0';
        w.countryOfOrigin = 'CN';
        w.htsCodeItem = '9004.10.0000';
        w.productType = 'Sunglasses';
        w.upc = '000123456789';

        Test.startTest();
        // No behavior to exercise beyond construction/field access, so just
        // reassert everything round-trips as set - this is what drives
        // coverage on the class's implicit constructor and fields.
        Test.stopTest();

        System.assertEquals('123', w.id);
        System.assertEquals('SKU-123', w.itemid);
        System.assertEquals('Test Sunglasses', w.displayname);
        System.assertEquals('A test product', w.description);
        System.assertEquals('F', w.isinactive);
        System.assertEquals('19.99', w.unitprice);
        System.assertEquals('T', w.globalSku);
        System.assertEquals('T', w.sellgoodrComSku);
        System.assertEquals('F', w.sellgoodrCaSku);
        System.assertEquals('Active', w.productStage);
        System.assertEquals('Summer', w.collection);
        System.assertEquals('T', w.replen);
        System.assertEquals('Eyewear', w.merchandiseDepartment);
        System.assertEquals('Sunglasses', w.merchandiseClass);
        System.assertEquals('Black', w.frameColor);
        System.assertEquals('Dark', w.frameColorLightness);
        System.assertEquals('Smoke', w.lensFinishColor);
        System.assertEquals('Medium', w.lensColorFinishLightness);
        System.assertEquals('01/15/2024', w.b2bLaunchDate);
        System.assertEquals('02/01/2024', w.launchDate);
        System.assertEquals('2024', w.launchYear);
        System.assertEquals('1.5', w.ipWeight);
        System.assertEquals('10.2', w.ipLength);
        System.assertEquals('5.1', w.ipWidth);
        System.assertEquals('3.0', w.ipHeight);
        System.assertEquals('CN', w.countryOfOrigin);
        System.assertEquals('9004.10.0000', w.htsCodeItem);
        System.assertEquals('Sunglasses', w.productType);
        System.assertEquals('000123456789', w.upc);
    }

    @isTest
    static void testDefaultsAreNullWhenUnset() {
        NetSuiteProductWrapper w = new NetSuiteProductWrapper();

        System.assertEquals(null, w.id);
        System.assertEquals(null, w.itemid);
        System.assertEquals(null, w.unitprice);
        System.assertEquals(null, w.launchYear);
        System.assertEquals(null, w.upc);
    }
}
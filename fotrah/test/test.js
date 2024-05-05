const assert = require('assert');
const firebase = require('@firebase/testing');
const my_project_id = 'fotarh-956e1';

describe("Our app", function() {
    it("Understands basic addition", function() {
        assert.equal(2 + 2, 4);
    });

    it("Can read from the database", function(done) {
        const db = firebase.initializeTestApp({ projectId: my_project_id }).firestore();
        const testDoc = db.collection("bill").doc("testDoc");
        testDoc.get().then(() => {
            done();
        }).catch((error) => {
            done(error);
        });
    });
});

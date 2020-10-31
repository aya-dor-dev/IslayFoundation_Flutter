const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp()

exports.updateAuction = functions.firestore.document('auctions/{auctionId}').onUpdate((change, context) => {
    const auction = change.after.data();
    const promises = [];
    change.before.ref.update()
    auction.auctioneer.get().then(auctioneerSnap => {
        const auctioneer = auctioneerSnap.data();
        auction.bottles.forEach(bottle => {
            promises.push(admin.firestore().doc(bottle.path).get())
        });
    
        Promise.all(promises).then(bottleSnaps => {
            var fees = 0;
            bottleSnaps.forEach(snap => {
                const bottle = snap.data();
                const sold = bottle.sold || 0;
                const reserve = bottle.reserve || 0;
                if (sold || 0 >= reserve) {
                    auction.investment += data.cost;
                }
                
                auction.returnOnInvestment += sold;
                fees += auctioneer.listing_fee;
                if (reserve > 0) {
                    fees += auctioneer.reserve_fee;
                }
            })

            auction.revenue = returnOnInvestment - fees;

            return change.after.update();
        }).catch(error => {
            console.log("Error " + error);
            return null;
        });
    }).catch(error => {
        console.log("Error " + error);
        return null;
    });
})

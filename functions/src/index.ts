const isLive = true;

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

if (isLive) {
    admin.initializeApp();
} else {
    const serviceAccount = require("../../islay-foundation-firebase-creds.json");

    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
    });
}

/**
 * Called when a new auction is added to the database
 * will call the updateAuction method to initialize investment values
 */
export const onAuctionCreated = functions.firestore.document('auctions/{auctionId}').onCreate(async (snapshot, context) => {
    return updateAuction(snapshot);
})

/** 
 * Called when an auction has been updated
 */
export const onAuctionUpdate = functions.firestore.document('auctions/{auctionId}').onUpdate(async (change, context) => {
    const auction = change.after.data()
    const old = change.before.data()
    if (!auction || !old) return null;

    if (auction.bottles.length === old.bottles.length) {   
        console.log('Skipping update');
        return null;
    } 

    return updateAuction(change.after);
})

/** 
 * Called when an owner has been updated
 */
export const onOwnerUpdate = functions.firestore.document('owners/{ownerId}').onUpdate(async (change, context) => {
    const owner = change.after.data()
    const old = change.before.data()
    if (!owner || !old) return null;

    if (owner.bottles.length === old.bottles.length) {   
        console.log('Skipping update');
        return null;
    } 

    return calculateOwnerInvestment(change.after);
})

/**
 * Called when a new bottle is added to the database.
 * Calculated bottles fees
 * Updates owner and adds the new bottle reference to the owners bottles list
 * Updates owners investment
 * Updates auction and adds the new bottle reference to the auctions bottles list
 * Update auctions investment
 */
export const onBottleCreated = functions.firestore.document('bottles/{bottleId}').onCreate(async (snapshot, context) => {
    const bottle = snapshot.data()
    if (!bottle) return 
    
    const ownerRef = (bottle.owner as FirebaseFirestore.DocumentReference)
    const auctionRef = (bottle.auction as FirebaseFirestore.DocumentReference)
    const updates = [];

    try {
        // Load owner
        const ownerSnap = await ownerRef.get()
        const owner = ownerSnap.data()
        if (!owner) return 
        owner.bottles.push(snapshot.ref)
        // Update owner values
        updates.push(ownerRef.update({'bottles': owner.bottles}))

        // Load auction
        const auctionSnap = await auctionRef.get()
        const auction = auctionSnap.data()
        if (!auction) return 
        auction.bottles.push(snapshot.ref)
        // update auction values
        updates.push(auctionRef.update({'bottles': auction.bottles}))
    } catch(error) {
        console.log(error)
        return null
    }

    return Promise.all(updates)
})

/**
 * Called when a bottle is deleted to the database.
 * Updates owner and removes the bottle reference to the owners bottles list
 * Updates auction and removes the bottle reference to the auctions bottles list
 */
export const onBottleDeleted = functions.firestore.document('bottles/{bottleId}').onDelete(async (snapshot, context) => {
    const bottle = snapshot.data()

    console.log(`Deleted bottle id: ${snapshot.id}`)
    
    if (!bottle) return 
    
    const ownerRef = (bottle.owner as FirebaseFirestore.DocumentReference)
    const auctionRef = (bottle.auction as FirebaseFirestore.DocumentReference)
    const updates = []

    try {
        const ownerSnap = await ownerRef.get()
        const owner = ownerSnap.data()
        if (!owner) return 
        owner.bottles = owner.bottles.filter((element: FirebaseFirestore.DocumentReference) => {
            return element.id !== snapshot.id
        })

        updates.push(ownerRef.update({'bottles': owner.bottles}));

        const auctionSnap = await auctionRef.get()
        const auction = auctionSnap.data()
        if (!auction) return 
        auction.bottles = auction.bottles.filter((element: FirebaseFirestore.DocumentReference) => {
            return element.id !== snapshot.id
        })
        updates.push(auctionRef.update({'bottles': auction.bottles}))
    } catch(error) {
        console.log(error)
        return null
    }

    return Promise.all(updates)
})

/**
 * Called when a bottle's data is updated
 * Recalculates revenue
 * Recalculates relevant auction's investment and revenue
 * Recalculates relevant owners's investment
 */
export const onBottleUpdate = functions.firestore.document('bottles/{bottleId}').onUpdate(async (change, context) => {
    const bottle = change.after.data()
    const old = change.before.data()

    if (!bottle || !old) return null;
    if (bottle.cost === old.cost && 
        bottle.reserve === old.reserve &&
        bottle.sold === old.sold) {   
        console.log('Skipping update');
        return null;
    } 

    // Recalculate revenue
    const revenueCalculation = calculateBottleRevenue(change.after)
    if (revenueCalculation) {
        try {
            await revenueCalculation
        } catch(error) {
            console.log(error)
            return null
        }
    }

    const auctionSnap = await bottle.auction.get()
    const ownerSnap = await bottle.owner.get()

    const sold = bottle.sold;
    if (sold !== null && sold >= 0) {
        const reserve = bottle.reserve;
        if (reserve && sold === 0) {
            const owner = ownerSnap.data()!!
            owner.bottles = owner.bottles.filter((element: FirebaseFirestore.DocumentReference) => {
                return element.id !== change.after.id
            })

            await (bottle.owner as FirebaseFirestore.DocumentReference).update({'bottles': owner.bottles})
        }
    }

    const promises = []
    promises.push(updateAuction(auctionSnap))
    promises.push(calculateOwnerInvestment(ownerSnap))

    return Promise.all(promises)
})

/**
 * Calculates fees and revenue for a given bottle
 * @param bottleSnapshot Firestore snapshot of the bottle 
 */
async function calculateBottleRevenue(bottleSnapshot: FirebaseFirestore.DocumentSnapshot) {
    const bottleId = bottleSnapshot.id
    console.log(`Beginning update for Bottle: ${bottleId}`)
    const bottle = bottleSnapshot.data()

    if (!bottle) {
        console.log(`Auction ${bottleSnapshot.id} doesn't exist`)
        return null;
    }

    let auctioneer: FirebaseFirestore.DocumentData
    try {
        const auctionSnapshot = (await admin.firestore().doc(bottle.auction.path).get())
        const auction = auctionSnapshot.data();
        if (!auction) throw new Error(`Cannot load auction with id ${auctionSnapshot.id}`)

        const auctioneerSnapshot = (await admin.firestore().doc(auction.auctioneer.path).get())
        auctioneer = auctioneerSnapshot.data()!!;
        if (!auctioneer) throw new Error(`Cannot load auctioneer with id ${auctioneerSnapshot.id}`)
    } catch (error) {
        console.log(error);
        return null;
    }

    const sold = bottle.sold;
    if (sold !== null && sold >= 0) {
        let fees = (auctioneer.listing_fee as number);
        const reserve = bottle.reserve;
        let revenue = 0;

        if (reserve) {
            fees += (auctioneer.reserve_fee as number);
            if (sold > 0) {
                revenue = sold - bottle.cost;
            }
        } else {
            revenue = sold - bottle.cost;
        }

        if (auctioneer.additional_fees_percentage) {
            let additionalFeesPercentage = (auctioneer.additional_fees_percentage as number);
            fees += sold * additionalFeesPercentage;
        }

        revenue -= fees;
        return bottleSnapshot.ref.update({fees, revenue});
    }

    return null
}

/**
 * Update auctions investment, fees, return & revenue
 * @param auctionSnapshot Relevant auction's snapshot
 */
async function updateAuction(auctionSnapshot: FirebaseFirestore.DocumentSnapshot) {
    console.log(`Beginning update for Auction: ${auctionSnapshot.id}`)
    
    const auction = auctionSnapshot.data()

    if (!auction) {
        console.log(`Auction ${auctionSnapshot.id} doesn't exist`)
        return null;
    }

    const bottles: any[] = []
    let auctioneer: FirebaseFirestore.DocumentData

    try {
        auctioneer = (await admin.firestore().doc(auction.auctioneer.path).get()).data()!!

        const promises: any[] = []
        auction.bottles.forEach((bottle: admin.firestore.DocumentReference) => {
            promises.push(admin.firestore().doc(bottle.path).get());
        });

        const bottleSnaps = await Promise.all(promises);
        bottleSnaps.forEach((snap: admin.firestore.DocumentSnapshot) => {
            bottles.push(snap.data());
        })
    } catch (error) {
        console.log(error);
        return null;
    }

    let investment = 0;
    let returnOnInvestment = 0;
    let revenue = 0;
    let fees = 0;

    bottles.forEach(bottle => {
        const cost = bottle.cost;
        const sold = bottle.sold;
        const reserve = bottle.reserve;
        if (reserve !== null) {
            if (sold !== null) {
                fees += auctioneer.reserve_fee;
                if (sold > 0) {
                    investment += cost;
                }
            } else {
                investment += cost;
            }
        } else {
            investment += cost;
        }

        if (sold !== null) {
            fees += auctioneer.listing_fee;

            if (auctioneer.additional_fees_percentage) {
                let additionalFeesPercentage = (auctioneer.additional_fees_percentage as number);
                fees += sold * additionalFeesPercentage;
            }

            returnOnInvestment += sold;
            revenue += bottle.revenue;
        }
    })

    console.log(`Updating auction with investment: ${investment}, returnOnInvestment: ${returnOnInvestment}, fees: ${fees}, revenue: ${revenue}`)

    const change = {investment, returnOnInvestment, fees, revenue}
    return auctionSnapshot.ref.update(change);  
}

/**
 * Calculates owners investment
 * @param ownerSnapshot relevant owner snapshot
 */
async function calculateOwnerInvestment(ownerSnapshot: FirebaseFirestore.DocumentSnapshot) {
    const owner = ownerSnapshot.data()!!
    let investment = 0

    const ownerBottlesSnapshotQueries: Promise<FirebaseFirestore.DocumentSnapshot>[] = [];
    (owner.bottles as FirebaseFirestore.DocumentReference[]).forEach((ref) => {
        ownerBottlesSnapshotQueries.push(ref.get())
    })

    const bottles = await Promise.all(ownerBottlesSnapshotQueries)
    bottles.forEach((bottleSnap) => {
        const bottle = bottleSnap.data()!!
        investment += bottle.cost
        if (bottle.reserve !== null && bottle.reserve > 0 && bottle.sold !== null && bottle.sold === 0) {
            investment -= bottle.cost
        }
    })

    return ownerSnapshot.ref.update({investment})
}

export const getAutoComplete = functions.https.onRequest(async (request, response) => {
    const res = new Set<string>();
    const query = request.query.q.toLowerCase()
    const list = await admin.firestore().collection('/bottles').select('name').get()
    list.docs.forEach(doc => { 
        const name = doc.data().name as string
        if (name.toLowerCase().startsWith(query)) res.add(name)
    })
      
    response.send(Array.from(res.values()))
})

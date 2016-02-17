/* Initialize the Stripe Cloud Module */
var Stripe = require('stripe');
Stripe.initialize('sk_test_tQioOjBZcmRij3KBcRj8Q59m');

Parse.Cloud.define("addFunds", function(request, response) { 
  // We ensure only Cloud Code can get access by using the master key.
  Parse.Cloud.useMasterKey();

  Parse.Promise.as().then(function() {
    // Now we can charge the credit card using Stripe and the credit card token.
    return Stripe.Charges.create({
      amount: 1000, // express dollars in cents 
      currency: 'usd',
      card: request.params.cardToken
    }).then(null, function(error) {
      console.log('Charging with stripe failed. Error: ' + error);
      return Parse.Promise.error('An error has occurred. Your credit card was not charged.');
    });
    
  }).then(function() {
    response.success('Success');
  }, function(error) {
    response.error(error);
  });
});

Parse.Cloud.define("createCustomer", function(request, response) {
  Stripe.Customers.create({
    card: request.params['tokenId']
  }, {
    success: function(customer) {
      response.success(customer.id);
    },
    error: function(error) {
      response.error("Error:" +error); 
    }
  })
});

Parse.Cloud.define("chargeCustomer", function(request, response) {
  Stripe.Charges.create({
    amount: request.params['amount'],
    currency: "usd",
    customer: request.params['customerId']
  }, {
    success: function(customer) {
      response.success("Success");
    },
    error: function(error) {
      response.error("Error:" +error); 
    }
  })
});

Parse.Cloud.define("recipient", function(request, response) {
	
    return Parse.Cloud.httpRequest({
    	method:"POST",
    	url: 'https://sk_test_tQioOjBZcmRij3KBcRj8Q59m:@api.stripe.com/v1/recipients?name='+request.params.firstName+'%20'+request.params.lastName+'&type=individual&card='+request.params.cardToken
    }).then(function(success) {
      console.log(success);
      response.success(success.text);
    }, function(err) {
      console.log(err);
      response.error(err.text);
    });
});

Parse.Cloud.define("cashOut", function(request, response) {
	return Parse.Cloud.httpRequest({
    	method:"POST",
    	url: 'https://sk_test_tQioOjBZcmRij3KBcRj8Q59m:@api.stripe.com/v1/transfers?currency=usd&amount='+request.params.amount+'&recipient='+ request.params.id + '&card='+ request.params.cardId
    }).then(function(httpResponse) {
        response.success(httpResponse.text);
    }, 
    function (error) {
        console.error('Console Log response: ' + error.text);
        response.error('Request failed with response ' + error.text)
    });
});

Parse.Cloud.define("refund", function(request, response) {
	var ids = request.params.idArray;
  for (var key in ids) {
    var User = Parse.Object.extend('_User'),
      user = new User({ objectId: key });
    user.fetch().then(function(user) {
      console.log(user);
      var currFunds = user.get("funds");
      console.log(currFunds);
      user.set("funds", ids[key]+currFunds);
      Parse.Cloud.useMasterKey();
      user.save().then(function(user) {
          console.log(user);
          response.success("Users updated");
      }, function(error) {
          console.log(error.txt + userId)
          response.error(error)
      });
    }, function(error) {
        console.log(error.txt + userId)
        response.error(error)
    });
  }
});

Parse.Cloud.define("winner", function(request, response) {
	var id = request.params.id;
	var newfunds = request.params.newFunds;
	
	var User = Parse.Object.extend('_User'),
    user = new User({ objectId: id });
    console.log(newfunds);
    user.set("funds", newfunds);
	Parse.Cloud.useMasterKey();
	user.save().then(function(user) {
    	console.log(newfunds);
		response.success("Funds Added");
    }, function(error) {
        console.log(error.txt + userId)
    	response.error(error)
    });
});
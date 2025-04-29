// Google Analytics Debug Script
console.log('Analytics Debug Script Loaded');

// Store the original dataLayer.push function
var originalPush = window.dataLayer.push;

// Override the push function to log events
window.dataLayer.push = function() {
    // Call the original function
    var result = originalPush.apply(this, arguments);
    
    // Log the event
    console.log('Google Analytics Event:', arguments[0]);
    
    return result;
};

// Send a test event
gtag('event', 'test_event', {
    'event_category': 'testing',
    'event_label': 'analytics_verification',
    'value': 1
});

console.log('Test event sent to Google Analytics');
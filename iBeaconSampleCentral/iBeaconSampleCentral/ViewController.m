//
//  ViewController.m
//  iBeaconSampleCentral
//
//  Created by kakegawa.atsushi on 2013/09/25.
//  Copyright (c) 2013年 kakegawa.atsushi. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface ViewController () <CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) NSUUID *proximityUUID;
@property (nonatomic) CLBeaconRegion *beaconRegion;
@property (weak, nonatomic) IBOutlet UITextView *txtview;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
        //# Estimote うまくいかない # D456894A-02F0-4CB0-8258-81C187DF45C2
        //# ｘBeacon E2C56DB5-DFFB-48D2-B060-D0F5A71096E0
        //# ｘBeacon 5A4BCFCE-174E-4BAC-A814-092E77F6B7E5
        self.proximityUUID = [[NSUUID alloc] initWithUUIDString:@"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"];
        
        self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:self.proximityUUID
                                                               identifier:@"jp.classmethod.testregion"];
        [self.locationManager startMonitoringForRegion:self.beaconRegion];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    [self sendLocalNotificationForMessage:@"Start Monitoring Region"];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    [self sendLocalNotificationForMessage:@"Enter Region"];
    
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    [self sendLocalNotificationForMessage:@"Exit Region"];
    
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if (beacons.count > 0) {
        CLBeacon *nearestBeacon = beacons.firstObject;
        
        NSString *rangeMessage;
        
        switch (nearestBeacon.proximity) {
            case CLProximityImmediate:
                rangeMessage = @"Range Immediate: ";
                break;
            case CLProximityNear:
                rangeMessage = @"Range Near: ";
                break;
            case CLProximityFar:
                rangeMessage = @"Range Far: ";
                break;
            default:
                rangeMessage = @"Range Unknown: ";
                break;
        }
        
        NSString *message = [NSString stringWithFormat:@"major:%@, minor:%@, accuracy:%f, rssi:%ld",
                             nearestBeacon.major, nearestBeacon.minor, nearestBeacon.accuracy, (long)nearestBeacon.rssi];
        [self sendLocalNotificationForMessage:[rangeMessage stringByAppendingString:message]];


        NSString *jsonstr = [NSString stringWithFormat:@"%@.json?major=%@&minor=%@&accuracy=%f&rssi=%ld",
                             [self.proximityUUID UUIDString],nearestBeacon.major, nearestBeacon.minor, nearestBeacon.accuracy, (long)nearestBeacon.rssi];
        [self getJson: jsonstr] ;
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    [self sendLocalNotificationForMessage:@"Exit Region"];
}

- (void)getJson: (NSString *)mes
{
	// request
    NSString *urlstr = [NSString stringWithFormat:@"http://beacon.ruby.iijgio.com/uumes/%@",mes];

	NSURL *url = [NSURL URLWithString:urlstr];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	NSURLResponse *response = nil;
	NSError *error = nil;
	NSData *data = [
		NSURLConnection
		sendSynchronousRequest : request
		returningResponse : &response
		error : &error
	];

	// error
	NSString *error_str = [error localizedDescription];
	if (0<[error_str length]) {
		UIAlertView *alert = [
			[UIAlertView alloc]
			initWithTitle : @"RequestError"
			message : error_str
			delegate : nil
			cancelButtonTitle : @"OK"
			otherButtonTitles : nil
		];
		[alert show];
//		[alert release];
		return;
	}

	// response
	int enc_arr[] = {
		NSUTF8StringEncoding,			// UTF-8
		NSShiftJISStringEncoding,		// Shift_JIS
		NSJapaneseEUCStringEncoding,	// EUC-JP
		NSISO2022JPStringEncoding,		// JIS
		NSUnicodeStringEncoding,		// Unicode
		NSASCIIStringEncoding			// ASCII
	};
	NSString *data_str = nil;
	int max = sizeof(enc_arr) / sizeof(enc_arr[0]);
	for (int i=0; i<max; i++) {
		data_str = [
			[NSString alloc]
			initWithData : data
			encoding : enc_arr[i]
		];
		if (data_str!=nil) {
			break;
		}
	}
    NSString *message = [NSString stringWithFormat:@"param:%@\njson:%@", mes,data_str];
    self.txtview.text = message ;
    [self sendLocalNotificationForMessage:message];
}


#pragma mark - Private methods

- (void)sendLocalNotificationForMessage:(NSString *)message
{
    UILocalNotification *localNotification = [UILocalNotification new];
    localNotification.alertBody = message;
    localNotification.fireDate = [NSDate date];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

@end

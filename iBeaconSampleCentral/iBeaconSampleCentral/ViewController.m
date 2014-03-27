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
@property (nonatomic) NSUUID *proximityUUIDmy;  // MyBeacon
@property (nonatomic) NSUUID *proximityUUIDx; // xBeacon
@property (nonatomic) CLBeaconRegion *beaconRegion;
@property (weak, nonatomic) IBOutlet UITextView *txtview;

// サンプルプログラム用
@property (nonatomic) NSString *vendorUUID;       // device_id用 myBeacon
@property (nonatomic) BOOL sendMode;              // device_id用

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // 広告トラッキング以外の用途に使用するUUID取得用メソッド
    self.vendorUUID = [[UIDevice currentDevice].identifierForVendor UUIDString];
    self.sendMode = YES ;

    // キーボードを表示させない
    self.txtview.delegate = self;
    
    if ([CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
        // iPhone/iPad App Storeのツールを利用
        // MyBeacon "00000000-8B46-1001-B000-0001C4DBB8E3"
        //# Estimote D456894A-02F0-4CB0-8258-81C187DF45C2 受信不可。uuidが違う可能性がある。
        //# ｘBeacon E2C56DB5-DFFB-48D2-B060-D0F5A71096E0 OK。リストから選択
        //# ｘBeacon 5A4BCFCE-174E-4BAC-A814-092E77F6B7E5
/*
        self.proximityUUIDmy = [[NSUUID alloc] initWithUUIDString:@"00000000-8B46-1001-B000-0001C4DBB8E3"];
        self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:self.proximityUUID
                                                     identifier:@"jp.co.hitachi-solutions.csv.mybeacon"];
        [self.locationManager startMonitoringForRegion:self.beaconRegion];
*/
        self.proximityUUIDx = [[NSUUID alloc] initWithUUIDString:@"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"];
        self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:self.proximityUUID
                                                     identifier:@"jp.co.hitachi-solutions.csv.xbeacon"];
        [self.locationManager startMonitoringForRegion:self.beaconRegion];

        self.txtview.text = [self.proximityUUID UUIDString];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonReaction:(id)sender {
    self.sendMode = YES ;
    NSLog(@"change color");
    self.txtview.backgroundColor = [UIColor whiteColor];
    [self.txtview resignFirstResponder];
}

// キーボードを表示させない
- (BOOL)textViewShouldReturn:(UITextField *)textView
{
    // ソフトウェアキーボードを閉じる
    NSLog(@"close Keyboard");
    [textView resignFirstResponder];
 
    return YES;
}

#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
	// ****************************************************************
	// * Bug Fix : http://brightechno.com/blog/archives/220
	// * 正しいビーコン監視の開始手順
	// ここでiOS7から追加された”CLLocationManager requestStateForRegion:”を呼び出し、
	// 現在自分が、iBeacon監視でどういう状態にいるかを知らせてくれるように要求します。
	[self.locationManager requestStateForRegion:self.beaconRegion];
	// ****************************************************************
    [self sendLocalNotificationForMessage:@"Start Monitoring Region"];
}

// ****************************************************************
// * Bug Fix : http://brightechno.com/blog/archives/220
// * 正しいビーコン監視の開始手順
// requestStateForRegion によって、呼び出されるdelegate
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    switch (state) {
    case CLRegionStateInside: // リージョン内にいる
        if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
            [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
        }
        break;
    case CLRegionStateOutside:
    case CLRegionStateUnknown:
    default:
        break;
    }
}
// ****************************************************************


- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    [self sendLocalNotificationForMessage:@"Enter Region"];
//    self.sendMode = NO;
    
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    [self sendLocalNotificationForMessage:@"Exit Region"];
    self.sendMode = YES;
    
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
                             nearestBeacon.major, nearestBeacon.minor, nearestBeacon.accuracy,
                             (long)nearestBeacon.rssi];
        [self sendLocalNotificationForMessage:[rangeMessage stringByAppendingString:message]];

        if (self.sendMode == YES)
        {
            NSString *rangestr;
        
            switch (nearestBeacon.proximity) {
                case CLProximityImmediate:
                    rangestr = @"Immediate";
                    break;
                case CLProximityNear:
                    rangestr = @"Near";
                    break;
                case CLProximityFar:
                    rangestr = @"Far";
                    break;
                default:
                    rangestr = @"Unknown";
                    break;
            }

            NSString *jsonstr = [NSString stringWithFormat:@"%@.json?proximity=%@&major=%@&minor=%@&accuracy=%f&rssi=%ld&device_id=%@",
                             // [self.proximityUUID UUIDString], 
                                    [nearestBeacon.proximityUUID UUIDString],
                                    rangestr,
                                    nearestBeacon.major, nearestBeacon.minor,
                                    nearestBeacon.accuracy, (long)nearestBeacon.rssi,
                                    self.vendorUUID  ];
            // NSLog(@"DEBUG:%@",jsonstr);
            [self getJson: jsonstr] ;
        }
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
		//[alert release];
		return;
	}

    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSString *recieve_time  = [jsonDictionary objectForKey:@"recieve_time"];
    NSString *uuid          = [jsonDictionary objectForKey:@"uuid"];
    NSString *major         = [jsonDictionary objectForKey:@"major"];
    NSString *minor         = [jsonDictionary objectForKey:@"minor"];
    NSString *proximity     = [jsonDictionary objectForKey:@"proximity"];
    NSString *accuracy      = [jsonDictionary objectForKey:@"accuracy"];
    NSString *rssi          = [jsonDictionary objectForKey:@"rssi"];
    NSString *deviceinfo    = [jsonDictionary objectForKey:@"deviceinfo"];
    NSString *message       = [jsonDictionary objectForKey:@"message"];
    NSString *cmd           = [jsonDictionary objectForKey:@"cmd"];
    NSString *parameter     = [jsonDictionary objectForKey:@"parameter"];
    NSString *device_id     = [jsonDictionary objectForKey:@"device_id"];
    NSString *bm_message_id = [jsonDictionary objectForKey:@"bm_message_id"];
/**************************************************************************************
 **************************************************************************************/
    //
    // 文字コードを変換する
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
    NSLog(@"retjson=%@¥n",data_str);
    //NSString *textmessage = [NSString stringWithFormat:@"param:%@\njson:%@", mes,data_str];
    NSString *textmessage = [NSString stringWithFormat:@"recieve_time:%@\nuuid:%@\nmajor:%@\nminor:%@\nproximity:%@\nacceracy:%@\nrssi:%@\ndevinfo:%@\nmessage:%@\ncmd:%@\nparameter:%@\ndevice_id:%@\nmessage_id:%@\n",
                             recieve_time  ,
                             uuid          ,
                             major         ,
                             minor         ,
                             proximity     ,
                             accuracy      ,
                             rssi          ,
                             deviceinfo    ,
                             message       ,
                             cmd           ,
                             parameter     ,
                             device_id     ,
                             bm_message_id
                             ];
    self.txtview.text = textmessage ;
    //self.sendMode = NO;

    if ( [cmd isEqualToString:@"url"]==YES )
    {
        //NSString *urlscheme = @"mailto:frank@wwdcdemo.example.com"; @"maps:" ;
        NSString *urlscheme = parameter;
        [self urlScheme: urlscheme] ;
        // [self sendLocalNotificationForMessage:textmessage];
    }
    else if ( [cmd isEqualToString:@"touch"]==YES )
    {
        self.txtview.backgroundColor = [UIColor redColor];
    }

}

- (void)urlScheme:(NSString *)url
{
    NSLog(@"url:%@",url);
    NSURL *myURL = [NSURL URLWithString: url];
    [[UIApplication sharedApplication] openURL:myURL];
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

//
//  FPViewController.m
//  FindParking
//
//  Created by Leigh McCulloch on 24/01/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#import "FPViewController.h"
#import "AdvMapView.h"
#import "HttpRequest.h"
#import "FPCarPark.h"

@interface FPViewController ()

@property (retain, nonatomic) AdvMapView *advMapView;
@property (retain, nonatomic) HttpRequest *request;

@end

@implementation FPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// setup the request utility
	self.request = [[[HttpRequest alloc] init]autorelease];
	
	// setup the adv map view
	self.advMapView = [AdvMapView viewFromNib];
	self.advMapView.delegate = self;
	self.advMapView.imagePin = [UIImage imageNamed:@"pin-parking"];
	self.advMapView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
	[self.view addSubview:self.advMapView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
	[_advMapView release];
	[_request release];
	[super dealloc];
}

#pragma mark View Functions

- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskPortrait;
}

#pragma mark AdvMapView Delegate

- (void)advMapView:(AdvMapView*)advMapView regionDidChangeAnimated:(BOOL)animated {
	NSString* url = [NSString stringWithFormat:@"http://192.168.5.6:5000/carparks/near/%f,%f/%f", self.advMapView.centerCoordinate.longitude, self.advMapView.centerCoordinate.latitude, self.advMapView.spanMeters];
	
	[self.request getJsonFromURL:url andCallback:^(NSString *url, NSDictionary *json) {
		
		NSArray* result = [json objectForKey:@"result"];
		if (!result) {
			return;
		}
		
		// add each carpark to the advMapView
		for (NSDictionary* carparkDic in result) {
			FPCarPark* carpark = [[FPCarPark alloc] initWithDictionary:carparkDic];
			[self.advMapView addItem:carpark];
		}
		
	}];
}


@end

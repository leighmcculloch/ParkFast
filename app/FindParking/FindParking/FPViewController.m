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
#import <sqlite3.h>
#import "sqlite3_latlondistkm.h"

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
	
	// create a region for Australia, and we'll limit searches to it
	CLLocationCoordinate2D australiaCentre = CLLocationCoordinate2DMake(-24.25, 133.416667);
	CLLocationDistance australiaRadius = 4100000/2; // max width 4,100km
	CLRegion *region = [[CLRegion alloc] initCircularRegionWithCenter:australiaCentre radius:australiaRadius identifier:@"Australia"];
	
	// setup the adv map view
	self.advMapView = [AdvMapView viewFromNib];
	self.advMapView.delegate = self;
	self.advMapView.region = region;
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

#define DEFAULT_FOCUS_NEARBY_DISTANCE 2000

- (void)advMapViewFocusCoordinateChanged:(AdvMapView*)advMapView {
	[self loadCarParksAtCoord:self.advMapView.focusCoordinate spanMeters:DEFAULT_FOCUS_NEARBY_DISTANCE];
}

- (void)advMapView:(AdvMapView*)advMapView regionDidChangeAnimated:(BOOL)animated {
	
	if (advMapView.accuracy <= 1 || advMapView.accuracy > 500.0) {
		return;
	}
	
	[self loadCarParksAtCoord:self.advMapView.centerCoordinate spanMeters:self.advMapView.spanMeters];
	
}

- (void)loadCarParksAtCoord:(CLLocationCoordinate2D)centerCoord spanMeters:(CGFloat)spanMeters {
	NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docsDir = [dirPaths objectAtIndex:0];
	NSString *dbPath = [docsDir stringByAppendingPathComponent:@"findparking.sqlite3"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:dbPath] == NO)
		dbPath = [[NSBundle mainBundle] pathForResource:@"findparking" ofType:@"sqlite3"];
	
	sqlite3 *db;
	if (sqlite3_open([dbPath UTF8String], &db) == SQLITE_OK)
	{
		// create the custom functions
		//sqlite3_create_function(db, "latlondistkm", 4, SQLITE_UTF8, NULL, &sqlite3_latlondistkm, NULL, NULL);
		
		// find all carparks that are roughly on screen (the calculation used here is a fast estimate)
		sqlite3_stmt *stmt;
		const char *stmtSql = "SELECT id, name, address, gps_lat, gps_lon, fee_summary, ((ABS($lat - gps_lat) + ABS($lon - gps_lon)) * 111.0) AS distance FROM carpark WHERE distance < $distance ORDER BY distance ASC";
		//const char *stmtSql = "SELECT id, name, address, gps_lat, gps_lon, fee_summary FROM carpark WHERE LATLONDISTKM(gps_lat, gps_lon, $lat, $lon) < $distance";
		if (sqlite3_prepare_v2(db, stmtSql, -1, &stmt, NULL) == SQLITE_OK) {
			if (sqlite3_bind_double(stmt, sqlite3_bind_parameter_index(stmt, "$lat"), centerCoord.latitude) == SQLITE_OK
				&& sqlite3_bind_double(stmt, sqlite3_bind_parameter_index(stmt, "$lon"), centerCoord.longitude) == SQLITE_OK
				&& sqlite3_bind_double(stmt, sqlite3_bind_parameter_index(stmt, "$distance"), MIN(8.5, (spanMeters / 1000.0))) == SQLITE_OK) {
				
				int count = 0;
				while (sqlite3_step(stmt) == SQLITE_ROW) {
					FPCarPark* carpark = [[FPCarPark alloc] init];
					
					// this identifier uniquely identifies are carpark
					carpark.identifier = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 0)];
					
					// the basic carpark info
					carpark.title = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 1)];
					carpark.address = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 2)];
					
					// set the lat / lon
					CLLocationDegrees lat = sqlite3_column_double(stmt, 3);
					CLLocationDegrees lon = sqlite3_column_double(stmt, 4);
					carpark.coordinate = CLLocationCoordinate2DMake(lat, lon);
					
					// set the fee summary and price info
					carpark.prices = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 5)];
					
					count++;
					[self.advMapView addItem:carpark];
				}
			}
			sqlite3_finalize(stmt);
		}
		else {
			NSLog(@"No database could be loaded.");
		}
		sqlite3_close(db);
	}
}


@end

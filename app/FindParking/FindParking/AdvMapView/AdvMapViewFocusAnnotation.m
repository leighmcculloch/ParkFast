//
//  AdvMapViewFocusAnnotation.m
//  FindParking
//
//  Created by Leigh McCulloch on 25/01/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#import "AdvMapViewFocusAnnotation.h"
#import "CLPlacemark+Fields.h"

@interface AdvMapViewFocusAnnotation ()

@property (retain, nonatomic) CLPlacemark *placemark;

@end

@implementation AdvMapViewFocusAnnotation

-(id)initWithPlacemark:(CLPlacemark*)placemark {
	self = [super init];
	if (self) {
		self.placemark = placemark;
	}
	return self;
}

- (void)dealloc {
	[_placemark release];
	[super dealloc];
}

- (CLLocationCoordinate2D)coordinate {
	return self.placemark.location.coordinate;
}

- (NSString*)title {
	return self.placemark.title;
}

- (NSString*)subtitle {
	return self.placemark.subtitle;
}

@end

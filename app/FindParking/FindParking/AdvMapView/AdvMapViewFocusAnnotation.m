//
//  AdvMapViewFocusAnnotation.m
//  FindParking
//
//  Created by Leigh McCulloch on 25/01/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#import "AdvMapViewFocusAnnotation.h"

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
	if (self.placemark.name) {
		return self.placemark.name;
	}
	
	NSString *addressLine1 = [self addressLine1];
	if (addressLine1) {
		return addressLine1;
	}
	
	return [self addressLine2];
}

- (NSString*)subtitle {
	if (self.placemark.name) {
		return [self address];
	}
	
	NSString *addressLine1 = [self addressLine1];
	if (addressLine1) {
		return [self addressLine2];
	}
	
	return nil;
}

- (NSString*)address {
	NSMutableString *address = [NSMutableString string];
	NSString *addressLine1 = [self addressLine1];
	if (addressLine1) {
		[address appendFormat:@"%@, ", addressLine1];
	}
	[address appendString:[self addressLine2]];
	return [NSString stringWithString:address];
}

- (NSString*)addressLine1 {
	NSMutableString *address = [NSMutableString string];
	if (self.placemark.subThoroughfare) {
		[address appendFormat:@"%@ ", self.placemark.subThoroughfare];
	}
	if (self.placemark.thoroughfare) {
		[address appendString:self.placemark.thoroughfare];
	}
	if (address.length == 0) {
		return nil;
	}
	return [NSString stringWithString:address];
}

- (NSString*)addressLine2 {
	return self.placemark.locality;
}

@end

//
//  CLPlacemark+Fields.m
//  FindParking
//
//  Created by Leigh McCulloch on 12/04/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#import "CLPlacemark+Fields.h"

@implementation CLPlacemark (Fields)


- (NSString*)title {
	if (self.name) {
		return self.name;
	}
	
	NSString *addressLine1 = [self addressLine1];
	if (addressLine1) {
		return addressLine1;
	}
	
	return [self addressLine2];
}

- (NSString*)subtitle {
	if (self.name) {
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
	if (self.subThoroughfare) {
		[address appendFormat:@"%@ ", self.subThoroughfare];
	}
	if (self.thoroughfare) {
		[address appendString:self.thoroughfare];
	}
	if (address.length == 0) {
		return nil;
	}
	return [NSString stringWithString:address];
}

- (NSString*)addressLine2 {
	return [NSString stringWithFormat:@"%@, %@", self.locality, self.administrativeArea];
}

@end

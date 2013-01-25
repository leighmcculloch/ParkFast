//
//  FPCarPark.m
//  FindParking
//
//  Created by Leigh McCulloch on 25/01/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#import "FPCarPark.h"

@implementation FPCarPark

@synthesize order;

- (id)initWithDictionary:(NSDictionary*)dic {
    self = [super init];
    if (self) {
		self.identifier = [dic objectForKey:@"_id"];
		NSArray* cpLoc = [dic objectForKey:@"location"];
		CLLocationDegrees cpLon = [[cpLoc objectAtIndex:0] doubleValue];
		CLLocationDegrees cpLat = [[cpLoc objectAtIndex:1] doubleValue];
		self.coordinate = CLLocationCoordinate2DMake(cpLat, cpLon);
		self.title = [dic objectForKey:@"name"];
		self.address = [dic objectForKey:@"address"];
		self.prices = [dic objectForKey:@"priceInfo"];
    }
    return self;
}

- (CLLocation*)location {
	return [[[CLLocation alloc] initWithLatitude:self.coordinate.latitude longitude:self.coordinate.longitude] autorelease];
}

- (BOOL)isEqual:(id)anObject
{
    return [self.identifier isEqual:[anObject identifier]];
}

- (NSUInteger)hash
{
    return [self.identifier hash];
}

#pragma mark AdvMapViewItem Protocol

- (NSString*)subtitle1 {
	return self.address;
}

- (NSString*)subtitle2 {
	return self.prices;
}

- (NSComparisonResult)comparePriority:(id<AdvMapViewItem>)other {
	// prioritise carparks by their distance from the main point of interest
	if (self.distance < other.distance) {
		return NSOrderedAscending;
	} else if (self.distance > other.distance) {
		return NSOrderedDescending;
	} else {
		return NSOrderedSame;
	}
}

@end

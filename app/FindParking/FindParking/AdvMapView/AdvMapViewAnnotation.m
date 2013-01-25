//
//  AdvMapViewAnnotation.m
//  FindParking
//
//  Created by Leigh McCulloch on 25/01/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#import "AdvMapViewAnnotation.h"

@implementation AdvMapViewAnnotation

-(id)initWithItem:(id<AdvMapViewItem>)item {
	if ((self = [super init])) {
		self.item = item;
	}
	return self;
}

-(CLLocationCoordinate2D)coordinate {
	return self.item.coordinate;
}

-(NSString*)title {
	return self.item.title;
}

-(NSString*)subtitle {
	return self.item.subtitle1;
}
@end

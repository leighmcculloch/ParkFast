//
//  FPCarPark.h
//  FindParking
//
//  Created by Leigh McCulloch on 25/01/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "AdvMapViewItem.h"

@interface FPCarPark : NSObject<AdvMapViewItem>

@property (retain, nonatomic) NSString* identifier;
@property (retain, nonatomic) NSString* title;
@property (retain, nonatomic) NSString* address;
@property (retain, nonatomic) NSString* prices;
@property (assign, nonatomic) CLLocationCoordinate2D coordinate;
@property (readonly, nonatomic) CLLocation* location;
@property (assign, nonatomic)CLLocationDistance distance;

- (id)initWithDictionary:(NSDictionary*)dic;


@end

//
//  AdvMapViewFocusAnnotation.h
//  FindParking
//
//  Created by Leigh McCulloch on 25/01/13.
//  Copyright (c) 2013 Leigh McCulloch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface AdvMapViewFocusAnnotation : NSObject<MKAnnotation>

@property (readonly, nonatomic) CLLocationCoordinate2D coordinate;
@property (readonly, nonatomic) NSString *title;
@property (readonly, nonatomic) NSString *subtitle;

-(id)initWithPlacemark:(CLPlacemark*)placemark;

@end
